.mode csv
.output results/memory/query_3.csv

-- Point-based of query 4

SELECT DISTINCT
    p.PointId,
    p.Geom,
    v.Licence
FROM TripsInput ti
JOIN Vehicles v ON ti.VehicleId = v.VehicleId
JOIN Points p ON ti.PosX = p.PosX AND ti.PosY = p.PosY
ORDER BY p.PointId, v.Licence;
