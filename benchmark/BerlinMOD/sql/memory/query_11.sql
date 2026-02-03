.mode csv
.output results/memory/query_11.csv  

-- Point based version of query 14
WITH BasePoints AS (
    SELECT
        TripId,
        VehicleId,
        t,
        ST_Transform(
            ST_Point(PosX, PosY),
            'EPSG:4326',
            'EPSG:3857',
            always_xy := true
        ) AS geom
    FROM TripsInput
),
Segments AS (
    SELECT
        TripId,
        VehicleId,
        t AS t1,
        LEAD(t) OVER (
            PARTITION BY TripId, VehicleId
            ORDER BY t
        ) AS t2,
        geom AS geom1,
        LEAD(geom) OVER (
            PARTITION BY TripId, VehicleId
            ORDER BY t
        ) AS geom2
    FROM BasePoints
),
ValidSegments AS (
    SELECT
        TripId,
        VehicleId,
        t1,
        t2,
        geom1,
        geom2
    FROM Segments
    WHERE t2 IS NOT NULL
),
Temp AS (
    SELECT DISTINCT
        r.RegionId,
        i.InstantId,
        i.Instant,
        s.VehicleId
    FROM ValidSegments s
    JOIN Instants1 i
      ON i.Instant >= s.t1
     AND i.Instant <= s.t2              
    JOIN Regions1 r
      ON ST_Intersects(
           ST_MakeLine(s.geom1, s.geom2),
           r.Geom
         )                              
)
SELECT DISTINCT
    t.RegionId,
    t.InstantId,
    t.Instant,
    v.Licence
FROM Temp t
JOIN Vehicles v ON t.VehicleId = v.VehicleId
ORDER BY t.RegionId, t.InstantId, v.Licence;
