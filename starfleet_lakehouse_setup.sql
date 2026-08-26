-- Starfleet Data Platform: fictional Iceberg lakehouse examples.
-- Engine: Trino / Starburst Galaxy. 
-- Author: CJ Julius.
-- Run top to bottom once. Refresh order matters. A commented teardown sits at the end.

-- ============================================================
-- SCHEMAS
-- ============================================================
CREATE SCHEMA IF NOT EXISTS starfleet.raw;
CREATE SCHEMA IF NOT EXISTS starfleet.transform;
CREATE SCHEMA IF NOT EXISTS starfleet.intermediate;
CREATE SCHEMA IF NOT EXISTS starfleet.analytics;
-- ============================================================
-- RAW LAYER: one nested document per (vessel, ingestion). document_json holds vessel scalars, crew array, sensor_logs array.
-- ingested_at is real pipeline time. In-universe dates and stardates live inside the JSON. Version history drives dedup downstream.
-- vessel_delete_signal is a separate tombstone feed.
-- ============================================================
CREATE OR REPLACE TABLE starfleet.raw.starship_record (
    registry VARCHAR,
    document_json VARCHAR,
    source_row_id VARCHAR,
    ingested_at TIMESTAMP(6) WITH TIME ZONE
);
INSERT INTO starfleet.raw.starship_record (registry, document_json, source_row_id, ingested_at) VALUES
('NCC-1701', '{"registry":"NCC-1701","vessel":{"registry":"NCC-1701","name":"USS Enterprise","class":"Constitution","affiliation":"Starfleet","commissioned":"2245","status":"destroyed","registry_prefix":"NCC"},"crew":[{"name":"James T. Kirk","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"1312.4","member_status":"active"},{"name":"Spock","crew_rank":"Commander","species":"Vulcan","duty_position":"First Officer","posting_stardate":"1312.4","member_status":"active"},{"name":"Leonard McCoy","crew_rank":"Lt Commander","species":"Human","duty_position":"Chief Medical Officer","posting_stardate":"1512.2","member_status":"active"},{"name":"Montgomery Scott","crew_rank":"Lt Commander","species":"Human","duty_position":"Chief Engineer","posting_stardate":"1512.2","member_status":"active"},{"name":"Nyota Uhura","crew_rank":"Lieutenant","species":"Human","duty_position":"Communications","posting_stardate":"1513.1","member_status":"active"},{"name":"Hikaru Sulu","crew_rank":"Lieutenant","species":"Human","duty_position":"Helm","posting_stardate":"1513.1","member_status":"active"},{"name":"Pavel Chekov","crew_rank":"Ensign","species":"Human","duty_position":"Navigation","posting_stardate":"2216.5","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0007","stardate":"3045.6","readings":[{"reading_type":"lifeform","target":"Mutara sector","reading_value":"none","unit":"flag"},{"reading_type":"radiation","target":"Mutara Nebula","reading_value":"high","unit":"level"}]}]}', 'vsl-0001', TIMESTAMP '2026-01-05 08:00:00 UTC'),
('NCC-1701-A', '{"registry":"NCC-1701-A","vessel":{"registry":"NCC-1701-A","name":"USS Enterprise","class":"Constitution","affiliation":"Starfleet","commissioned":"2286","status":"decommissioned","registry_prefix":"NCC"}}', 'vsl-0003', TIMESTAMP '2026-01-05 08:05:00 UTC'),
('NCC-1701-B', '{"registry":"NCC-1701-B","vessel":{"registry":"NCC-1701-B","name":"USS Enterprise","class":"Excelsior","affiliation":"Starfleet","commissioned":"2293","status":"active","registry_prefix":"NCC"}}', 'vsl-0004', TIMESTAMP '2026-01-05 08:06:00 UTC'),
('NCC-1701-C', '{"registry":"NCC-1701-C","vessel":{"registry":"NCC-1701-C","name":"USS Enterprise","class":"Ambassador","affiliation":"Starfleet","commissioned":"2332","status":"destroyed","registry_prefix":"NCC"}}', 'vsl-0005', TIMESTAMP '2026-01-05 08:07:00 UTC'),
('NCC-1701-D', '{"registry":"NCC-1701-D","vessel":{"registry":"NCC-1701-D","name":"USS Enterprise","class":"Galaxy","affiliation":"Starfleet","commissioned":"2363","status":"active","registry_prefix":"NCC"},"crew":[{"name":"Jean-Luc Picard","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"41124.0","member_status":"active"},{"name":"William Riker","crew_rank":"Commander","species":"Human","duty_position":"First Officer","posting_stardate":"41124.0","member_status":"active"},{"name":"Data","crew_rank":"Lt Commander","species":"Android","duty_position":"Operations","posting_stardate":"41124.0","member_status":"active"},{"name":"Worf","crew_rank":"Lieutenant","species":"Klingon","duty_position":"Security Chief","posting_stardate":"41124.0","member_status":"active"},{"name":"Deanna Troi","crew_rank":"Lt Commander","species":"Betazoid","duty_position":"Counselor","posting_stardate":"41124.0","member_status":"active"},{"name":"Beverly Crusher","crew_rank":"Commander","species":"Human","duty_position":"Chief Medical Officer","posting_stardate":"41124.0","member_status":"active"},{"name":"Geordi La Forge","crew_rank":"Lieutenant","species":"Human","duty_position":"Conn","posting_stardate":"41124.0","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0001","stardate":"41153.7","readings":[{"reading_type":"lifeform","target":"Class-M planet","reading_value":"2400000000","unit":"count"},{"reading_type":"radiation","target":"Class-M planet","reading_value":"12","unit":"rad"},{"reading_type":"biosign","target":"humanoid","reading_value":"positive","unit":"flag"}]},{"log_id":"LOG-0002","stardate":"44286.5","readings":[{"reading_type":"temporal","target":"temporal anomaly","reading_value":"0.003","unit":"delta"},{"reading_type":"subspace","target":"Class-9 nebula","reading_value":"high","unit":"level"}]}]}', 'vsl-0006', TIMESTAMP '2026-01-05 08:08:00 UTC'),
('NCC-1701-D', '{"registry":"NCC-1701-D","vessel":{"registry":"NCC-1701-D","name":"USS Enterprise","class":"Galaxy","affiliation":"Starfleet","commissioned":"2363","status":"destroyed","registry_prefix":"NCC"},"crew":[{"name":"Jean-Luc Picard","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"41124.0","member_status":"active"},{"name":"William Riker","crew_rank":"Commander","species":"Human","duty_position":"First Officer","posting_stardate":"41124.0","member_status":"active"},{"name":"Data","crew_rank":"Lt Commander","species":"Android","duty_position":"Operations","posting_stardate":"41124.0","member_status":"active"},{"name":"Worf","crew_rank":"Lieutenant","species":"Klingon","duty_position":"Security Chief","posting_stardate":"41124.0","member_status":"active"},{"name":"Deanna Troi","crew_rank":"Lt Commander","species":"Betazoid","duty_position":"Counselor","posting_stardate":"41124.0","member_status":"active"},{"name":"Beverly Crusher","crew_rank":"Commander","species":"Human","duty_position":"Chief Medical Officer","posting_stardate":"41124.0","member_status":"active"},{"name":"Geordi La Forge","crew_rank":"Lt Commander","species":"Human","duty_position":"Chief Engineer","posting_stardate":"43205.6","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0001","stardate":"41153.7","readings":[{"reading_type":"lifeform","target":"Class-M planet","reading_value":"2400000000","unit":"count"},{"reading_type":"radiation","target":"Class-M planet","reading_value":"12","unit":"rad"},{"reading_type":"biosign","target":"humanoid","reading_value":"positive","unit":"flag"}]},{"log_id":"LOG-0002","stardate":"44286.5","readings":[{"reading_type":"temporal","target":"temporal anomaly","reading_value":"0.003","unit":"delta"},{"reading_type":"subspace","target":"Class-9 nebula","reading_value":"high","unit":"level"}]}]}', 'vsl-0007', TIMESTAMP '2026-03-10 08:08:00 UTC'),
('NCC-1701-E', '{"registry":"NCC-1701-E","vessel":{"registry":"NCC-1701-E","name":"USS Enterprise","class":"Sovereign","affiliation":"Starfleet","commissioned":"2372","status":"active","registry_prefix":"NCC"},"sensor_logs":[{"log_id":"LOG-0008","stardate":"50893.5","readings":[{"reading_type":"tachyon","target":"temporal anomaly","reading_value":"detected","unit":"flag"},{"reading_type":"temporal","target":"temporal vortex","reading_value":"0.9","unit":"delta"},{"reading_type":"gravimetric","target":"Class-M planet","reading_value":"1.0","unit":"g"}]}]}', 'vsl-0008', TIMESTAMP '2026-01-05 08:09:00 UTC'),
('NX-74205', '{"registry":"NX-74205","vessel":{"registry":"NX-74205","name":"USS Defiant","class":"Defiant","affiliation":"Starfleet","commissioned":"2370","status":"destroyed","registry_prefix":"NX"},"crew":[{"name":"Benjamin Sisko","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"46379.0","member_status":"active"},{"name":"Kira Nerys","crew_rank":"Major","species":"Bajoran","duty_position":"First Officer","posting_stardate":"46379.0","member_status":"active"},{"name":"Worf","crew_rank":"Lt Commander","species":"Klingon","duty_position":"Strategic Operations","posting_stardate":"50564.2","member_status":"active"},{"name":"Jadzia Dax","crew_rank":"Lieutenant","species":"Trill","duty_position":"Science Officer","posting_stardate":"46379.0","member_status":"active"},{"name":"Julian Bashir","crew_rank":"Lieutenant","species":"Human","duty_position":"Chief Medical Officer","posting_stardate":"46379.0","member_status":"active"},{"name":"Miles O''Brien","crew_rank":"Chief Petty Officer","species":"Human","duty_position":"Chief Engineer","posting_stardate":"46379.0","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0003","stardate":"48962.5","readings":[{"reading_type":"subspace","target":"Bajoran wormhole","reading_value":"active","unit":"flag"},{"reading_type":"gravimetric","target":"Bajoran wormhole","reading_value":"9.8","unit":"g"},{"reading_type":"tachyon","target":"Romulan warbird","reading_value":"detected","unit":"flag"}]}]}', 'vsl-0009', TIMESTAMP '2026-01-08 08:00:00 UTC'),
('NCC-74656', '{"registry":"NCC-74656","vessel":{"registry":"NCC-74656","name":"USS Voyager","class":"Intrepid","affiliation":"Starfleet","commissioned":"2371","status":"active","registry_prefix":"NCC"},"crew":[{"name":"Kathryn Janeway","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"48038.0","member_status":"active"},{"name":"Chakotay","crew_rank":"Commander","species":"Human","duty_position":"First Officer","posting_stardate":"48038.0","member_status":"active"},{"name":"Tuvok","crew_rank":"Lt Commander","species":"Vulcan","duty_position":"Security Chief","posting_stardate":"48038.0","member_status":"active"},{"name":"B''Elanna Torres","crew_rank":"Lieutenant","species":"Klingon","duty_position":"Chief Engineer","posting_stardate":"48038.0","member_status":"active"},{"name":"Tom Paris","crew_rank":"Lieutenant","species":"Human","duty_position":"Helm","posting_stardate":"48038.0","member_status":"active"},{"name":"Harry Kim","crew_rank":"Ensign","species":"Human","duty_position":"Operations","posting_stardate":"48038.0","member_status":"active"},{"name":"The Doctor","crew_rank":"None","species":"Hologram","duty_position":"Chief Medical Officer","posting_stardate":"48038.0","member_status":"active"},{"name":"Seven of Nine","crew_rank":"Crewman","species":"Human","duty_position":"Astrometrics","posting_stardate":"50984.3","member_status":"active"},{"name":"Neelix","crew_rank":"None","species":"Talaxian","duty_position":"Morale Officer","posting_stardate":"48315.0","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0004","stardate":"48315.6","readings":[{"reading_type":"lifeform","target":"Class-L planet","reading_value":"0","unit":"count"},{"reading_type":"radiation","target":"Class-L planet","reading_value":"450","unit":"rad"},{"reading_type":"gravimetric","target":"Delta Quadrant","reading_value":"1.1","unit":"g"}]},{"log_id":"LOG-0005","stardate":"49548.7","readings":[{"reading_type":"temporal","target":"temporal rift","reading_value":"0.07","unit":"delta"},{"reading_type":"subspace","target":"Borg cube","reading_value":"critical","unit":"level"},{"reading_type":"biosign","target":"Borg cube","reading_value":"6042","unit":"count"}]}]}', 'vsl-0011', TIMESTAMP '2026-01-08 08:05:00 UTC'),
('NCC-74656', '{"registry":"NCC-74656","vessel":{"registry":"NCC-74656","name":"USS Voyager","class":"Intrepid","affiliation":"Starfleet","commissioned":"2371","status":"active","registry_prefix":"NCC"},"crew":[{"name":"Kathryn Janeway","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"48038.0","member_status":"active"},{"name":"Chakotay","crew_rank":"Commander","species":"Human","duty_position":"First Officer","posting_stardate":"48038.0","member_status":"active"},{"name":"Tuvok","crew_rank":"Lt Commander","species":"Vulcan","duty_position":"Security Chief","posting_stardate":"48038.0","member_status":"active"},{"name":"B''Elanna Torres","crew_rank":"Lieutenant","species":"Klingon","duty_position":"Chief Engineer","posting_stardate":"48038.0","member_status":"active"},{"name":"Tom Paris","crew_rank":"Lieutenant","species":"Human","duty_position":"Helm","posting_stardate":"48038.0","member_status":"active"},{"name":"Harry Kim","crew_rank":"Ensign","species":"Human","duty_position":"Operations","posting_stardate":"48038.0","member_status":"active"},{"name":"The Doctor","crew_rank":"None","species":"Hologram","duty_position":"Chief Medical Officer","posting_stardate":"48038.0","member_status":"active"},{"name":"Seven of Nine","crew_rank":"Crewman","species":"Human","duty_position":"Astrometrics","posting_stardate":"50984.3","member_status":"active"},{"name":"Neelix","crew_rank":"None","species":"Talaxian","duty_position":"Morale Officer","posting_stardate":"48315.0","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0004","stardate":"48315.6","readings":[{"reading_type":"lifeform","target":"Class-L planet","reading_value":"0","unit":"count"},{"reading_type":"radiation","target":"Class-L planet","reading_value":"450","unit":"rad"},{"reading_type":"gravimetric","target":"Delta Quadrant","reading_value":"1.1","unit":"g"}]},{"log_id":"LOG-0005","stardate":"49548.7","readings":[{"reading_type":"temporal","target":"temporal rift","reading_value":"0.07","unit":"delta"},{"reading_type":"subspace","target":"Borg cube","reading_value":"critical","unit":"level"},{"reading_type":"biosign","target":"Borg cube","reading_value":"6042","unit":"count"}]}]}', 'vsl-0012', TIMESTAMP '2026-04-01 08:05:00 UTC'),
('NCC-2000', '{"registry":"NCC-2000","vessel":{"registry":"NCC-2000","name":"USS Excelsior","class":"Excelsior","affiliation":"Starfleet","commissioned":"2285","status":"active","registry_prefix":"NCC"}}', 'vsl-0013', TIMESTAMP '2026-01-05 08:10:00 UTC'),
('NCC-1864', '{"registry":"NCC-1864","vessel":{"registry":"NCC-1864","name":"USS Reliant","class":"Miranda","affiliation":"Starfleet","commissioned":"2267","status":"destroyed","registry_prefix":"NCC"}}', 'vsl-0014', TIMESTAMP '2026-01-05 08:11:00 UTC'),
('NCC-638', '{"registry":"NCC-638","vessel":{"registry":"NCC-638","name":"USS Grissom","class":"Oberth","affiliation":"Starfleet","commissioned":"2270","status":"destroyed","registry_prefix":"NCC"}}', 'vsl-0015', TIMESTAMP '2026-01-05 08:12:00 UTC'),
('NCC-2893', '{"registry":"NCC-2893","vessel":{"registry":"NCC-2893","name":"USS Stargazer","class":"Constellation","affiliation":"Starfleet","commissioned":"2332","status":"decommissioned","registry_prefix":"NCC"}}', 'vsl-0016', TIMESTAMP '2026-01-05 08:13:00 UTC'),
('NX-01', '{"registry":"NX-01","vessel":{"registry":"NX-01","name":"Enterprise","class":"NX","affiliation":"United Earth Starfleet","commissioned":"2151","status":"active","registry_prefix":"NX"},"crew":[{"name":"Jonathan Archer","crew_rank":"Captain","species":"Human","duty_position":"Commanding Officer","posting_stardate":"2151.04","member_status":"active"},{"name":"T''Pol","crew_rank":"Subcommander","species":"Vulcan","duty_position":"Science Officer","posting_stardate":"2151.04","member_status":"active"},{"name":"Charles Tucker III","crew_rank":"Commander","species":"Human","duty_position":"Chief Engineer","posting_stardate":"2151.04","member_status":"active"},{"name":"Malcolm Reed","crew_rank":"Lieutenant","species":"Human","duty_position":"Armory Officer","posting_stardate":"2151.04","member_status":"active"},{"name":"Hoshi Sato","crew_rank":"Ensign","species":"Human","duty_position":"Communications","posting_stardate":"2151.04","member_status":"active"},{"name":"Travis Mayweather","crew_rank":"Ensign","species":"Human","duty_position":"Helm","posting_stardate":"2151.04","member_status":"active"},{"name":"Phlox","crew_rank":"None","species":"Denobulan","duty_position":"Chief Medical Officer","posting_stardate":"2151.04","member_status":"active"}],"sensor_logs":[{"log_id":"LOG-0006","stardate":"2152.05","readings":[{"reading_type":"lifeform","target":"Class-M planet","reading_value":"unknown","unit":"flag"},{"reading_type":"subspace","target":"plasma storm","reading_value":"severe","unit":"level"}]}]}', 'vsl-0017', TIMESTAMP '2026-01-05 08:14:00 UTC'),
('NCC-72381', '{"registry":"NCC-72381","vessel":{"registry":"NCC-72381","name":"USS Equinox","class":"Nova","affiliation":"Starfleet","commissioned":"2370","status":"destroyed","registry_prefix":"NCC"}}', 'vsl-0018', TIMESTAMP '2026-01-15 08:00:00 UTC'),
('NCC-31911', '{"registry":"NCC-31911","vessel":{"registry":"NCC-31911","name":"USS Saratoga","class":"Miranda","affiliation":"Starfleet","commissioned":"2360","status":"destroyed","registry_prefix":"NCC"}}', 'vsl-0019', TIMESTAMP '2026-01-05 08:15:00 UTC'),
('NCC-1941', '{"registry":"NCC-1941","vessel":{"registry":"NCC-1941","name":"USS Bozeman","class":"Soyuz","affiliation":"Starfleet","commissioned":"2278","status":"active","registry_prefix":"NCC"}}', 'vsl-0020', TIMESTAMP '2026-01-05 08:16:00 UTC'),
('IKS-ROTARRAN', '{"registry":"IKS-ROTARRAN","vessel":{"registry":"IKS-ROTARRAN","name":"IKS Rotarran","class":"Bird-of-Prey","affiliation":"Klingon Empire","commissioned":"2372","status":"active","registry_prefix":"IKS"}}', 'vsl-0021', TIMESTAMP '2026-01-08 08:10:00 UTC'),
('NX-59650', '{"registry":"NX-59650","vessel":{"registry":"NX-59650","name":"USS Prometheus","class":"Prometheus","affiliation":"Starfleet","commissioned":"2374","status":"active","registry_prefix":"NX"}}', 'vsl-0022', TIMESTAMP '2026-01-08 08:12:00 UTC');

