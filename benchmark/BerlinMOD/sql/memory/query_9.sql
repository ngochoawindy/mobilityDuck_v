.mode csv
.output results/memory/query_9.csv  

-- Point based version of query 13 
WITH Temp AS (
    SELECT DISTINCT
        r.RegionId,
        p.PeriodId,
        p.Period,   
        ti.VehicleId
    FROM TripsInput ti
    JOIN Periods1 p
      ON ti.t >= p.Tstart
     AND ti.t <= p.Tend
    JOIN Regions1 r
      ON ST_Contains(
           r.Geom,
           ST_Transform(
             ST_Point(ti.PosX, ti.PosY),
             'EPSG:4326',
             'EPSG:3857',
             always_xy := true
           )
         )
)
SELECT DISTINCT
    t.RegionId,
    t.PeriodId,
    t.Period,
    v.Licence
FROM Temp t
JOIN Vehicles v ON t.VehicleId = v.VehicleId
ORDER BY t.RegionId, t.PeriodId, v.Licence;
