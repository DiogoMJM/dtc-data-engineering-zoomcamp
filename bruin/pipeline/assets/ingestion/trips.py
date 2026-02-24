"""@bruin

name: ingestion.trips
type: python
image: python:3.11
connection: duckdb-default

materialization:
  type: table
  strategy: append

columns:
  - name: VendorID
    type: integer
    description: "Vendor ID (1 or 2)"
  - name: pickup_datetime
    type: timestamp
    description: "Trip pickup datetime"
  - name: dropoff_datetime
    type: timestamp
    description: "Trip dropoff datetime"
  - name: passenger_count
    type: integer
    description: "Number of passengers"
  - name: trip_distance
    type: float
    description: "Trip distance in miles"
  - name: RatecodeID
    type: integer
    description: "Rate code ID"
  - name: store_and_fwd_flag
    type: string
    description: "Store and forward flag (Y/N)"
  - name: PULocationID
    type: integer
    description: "Pickup location ID"
  - name: DOLocationID
    type: integer
    description: "Dropoff location ID"
  - name: payment_type
    type: integer
    description: "Payment type ID"
  - name: fare_amount
    type: float
    description: "Fare amount"
  - name: extra
    type: float
    description: "Extra charges"
  - name: mta_tax
    type: float
    description: "MTA tax"
  - name: tip_amount
    type: float
    description: "Tip amount"
  - name: tolls_amount
    type: float
    description: "Tolls amount"
  - name: total_amount
    type: float
    description: "Total trip amount"
  - name: extracted_at
    type: timestamp
    description: "Timestamp when data was extracted"

@bruin"""

import json
import os
from datetime import datetime
from dateutil.relativedelta import relativedelta

import pandas as pd


def materialize():
    """
    Fetch NYC Taxi trip data from the TLC public endpoint.
    
    Fetches parquet files for configured taxi types and date range.
    Data is kept in raw format; cleaning and deduplication handled downstream in staging layer.
    
    Environment variables (set by Bruin):
    - BRUIN_START_DATE: Start date (YYYY-MM-DD)
    - BRUIN_END_DATE: End date (YYYY-MM-DD)
    - BRUIN_VARS: JSON string with pipeline variables including taxi_types list
    """
    # Parse Bruin environment variables
    start_date_str = os.environ.get("BRUIN_START_DATE", "")
    end_date_str = os.environ.get("BRUIN_END_DATE", "")
    bruin_vars_str = os.environ.get("BRUIN_VARS", "{}")
    
    start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
    end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()
    bruin_vars = json.loads(bruin_vars_str)
    taxi_types = bruin_vars.get("taxi_types", ["yellow"])
    
    # TLC public endpoint: https://d37ci6vzurychx.cloudfront.net/trip-data/
    base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/"
    
    # Generate list of (taxi_type, year, month) combinations to fetch
    current_date = start_date
    dfs = []
    extraction_timestamp = datetime.utcnow()
    
    while current_date <= end_date:
        for taxi_type in taxi_types:
            # Build file name: yellow_tripdata_2022-03.parquet
            filename = f"{taxi_type}_tripdata_{current_date.year}-{current_date.month:02d}.parquet"
            url = f"{base_url}{filename}"
            
            try:
                print(f"Fetching: {url}")
                df = pd.read_parquet(url)
                df["extracted_at"] = extraction_timestamp
                dfs.append(df)
                print(f"  ✓ Loaded {len(df)} rows")
            except Exception as e:
                print(f"  ✗ Failed to fetch {filename}: {str(e)}")
        
        # Move to next month
        current_date += relativedelta(months=1)
    
    # Combine all DataFrames
    if not dfs:
        raise ValueError("No data was fetched. Check taxi_types and date range.")
    
    result_df = pd.concat(dfs, ignore_index=True)
    print(f"\nTotal rows fetched: {len(result_df)}")
    
    return result_df