-- Tombstone feed. Voyager is re-ingested after its delete (resurrection). Equinox is not, so it stays deleted.
CREATE OR REPLACE TABLE starfleet.raw.vessel_delete_signal (
    entity_id VARCHAR,
    deleted_at TIMESTAMP(6) WITH TIME ZONE,
    source_row_id VARCHAR,
    ingested_at TIMESTAMP(6) WITH TIME ZONE
);
INSERT INTO starfleet.raw.vessel_delete_signal (entity_id, deleted_at, source_row_id, ingested_at) VALUES
('NCC-74656', TIMESTAMP '2026-02-01 00:00:00 UTC', 'del-0001', TIMESTAMP '2026-02-01 09:00:00 UTC'),
('NCC-72381', TIMESTAMP '2026-03-20 00:00:00 UTC', 'del-0002', TIMESTAMP '2026-03-20 09:00:00 UTC');


-- ============================================================
-- TRANSFORM LAYER: slice each sub-object out of the golden-record document. Still JSON, still one row per (vessel, ingestion).
-- ============================================================
CREATE OR REPLACE MATERIALIZED VIEW starfleet.transform.vessel
WITH (compression_codec = 'ZSTD') AS
SELECT registry,
    json_format(json_extract(json_parse(document_json), '$.vessel')) vessel_json,
    source_row_id, ingested_at
