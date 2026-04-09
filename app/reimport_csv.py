import pandas as pd
from supabase import create_client
import math
import numpy as np

# --- CONFIG ---
CSV_FILE = "all_groundwater.csv"
BATCH_SIZE = 500
TABLE_NAME = "groundwater"

# --- SUPABASE CONNECTION ---
url = "https://rxfbbhlwotcqncmnnqzn.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4ZmJiaGx3b3RjcW5jbW5ucXpuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NjQyNzcsImV4cCI6MjA3NDA0MDI3N30.4xgCDnSEz_MtX15_9ftYHqGtfUsmxUc7c2vO5L2om6A"   # ⚠️ service_role key
supabase = create_client(url, key)

# --- LOAD CSV ---
df = pd.read_csv(CSV_FILE, low_memory=False)
print(f"Loaded {len(df)} rows from {CSV_FILE}")

# --- NUMERIC CLEANUP ---
numeric_columns = [
    "water_level", "barometric",
    "latitude", "longitude", "wq_distance_km",
    "wq_ph", "wq_ec", "wq_cl", "wq_f",
    "wq_total_hardness", "specific_yield"
]

for col in numeric_columns:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

# Replace NaN/Inf with None for JSON-safe upload
df = df.replace([np.nan, np.inf, -np.inf], None)

expected_columns = [
    "datetime", "water_level", "barometric",
    "state", "district", "block", "site_name", "well_id",
    "latitude", "longitude", "wq_distance_km", "wq_ph",
    "wq_ec", "wq_cl", "wq_f", "wq_total_hardness",
    "aquifer_type", "specific_yield"
]

df = df[[c for c in expected_columns if c in df.columns]]
print("Uploading columns:", df.columns.tolist())

# --- INSERT IN BATCHES ---
total_rows = len(df)
batches = math.ceil(total_rows / BATCH_SIZE)

for i in range(batches):
    start = i * BATCH_SIZE
    end = min((i + 1) * BATCH_SIZE, total_rows)
    chunk = df.iloc[start:end]

    records = chunk.to_dict(orient="records")

    response = supabase.table(TABLE_NAME).insert(records).execute()
    print(f"Inserted rows {start+1}–{end} / {total_rows}")

print("✅ Done inserting all rows into Supabase.")
