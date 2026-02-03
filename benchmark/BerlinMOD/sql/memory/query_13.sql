.mode csv
.output results/memory/query_13.csv

-- Point -query 17

WITH PointCount AS (
    SELECT
        p.PointId,
        COUNT(DISTINCT ti.VehicleId) AS Hits
    FROM TripsInput ti
    JOIN Points p
      ON ti.PosX = p.PosX
     AND ti.PosY = p.PosY
    GROUP BY p.PointId
)
SELECT
    PointId,
    Hits
FROM PointCount pc
WHERE pc.Hits = (SELECT MAX(Hits) FROM PointCount)
ORDER BY PointId;
