.mode csv
.output results/memory/query_4.csv

-- Trajectory of query 4
SELECT DISTINCT p.PointId, p.Geom, v.Licence
FROM Trips t, Vehicles v, Points p
WHERE
    t.VehicleId = v.VehicleId
    AND ST_Intersects(trajectory(t.Trip)::GEOMETRY, p.Geom)
ORDER BY p.PointId, v.Licence;