FROM starfleet.raw.starship_record
WHERE document_json IS NOT NULL AND document_json <> '';
CREATE OR REPLACE MATERIALIZED VIEW starfleet.transform.crew
WITH (compression_codec = 'ZSTD') AS
SELECT registry, crew_json, source_row_id, ingested_at
FROM (
    SELECT registry,
        json_format(json_extract(json_parse(document_json), '$.crew')) crew_json,
        source_row_id, ingested_at
    FROM starfleet.raw.starship_record
)
WHERE crew_json IS NOT NULL AND crew_json <> 'null';
CREATE OR REPLACE MATERIALIZED VIEW starfleet.transform.sensor_log
WITH (compression_codec = 'ZSTD') AS
SELECT registry, sensor_logs_json, source_row_id, ingested_at
FROM (
    SELECT registry,
        json_format(json_extract(json_parse(document_json), '$.sensor_logs')) sensor_logs_json,
        source_row_id, ingested_at
    FROM starfleet.raw.starship_record
)
WHERE sensor_logs_json IS NOT NULL AND sensor_logs_json <> 'null';


-- ============================================================
-- INTERMEDIATE LAYER: tombstone (obituary) MV.
-- ============================================================
CREATE OR REPLACE MATERIALIZED VIEW starfleet.intermediate.vessel_deletes
WITH (compression_codec = 'ZSTD') AS
SELECT entity_id, MAX(deleted_at) deleted_at
FROM starfleet.raw.vessel_delete_signal
GROUP BY entity_id;


