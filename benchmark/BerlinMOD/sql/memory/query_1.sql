
.mode csv
.output results/memory/query_1.csv

-- point based of query 3

SELECT DISTINCT
    c.Licence,
    c.InstantId,
    c.Instant,
    c.Pos
FROM (
    WITH TripSpans AS (
        SELECT
            TripId,
            VehicleId,
            MIN(t) AS tmin,
            MAX(t) AS tmax
        FROM TripsInput
        GROUP BY TripId, VehicleId
    ),
    Candidates AS (
        SELECT
            l.Licence,
            i.InstantId,
            i.Instant,
            ST_Transform(
                ST_Point(ti.PosX, ti.PosY),
                'EPSG:4326',
                'EPSG:3857',
                always_xy := true
            ) AS Pos,
            ROW_NUMBER() OVER (
                PARTITION BY l.Licence, i.InstantId
                ORDER BY ti.t DESC
            ) AS rn
        FROM TripSpans s
        JOIN Licences1 l
          ON s.VehicleId = l.VehicleId
        JOIN Instants1 i
          ON i.Instant >= s.tmin
         AND i.Instant <= s.tmax              -- i.Instant lies inside this trip span
        JOIN TripsInput ti
          ON ti.TripId = s.TripId
         AND ti.VehicleId = s.VehicleId
         AND ti.t <= i.Instant         -- only samples at or before the instant
    )
    SELECT
        Licence,
        InstantId,
        Instant,
        Pos
    FROM Candidates
    WHERE rn = 1            
) AS c
ORDER BY c.Licence, c.InstantId;
