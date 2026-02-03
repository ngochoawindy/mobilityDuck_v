#!/usr/bin/env python3
"""
Query runner for Comparing memory between Points-based vs Trajectory-based
"""

import subprocess
import time
import json
import sys
import os
import argparse
import re
from typing import Dict, Tuple

QUERIES_NUM = 14


class QueryRunner:
    def __init__(self, duckdb_path: str = "../../build/release/duckdb",
                       benchmark: str = "default",
                       queries_path: str = "./sql/memory",                       
                       output_path: str = "./results/memory"):
        self.duckdb_path = duckdb_path
        self.benchmark = benchmark
        self.queries_path = queries_path        
        self.output_path = output_path
        self.queries_num = QUERIES_NUM
        self._warned_no_time = False   

    # ---------- Helpers for memory measurement ----------

    def _wrap_with_time(self, base_cmd):
        # Try GNU time on macOS
        if os.path.exists("/usr/local/bin/gtime"):
            return ["/usr/local/bin/gtime", "-v"] + base_cmd, True

        # Try GNU time on Linux
        if os.path.exists("/usr/bin/time"):
            return ["/usr/bin/time", "-v"] + base_cmd, True

        # No GNU time available
        if not self._warned_no_time:
            print("\tWarning: GNU time not found, memory will not be measured.")
            self._warned_no_time = True

        return base_cmd, False

    def _parse_max_rss(self, stderr: str) -> int:
        """
        Parse 'Maximum resident set size (kbytes)' from /usr/bin/time -v output.
        Returns:
            max_rss_kb (int) or -1 if not found / cannot parse.
        """
        if not stderr:
            return -1
        for line in stderr.splitlines():
            # Example: "Maximum resident set size (kbytes): 123456"
            m = re.search(r"Maximum resident set size.*?([0-9]+)", line)
            if m:
                try:
                    return int(m.group(1))
                except ValueError:
                    return -1
        return -1

    # ----------------------------------------------------

    def run_sql(self, filename: str) -> Tuple[float, int, int]:
        """
        Run a single query SQL file.

        Returns:
            elapsed_ms : float
            line_count : int
            max_rss_kb : int (or -1 if not measured)
        """
        success = False
        print(f"\nRunning {filename}")
        start_time = time.time()
        sql_path = os.path.join(self.queries_path, filename)
        if not os.path.exists(sql_path):
            print(f"\tError: Query file not found: {sql_path}")
            return -1, -1, -1
        
        with open(sql_path, "r") as f:
            sql = f.read()

        # Adjust .output path to include benchmark name
        sql = sql.replace(".output results/memory/query",
                          f".output results/memory/{self.benchmark}/query")

        max_rss_kb = -1  # default dont measure memory

        while not success:
            base_cmd = [self.duckdb_path, f"./databases/{self.benchmark}.db"]
            cmd, use_time = self._wrap_with_time(base_cmd)

            result = subprocess.run(
                cmd,
                input=sql,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                success = True
            else:
                print(f"\tError running query: {result.stderr}")
                print("\tTrying again...")
                time.sleep(1)
                start_time = time.time()

        end_time = time.time()
        elapsed = (end_time - start_time) * 1000  # milliseconds

        # If wrapped with /usr/bin/time, parse its stderr for max RSS
        if use_time:
            max_rss_kb = self._parse_max_rss(result.stderr)

        print(f"\tDone in {elapsed:.2f}ms")

        line_count = self.run_validation(filename)
        print(f"\tOutput row count: {line_count}")
        if use_time:
            print(f"\tMax RSS: {max_rss_kb} kB")

        return elapsed, line_count, max_rss_kb

    def run_validation(self, filename: str) -> int:
        """
        Count rows in the CSV output corresponding to this query.
        Assumes a header row and subtracts 1 from the line count.
        """
        output_file = f"{self.output_path}/{self.benchmark}/{filename.replace('.sql', '.csv')}"
        if not os.path.exists(output_file):
            print(f"\tError: Output file not found: {output_file}")
            return -1
        with open(output_file, "r") as f:
            line_count = sum(1 for _ in f)
        if line_count > 0:
            line_count -= 1
        return line_count

    def run_queries(self) -> Dict:
        """
        Run all queries from query_1.sql to query_{QUERIES_NUM}.sql
        and store elapsed time, row count, and max RSS in a dict.
        """
        results = dict()

        for query_num in range(1, self.queries_num + 1):
            filename = f"query_{query_num}.sql"
            elapsed, line_count, max_rss_kb = self.run_sql(filename)
            if elapsed != -1:
                results[filename] = {
                    "elapsed": elapsed,
                    "row_count": line_count,
                    "max_rss_kb": max_rss_kb
                }
        
        return results

def main():
    parser = argparse.ArgumentParser(description="Data loader for Memory Comparison")
    parser.add_argument("--benchmark", type=str, required=True, help="Name of the benchmark run")    
    args = parser.parse_args()

    benchmark = args.benchmark    

    if not os.path.exists(f"./results/memory/{benchmark}"):
        os.makedirs(f"./results/memory/{benchmark}")

    duckdb_path = "../../build/release/duckdb"
    if not os.path.exists(duckdb_path):
        print(f"Error: DuckDB executable not found at {duckdb_path}")
        print("Please make sure you're running this from the benchmark directory and DuckDB is built.")
        sys.exit(1)
    
    runner = QueryRunner(duckdb_path, benchmark)    
    results = runner.run_queries()
    
    if not os.path.exists(f"./results/stats/{benchmark}"):
        os.makedirs(f"./results/stats/{benchmark}")
    
    stats_filename = "run_queries_memory.json" 
    with open(f"./results/stats/{benchmark}/{stats_filename}", "w") as f:
        json.dump(results, f, indent=4)
    
    print(f"\nResults saved to ./results/stats/{benchmark}/{stats_filename}")


if __name__ == "__main__":
    main()