-- ============================================================
-- ANALYTICS LAYER: dedup latest document per vessel, then flatten the transform JSON into relational rows.
-- ============================================================
-- Vessel: latest per registry (MAX_BY winner), scalar extract, tombstone resurrection, hash surrogate.
CREATE OR REPLACE MATERIALIZED VIEW starfleet.analytics.vessel
WITH (compression_codec = 'ZSTD') AS
WITH winners AS (
    SELECT registry, MAX_BY(source_row_id, ingested_at) win_id, MAX(ingested_at) ingested_at
    FROM starfleet.transform.vessel
    GROUP BY registry
),
latest AS (
    SELECT v.registry, v.vessel_json, w.ingested_at
    FROM starfleet.transform.vessel v
    INNER JOIN winners w ON v.registry = w.registry AND v.source_row_id = w.win_id
)
SELECT from_big_endian_64(xxhash64(to_utf8(COALESCE(l.registry, '')))) vessel_id,
    l.registry,
    json_extract_scalar(l.vessel_json, '$.name') vessel_name,
    json_extract_scalar(l.vessel_json, '$.class') vessel_class,
    json_extract_scalar(l.vessel_json, '$.affiliation') affiliation,
    json_extract_scalar(l.vessel_json, '$.status') status,
    json_extract_scalar(l.vessel_json, '$.commissioned') commissioned,
    l.ingested_at
