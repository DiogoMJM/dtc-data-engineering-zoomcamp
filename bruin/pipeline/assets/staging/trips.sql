/* @bruin

# Docs:
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks (built-ins): https://getbruin.com/docs/bruin/quality/available_checks
# - Custom checks: https://getbruin.com/docs/bruin/quality/custom

# Staging layer: Clean, deduplicate, and enrich raw trip data
name: staging.trips
type: duckdb.sql

# Dependencies: raw trips and payment lookup reference table
depends:
  - ingestion.trips
  - ingestion.payment_lookup

# TODO: Choose time-based incremental processing if the dataset is naturally time-windowed.
# - This module expects you to use `time_interval` to reprocess only the requested window.
materialization:
  # What is materialization?
  # Materialization tells Bruin how to turn your SELECT query into a persisted dataset.
  # Docs: https://getbruin.com/docs/bruin/assets/materialization
  #
  # Materialization "type":
  # - table: persisted table
  # - view: persisted view (if the platform supports it)
  type: table
  # TODO: set a materialization strategy.
  # Docs: https://getbruin.com/docs/bruin/assets/materialization
  # suggested strategy: time_interval
  #
  # Incremental strategies (what does "incremental" mean?):
  # Incremental means you update only part of the destination instead of rebuilding everything every run.
  # In Bruin, this is controlled by `strategy` plus keys like `incremental_key` and `time_granularity`.
  #
  # Common strategies you can choose from (see docs for full list):
  # - create+replace (full rebuild)
  # - truncate+insert (full refresh without drop/create)
  # - append (insert new rows only)
  # - delete+insert (refresh partitions based on incremental_key values)
  # - merge (upsert based on primary key)
  # - time_interval (refresh rows within a time window)
  strategy: time_interval
  # Incremental key: process data by pickup time window
  incremental_key: pickup_datetime
  # Time granularity: timestamp (supports minute-level reprocessing if needed)
  time_granularity: timestamp

# Output columns with quality checks
columns:
  - name: trip_id
    type: string
    description: "Unique trip identifier (VendorID + pickup_datetime hash)"
    primary_key: true
    nullable: false
    checks:
      - name: not_null
      - name: unique
  - name: VendorID
    type: integer
    description: "Taxi vendor ID"
    checks:
      - name: not_null
  - name: pickup_datetime
    type: timestamp
    description: "Trip pickup datetime (incremental key)"
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: "Trip dropoff datetime"
    checks:
      - name: not_null
  - name: passenger_count
    type: integer
    description: "Number of passengers"
    checks:
      - name: not_null
  - name: trip_distance
    type: float
    description: "Trip distance in miles"
    checks:
      - name: non_negative
  - name: fare_amount
    type: float
    description: "Fare amount"
    checks:
      - name: non_negative
  - name: total_amount
    type: float
    description: "Total trip amount"
    checks:
      - name: non_negative
  - name: payment_type
    type: integer
    description: "Payment type ID"
    checks:
      - name: not_null
  - name: payment_type_name
    type: string
    description: "Payment type name (from lookup table)"
    checks:
      - name: not_null
  - name: extracted_at
    type: timestamp
    description: "Timestamp when data was extracted from source"

# Custom check: Validate that dropoff_datetime >= pickup_datetime
custom_checks:
  - name: valid_trip_times
    description: "Ensure dropoff time is after or equal to pickup time for all trips"
    query: |
      SELECT COUNT(*)
      FROM staging.trips
      WHERE dropoff_datetime < pickup_datetime
    value: 0

@bruin */

-- Staging layer: Clean, deduplicate, and enrich raw trip data
--
-- Steps:
-- 1. Deduplicate using ROW_NUMBER (partition by trip attributes, order by extracted_at DESC)
-- 2. Filter to valid records (non-null PKs, positive amounts, valid trip times)
-- 3. Enrich with payment type lookup
-- 4. Filter to the processing time window (required for time_interval strategy)

WITH deduplicated AS (
  SELECT
    t.*,
    ROW_NUMBER() OVER (
      PARTITION BY VendorID, pickup_datetime, dropoff_datetime, PULocationID, DOLocationID
      ORDER BY extracted_at DESC
    ) AS rn
  FROM ingestion.trips t
  WHERE pickup_datetime >= '{{ start_datetime }}'
    AND pickup_datetime < '{{ end_datetime }}'
),
filtered AS (
  SELECT
    d.VendorID,
    d.pickup_datetime,
    d.dropoff_datetime,
    d.passenger_count,
    d.trip_distance,
    d.RatecodeID,
    d.store_and_fwd_flag,
    d.PULocationID,
    d.DOLocationID,
    d.payment_type,
    d.fare_amount,
    d.extra,
    d.mta_tax,
    d.tip_amount,
    d.tolls_amount,
    d.total_amount,
    d.extracted_at
  FROM deduplicated d
  WHERE rn = 1
    -- Filter invalid records
    AND d.pickup_datetime IS NOT NULL
    AND d.dropoff_datetime IS NOT NULL
    AND d.payment_type IS NOT NULL
    AND d.passenger_count IS NOT NULL
    AND d.fare_amount >= 0
    AND d.total_amount >= 0
    AND d.trip_distance >= 0
)
SELECT
  CONCAT(f.VendorID, '_', f.pickup_datetime, '_', f.PULocationID) AS trip_id,
  f.VendorID,
  f.pickup_datetime,
  f.dropoff_datetime,
  f.passenger_count,
  f.trip_distance,
  f.RatecodeID,
  f.store_and_fwd_flag,
  f.PULocationID,
  f.DOLocationID,
  f.payment_type,
  pl.payment_type_name,
  f.fare_amount,
  f.extra,
  f.mta_tax,
  f.tip_amount,
  f.tolls_amount,
  f.total_amount,
  f.extracted_at
FROM filtered f
LEFT JOIN ingestion.payment_lookup pl
  ON f.payment_type = pl.payment_type_id
ORDER BY f.pickup_datetime DESC
