.mode csv
.output results/memory/query_5.csv

-- Point version of query 7 
WITH Timestamps AS (
    SELECT
        v.Licence,
        p.PointId,
        p.Geom,
        MIN(ti.t) AS Instant
    FROM TripsInput ti
    JOIN Vehicles v ON ti.VehicleId = v.VehicleId
    JOIN Points1 p ON ti.PosX = p.PosX AND ti.PosY = p.PosY
    WHERE v.VehicleType = 'passenger'
    GROUP BY v.Licence, p.PointId, p.Geom
)
SELECT
    t1.Licence,
    t1.PointId,
    t1.Geom,
    t1.Instant
FROM Timestamps t1
WHERE t1.Instant <= ALL (
    SELECT t2.Instant
    FROM Timestamps t2
    WHERE t1.PointId = t2.PointId
)
ORDER BY t1.PointId, t1.Licence;
