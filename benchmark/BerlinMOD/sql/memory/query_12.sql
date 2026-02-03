.mode csv
.output results/memory/query_12.csv

-- Traj based version of query 14
WITH Temp AS (
    SELECT DISTINCT r.RegionId, i.InstantId, i.Instant, t.VehicleId
    FROM Trips t, Regions1 r, Instants1 i
    WHERE
        t.Trip && stbox(r.Geom::WKB_BLOB, i.Instant)
        AND ST_Contains(r.Geom, valueAtTimestamp(t.Trip, i.Instant)::GEOMETRY) )
SELECT DISTINCT t.RegionId, t.InstantId, t.Instant, v.Licence
FROM Temp t JOIN Vehicles v ON t.VehicleId = v.VehicleId 
ORDER BY t.RegionId, t.InstantId, v.Licence;