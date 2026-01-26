import pandas as pd
from sqlalchemy import create_engine
from tqdm.auto import tqdm

df = pd.read_parquet('green_tripdata_2025-11.parquet')

engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')

# Create table schema (no data)
df.head(0).to_sql(
    name="green_tripdata_2025_11",
    con=engine,
    if_exists="replace"
)

print("Table created")

# Insert chunk
df.to_sql(
name="green_tripdata_2025_11",
con=engine,
if_exists="append"
)

print("Data inserted")