FROM latest l
LEFT JOIN starfleet.intermediate.vessel_deletes del ON l.registry = del.entity_id
WHERE del.deleted_at IS NULL OR l.ingested_at > del.deleted_at;

-- Crew: latest manifest per vessel (narrow-key winner keeps the array out of the aggregate), CAST + UNNEST flatten, hash surrogate.
CREATE OR REPLACE MATERIALIZED VIEW starfleet.analytics.crew_member
WITH (compression_codec = 'ZSTD') AS
WITH winners AS (
    SELECT registry, MAX_BY(source_row_id, ingested_at) win_id
    FROM starfleet.transform.crew
    GROUP BY registry
),
latest AS (
    SELECT c.registry, c.crew_json
    FROM starfleet.transform.crew c
    INNER JOIN winners w ON c.registry = w.registry AND c.source_row_id = w.win_id
),
flat AS (
    SELECT l.registry, m.name member_name, m.crew_rank, m.species, m.duty_position, m.member_status, m.ord
    FROM latest l
    CROSS JOIN UNNEST(
        TRY(CAST(json_parse(l.crew_json) AS array(row(
            name VARCHAR, crew_rank VARCHAR, species VARCHAR, duty_position VARCHAR, posting_stardate VARCHAR, member_status VARCHAR
        ))))
    ) WITH ORDINALITY AS m(name, crew_rank, species, duty_position, posting_stardate, member_status, ord)
)
SELECT from_big_endian_64(xxhash64(to_utf8(concat_ws(chr(31),
        COALESCE(registry, ''), COALESCE(member_name, ''), COALESCE(CAST(ord AS VARCHAR), ''))))) crew_id,
    registry, member_name, crew_rank, species, duty_position, member_status
