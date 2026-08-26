# demo-sql
SQL setup for demo environments

## Starfleet Lakehouse Demo

A self-contained Iceberg lakehouse for on Trino and Starburst Galaxy. Fictional Star Trek data.

### What it be

Several nested-JSON record source flies flow through four layers into clean, queryable tables. This mimics a real dedup-and-flatten pipeline with some extra soft-delete tables to simulate external tables influencing the final analytics layer.

### Run it

Run the file top to bottom one section at a time. Refresh order matters and is handled in the REFRESH block (transform, then intermediate, then analytics). 

A teardown is at the end. un it manually to reset and start over.

### Layers (catalog `starfleet`)

- `raw` - source tables. `starship_record` holds one nested document per (vessel, ingestion) with history. `vessel_delete_signal` is a separate soft-delete tombstone feed.
- `transform` - slices each sub-object (vessel, crew, sensor_logs) out of the document as JSON. One row per source version, no dedup.
- `intermediate` - `vessel_deletes`, the latest delete per entity.
- `analytics` - the tables the Starfleet admirals would query. Dedups to the latest version, flattens the JSON arrays into relational rows, applies soft deletes.

### What it demonstrates

- Latest-wins dedup with a narrow-key `MAX_BY` winner, keeping wide JSON out of the aggregate.
- JSON array flattening with `CAST` plus `UNNEST`, wrapped in `TRY` for safety (safety is job 1 in Starfleet).
- Tombstone soft deletes with resurrection (a re-ingested entity survives a delete).
- Distributed hash surrogates via `from_big_endian_64(xxhash64(...))` over the row grain.

### Included scenarios

- NCC-1701-D has two document versions, the later marks it destroyed and changes a crew posting, so latest-wins is visible.
- Voyager (NCC-74656) is declared destroyed but shows up years later. So the file is re-ingested, so the ship resurrects.
- Equinox (NCC-72381) is destroyed and never comes back. So its record is deleted with no re-ingest. It's gone now.

### Verify

Row-count and sanity checks are commented under QA TIME near the bottom.
