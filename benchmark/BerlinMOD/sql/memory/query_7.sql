.mode csv
.output results/memory/query_7.csv

-- Point-based version of query 9
WITH PointsInPeriod AS (
    SELECT
        p.PeriodId,
        p.Tstart,
        p.Tend,
        ti.VehicleId,
        ti.t,
        ST_Transform(
            ST_Point(ti.PosX, ti.PosY),
            'EPSG:4326',
            'EPSG:3857',
            always_xy := true
        ) AS geom
    FROM TripsInput ti
    JOIN Periods p ON ti.t >= p.Tstart AND ti.t <= p.Tend
),
Ordered AS (
    SELECT
        PeriodId,
        Tstart,
        Tend,
        VehicleId,
        t,
        geom,
        LEAD(geom) OVER (
            PARTITION BY PeriodId, VehicleId
            ORDER BY t
        ) AS next_geom
    FROM PointsInPeriod
),
Distances AS (
    SELECT
        PeriodId,
        Tstart,
        Tend,
        VehicleId,
        SUM(
            CASE
                WHEN next_geom IS NOT NULL
                THEN ST_Distance(geom, next_geom)
                ELSE 0
            END
        ) AS Dist
    FROM Ordered
    GROUP BY PeriodId, Tstart, Tend, VehicleId
)
SELECT
    p.PeriodId,
    p.Tstart,
    p.Tend,
    COALESCE(MAX(d.Dist), 0) AS MaxDist
FROM Periods p
LEFT JOIN Distances d
  ON p.PeriodId = d.PeriodId
GROUP BY p.PeriodId, p.Tstart, p.Tend
HAVING MAX(COALESCE(d.Dist, 0)) > 0
ORDER BY p.PeriodId;