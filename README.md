# dtc-data-engineering-zoomcamp
Repo for the work done in the Data Engineering Zoomcamp 2026, from Data Talks Club.

# 01-docker-terraform homework
__Question 1__ \
docker run -it --rm --entrypoint=bash python:3.13.10-slim \
pip --version

__Question 3__ \
SELECT 
	COUNT(*) 
FROM green_tripdata_2025_11 
WHERE 1=1 
	AND lpep_pickup_datetime BETWEEN '2025-11-01' and '2025-12-01' 
	AND trip_distance <= 1

__Question 4__ \
SELECT 
	CAST(lpep_pickup_datetime AS DATE) 
	,MAX(trip_distance) 
FROM green_tripdata_2025_11 
WHERE 1=1 
	AND trip_distance <= 100 
GROUP BY 
	CAST(lpep_pickup_datetime AS DATE) 
ORDER BY 2 DESC 
LIMIT 1

__Question 5__ \
SELECT 
	z."Zone" 
	,COUNT(g.*) 
FROM green_tripdata_2025_11 g 
LEFT JOIN zones z 
	ON g."PULocationID" = z."LocationID" 
WHERE 1=1 
	AND g.lpep_pickup_datetime >= '2025-11-18 00:00:00' 
    AND g.lpep_pickup_datetime < '2025-11-19 00:00:00' 
GROUP BY 
	z."Zone" 
ORDER BY 2 DESC 
LIMIT 1

__Question 6__ \
SELECT 
	z2."Zone" 
	,g.tip_amount 
FROM green_tripdata_2025_11 g 
LEFT JOIN zones z1 
	ON g."PULocationID" = z1."LocationID" 
LEFT JOIN zones z2 
	ON g."DOLocationID" = z2."LocationID" 
WHERE 1=1 
	AND g.lpep_pickup_datetime BETWEEN '2025-11-01' AND '2025-12-01' 
	AND z1."Zone" = 'East Harlem North' 
ORDER BY 2 DESC 
LIMIT 1

# 02-workflow-orchestration homework
__Question 3__ \
SELECT COUNT(*) 
FROM `dtc-de-course-dmjm26.kestra_dataset.yellow_tripdata` 
WHERE tpep_pickup_datetime > '2019-12-31' AND tpep_pickup_datetime < '2021-01-01'

__Question 4__ \
SELECT COUNT(*) 
FROM `dtc-de-course-dmjm26.kestra_dataset.green_tripdata` 
WHERE lpep_pickup_datetime > '2019-12-31' AND lpep_pickup_datetime < '2021-01-01'

__Question 5__ \
SELECT COUNT(*) 
FROM `dtc-de-course-dmjm26.kestra_dataset.yellow_tripdata` 
WHERE tpep_pickup_datetime >= '2021-03-01' AND tpep_pickup_datetime < '2021-04-01'

# 03-data-warehouse
__Question 1__ \
SELECT
  COUNT(*)
FROM `kestra_dataset.yellow_tripdata_2024`
-- 20 332 093

__Question 2__ \
-- Materialized Table \
-- 155,12 MB \
SELECT
  COUNT(DISTINCT PULocationID)
FROM `kestra_dataset.yellow_tripdata_2024`;

-- External Table \
-- 0 MB \
SELECT
  COUNT(DISTINCT PULocationID)
FROM `kestra_dataset.yellow_tripdata_ext_2024`;

__Question 3__ \
SELECT
  PULocationID
FROM `kestra_dataset.yellow_tripdata_2024`;

SELECT
  PULocationID
  ,DOLocationID
FROM `kestra_dataset.yellow_tripdata_2024`;

__Question 4__ \
SELECT
  COUNT(*)
FROM `kestra_dataset.yellow_tripdata_2024`
WHERE 1=1
  AND fare_amount = 0;

__Question 5__ \
CREATE OR REPLACE TABLE `kestra_dataset.optimized_yellow_tripdata_2024`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID AS
SELECT * FROM `kestra_dataset.yellow_tripdata_ext_2024`;

__Question 6__ \
-- Not materialized Table \
SELECT
  COUNT(DISTINCT VendorID)
FROM `kestra_dataset.yellow_tripdata_2024`
WHERE 1=1
  AND tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';

-- Materialized Table \
SELECT
  COUNT(DISTINCT VendorID)
FROM `kestra_dataset.optimized_yellow_tripdata_2024`
WHERE 1=1
  AND tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';

__Question 9__ \
SELECT
  COUNT(*)
FROM `kestra_dataset.yellow_tripdata_2024`;