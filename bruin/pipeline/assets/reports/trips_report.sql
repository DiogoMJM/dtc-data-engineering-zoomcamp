/* @bruin

# Docs:
# - SQL assets: https://getbruin.com/docs/bruin/assets/sql
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks: https://getbruin.com/docs/bruin/quality/available_checks

# Reports layer: Aggregate staging data for analytics
name: reports.trips_report

# Platform type: DuckDB SQL
type: duckdb.sql

# Dependency: aggregates data from staging layer
depends:
  - staging.trips

# TODO: Choose materialization strategy.
# For reports, `time_interval` is a good choice to rebuild only the relevant time window.
# Important: Use the same `incremental_key` as staging (e.g., pickup_datetime) for consistency.
materialization:
  type: table
  # Time-interval strategy: rebuild only the requested window
  strategy: time_interval
  # Incremental key: report date column for time-based partitioning
  incremental_key: report_date
  # Time granularity: daily aggregation
  time_granularity: date

# Report columns: dimensions and aggregated metrics
columns:
  - name: report_date
    type: date
    description: "Date of the trips (derived from pickup_datetime)"
    primary_key: true
    checks:
      - name: not_null
  - name: VendorID
    type: integer
    description: "Taxi vendor ID"
    primary_key: true
    checks:
      - name: not_null
  - name: payment_type_name
    type: string
    description: "Payment type name"
    primary_key: true
    checks:
      - name: not_null
  - name: trip_count
    type: bigint
    description: "Total number of trips"
    checks:
      - name: non_negative
  - name: total_passengers
    type: bigint
    description: "Total number of passengers across all trips"
    checks:
      - name: non_negative
  - name: total_distance_miles
    type: float
    description: "Total distance traveled in miles"
    checks:
      - name: non_negative
  - name: total_fare_amount
    type: float
    description: "Total fare amount (before tips)"
    checks:
      - name: non_negative
  - name: total_tip_amount
    type: float
    description: "Total tips collected"
    checks:
      - name: non_negative
  - name: total_amount
    type: float
    description: "Total revenue (fare + tips + extras + taxes)"
    checks:
      - name: non_negative
  - name: avg_fare_amount
    type: float
    description: "Average fare per trip"
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: float
    description: "Average trip distance"
    checks:
      - name: non_negative
  - name: avg_passenger_count
    type: float
    description: "Average passengers per trip"
    checks:
      - name: non_negative

@bruin */

-- Reports layer: Aggregate staging data for analytics and dashboards
--
-- Aggregation level: daily by vendor and payment type
-- Metrics: trip count, passengers, distance, revenue, averages
-- Time window: filter to incremental processing window

SELECT
  DATE(s.pickup_datetime) AS report_date,
  s.VendorID,
  s.payment_type_name,
  COUNT(*) AS trip_count,
  SUM(s.passenger_count) AS total_passengers,
  SUM(s.trip_distance) AS total_distance_miles,
  SUM(s.fare_amount) AS total_fare_amount,
  SUM(s.tip_amount) AS total_tip_amount,
  SUM(s.total_amount) AS total_amount,
  AVG(s.fare_amount) AS avg_fare_amount,
  AVG(s.trip_distance) AS avg_trip_distance,
  AVG(s.passenger_count) AS avg_passenger_count
FROM staging.trips s
WHERE DATE(s.pickup_datetime) >= DATE('{{ start_datetime }}')
  AND DATE(s.pickup_datetime) < DATE('{{ end_datetime }}')
GROUP BY
  DATE(s.pickup_datetime),
  s.VendorID,
  s.payment_type_name
ORDER BY
  report_date DESC,
  VendorID,
  payment_type_name
