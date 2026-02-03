import json
import re
from pathlib import Path

import matplotlib.pyplot as plt

# Change this to the file you want, e.g. hanoi0.005/run_queries_memory.json
JSON_PATH = Path("hanoi0.005/run_queries_memory.json")

def qnum(name: str) -> int:
    m = re.search(r"query_(\d+)\.sql$", name)
    if not m:
        raise ValueError(f"Bad query key: {name}")
    return int(m.group(1))

def kb_to_gib(kb: float) -> float:
    return kb / (1024 * 1024)

data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
by_num = {qnum(k): v for k, v in data.items()}

pairs = []
for odd in sorted(n for n in by_num if n % 2 == 1):
    even = odd + 1
    if even in by_num:
        pairs.append((odd, by_num[odd], by_num[even]))

if not pairs:
    raise SystemExit(f"No odd/even pairs found in {JSON_PATH}")

labels = [f"q{odd}/q{odd+1}" for odd, _, _ in pairs]
pts_elapsed = [odd_s["elapsed"] for _, odd_s, _ in pairs]
mob_elapsed = [even_s["elapsed"] for _, _, even_s in pairs]
pts_rss = [kb_to_gib(odd_s["max_rss_kb"]) for _, odd_s, _ in pairs]
mob_rss = [kb_to_gib(even_s["max_rss_kb"]) for _, _, even_s in pairs]

x = list(range(len(labels)))
w = 0.42

outdir = Path("figures")
outdir.mkdir(exist_ok=True)

# Figure 1: elapsed per pair (2 bars each)
plt.figure(figsize=(max(8, 1.2 * len(labels)), 4))
plt.bar([i - w/2 for i in x], pts_elapsed, width=w, label="Points-Based (DuckDB+Spatial)")
plt.bar([i + w/2 for i in x], mob_elapsed, width=w, label="Trajectory-Based (MobilityDuck+Spatial)")
plt.xticks(x, labels, rotation=0)
plt.xlabel("Query pair")
plt.ylabel("Elapsed (s)")
plt.title(f"Elapsed time")
plt.legend()
plt.tight_layout()
plt.savefig(outdir / f"{JSON_PATH.parent.name}_elapsed_pairs.png", dpi=200)

# Figure 2: max RSS per pair (2 bars each)
plt.figure(figsize=(max(8, 1.2 * len(labels)), 4))
plt.bar([i - w/2 for i in x], pts_rss, width=w, label="Points-Based (DuckDB+Spatial)")
plt.bar([i + w/2 for i in x], mob_rss, width=w, label="Trajectory-Based (MobilityDuck+Spatial)")
plt.xticks(x, labels, rotation=0)
plt.xlabel("Query pair")
plt.ylabel("Max RSS (GiB)")
plt.title(f"Max RSS")
plt.legend()
plt.tight_layout()
plt.savefig(outdir / f"{JSON_PATH.parent.name}_rss_pairs.png", dpi=200)

print("Saved:")
print(" -", outdir / f"{JSON_PATH.parent.name}_elapsed_pairs.png")
print(" -", outdir / f"{JSON_PATH.parent.name}_rss_pairs.png")
