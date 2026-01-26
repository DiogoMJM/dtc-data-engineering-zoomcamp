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