FROM flat;

-- Sensor reading: latest logs per vessel, double UNNEST (logs then readings), hash surrogate over (log_id, ordinal).
CREATE OR REPLACE MATERIALIZED VIEW starfleet.analytics.sensor_reading
WITH (compression_codec = 'ZSTD') AS
WITH winners AS (
    SELECT registry, MAX_BY(source_row_id, ingested_at) win_id
    FROM starfleet.transform.sensor_log
    GROUP BY registry
),
latest AS (
    SELECT s.registry, s.sensor_logs_json
    FROM starfleet.transform.sensor_log s
    INNER JOIN winners w ON s.registry = w.registry AND s.source_row_id = w.win_id
),
logs AS (
    SELECT l.registry, lg.log_id, lg.stardate, lg.readings
    FROM latest l
    CROSS JOIN UNNEST(
        TRY(CAST(json_parse(l.sensor_logs_json) AS array(row(
            log_id VARCHAR, stardate VARCHAR, readings array(row(reading_type VARCHAR, target VARCHAR, reading_value VARCHAR, unit VARCHAR))
        ))))
    ) AS lg(log_id, stardate, readings)
),
flat AS (
    SELECT g.registry, g.log_id, g.stardate, r.reading_type, r.target, r.reading_value, r.unit, r.ord
    FROM logs g
    CROSS JOIN UNNEST(g.readings) WITH ORDINALITY AS r(reading_type, target, reading_value, unit, ord)
)
SELECT from_big_endian_64(xxhash64(to_utf8(concat_ws(chr(31),
        COALESCE(log_id, ''), COALESCE(CAST(ord AS VARCHAR), ''))))) reading_id,
    registry vessel_registry, log_id, stardate, reading_type, target, reading_value, unit
