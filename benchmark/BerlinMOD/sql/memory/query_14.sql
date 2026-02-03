.mode csv
.output results/memory/query_14.csv

-- trajectory of query 17 
WITH PointCount AS (
    SELECT p.PointId, COUNT(DISTINCT t.VehicleId) AS Hits
    FROM Trips t, Points p
    WHERE ST_Intersects(trajectory(t.Trip)::GEOMETRY, p.Geom)
    GROUP BY p.PointId )
SELECT PointId, Hits
FROM PointCount AS p
WHERE p.Hits = ( SELECT MAX(Hits) FROM PointCount );