FROM flat;


-- ============================================================
-- REFRESH: transform, intermediate then analytics.
-- ============================================================
REFRESH MATERIALIZED VIEW starfleet.transform.vessel;
REFRESH MATERIALIZED VIEW starfleet.transform.crew;
REFRESH MATERIALIZED VIEW starfleet.transform.sensor_log;
REFRESH MATERIALIZED VIEW starfleet.intermediate.vessel_deletes;
REFRESH MATERIALIZED VIEW starfleet.analytics.vessel;
REFRESH MATERIALIZED VIEW starfleet.analytics.crew_member;
REFRESH MATERIALIZED VIEW starfleet.analytics.sensor_reading;




-- ============================================================
-- QA TIME
-- QUICK CHECK TO VERIFY EVERYTHING LANDED (run after refreshes above):
-- ============================================================

-- SELECT count(*) FROM starfleet.transform.vessel;         -- expect 20 rows (all versions)
-- SELECT count(*) FROM starfleet.transform.crew;           -- expect 7 crew-bearing document versions
-- SELECT count(*) FROM starfleet.transform.sensor_log;     -- expect 8 log-bearing document versions
-- SELECT count(*) FROM starfleet.analytics.vessel;         -- expect 17 (Equinox tombstoned, Voyager resurrected)
-- SELECT count(*) FROM starfleet.analytics.crew_member;    -- expect 36 across 5 vessels
-- SELECT count(*) FROM starfleet.analytics.sensor_reading; -- expect 21 readings across 6 vessels
-- SELECT count(DISTINCT crew_id) = count(*) FROM starfleet.analytics.crew_member;       -- surrogate uniqueness
-- SELECT count(DISTINCT reading_id) = count(*) FROM starfleet.analytics.sensor_reading; -- surrogate uniqueness
-- SELECT registry, status FROM starfleet.analytics.vessel WHERE registry IN ('NCC-1701-D'); -- expect destroyed (latest won)
-- SELECT registry, duty_position FROM starfleet.analytics.crew_member WHERE registry = 'NCC-1701-D' AND member_name = 'Geordi La Forge'; -- expect Chief Engineer (v2 won)



-- ============================================================
-- TEARDOWN (commented, run manually to reset the environment). Drop dependents before sources.
-- ============================================================

-- DROP MATERIALIZED VIEW IF EXISTS starfleet.analytics.sensor_reading;
-- DROP MATERIALIZED VIEW IF EXISTS starfleet.analytics.crew_member;
-- DROP MATERIALIZED VIEW IF EXISTS starfleet.analytics.vessel;
-- DROP MATERIALIZED VIEW IF EXISTS starfleet.intermediate.vessel_deletes;
-- DROP MATERIALIZED VIEW IF EXISTS starfleet.transform.sensor_log;
-- DROP MATERIALIZED VIEW IF EXISTS starfleet.transform.crew;
-- DROP MATERIALIZED VIEW IF EXISTS starfleet.transform.vessel;
-- DROP TABLE IF EXISTS starfleet.raw.vessel_delete_signal;
-- DROP TABLE IF EXISTS starfleet.raw.starship_record;
-- DROP SCHEMA IF EXISTS raw
-- DROP SCHEMA IF EXISTS transform
-- DROP SCHEMA IF EXISTS analytisc
-- DROP SCHEMA IF EXISTS intermediate
