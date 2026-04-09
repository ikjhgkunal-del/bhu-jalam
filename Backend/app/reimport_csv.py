"""
reimport_csv.py - Import all_groundwater.csv into your NEW Supabase project.

Usage:
  1. Create a .env file in the Backend/ directory with:
       SUPABASE_URL=https://YOUR_PROJECT.supabase.co
       SUPABASE_KEY=your_service_role_key_here
  2. Run:
       python -m app.reimport_csv
     OR:
       python app/reimport_csv.py
"""
import sys
import io

# Fix Windows console encoding for Unicode output
if sys.stdout.encoding != 'utf-8':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import pandas as pd
from supabase import create_client
import math
import numpy as np
import os
from pathlib import Path
from dotenv import load_dotenv

# --- LOAD ENV ---
env_path = Path(__file__).resolve().parents[1] / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)
else:
    load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")

if not url or not key:
    print("[ERROR] Set SUPABASE_URL and SUPABASE_KEY in Backend/.env")
    print("   For data import, use the service_role key (not the anon key).")
    exit(1)

print(f"[OK] Connecting to Supabase: {url}")

# --- CONFIG ---
CSV_FILE = Path(__file__).resolve().parents[1] / "all_groundwater.csv"
BATCH_SIZE = 500
TABLE_NAME = "groundwater"

# --- SUPABASE CONNECTION ---
supabase = create_client(url, key)

# --- LOAD CSV ---
if not CSV_FILE.exists():
    print(f"[ERROR] CSV file not found: {CSV_FILE}")
    exit(1)

df = pd.read_csv(CSV_FILE, low_memory=False)
print(f"Loaded {len(df)} rows from {CSV_FILE.name}")

# --- RENAME datetime -> datetime_ts (match Supabase table column) ---
if "datetime" in df.columns and "datetime_ts" not in df.columns:
    df.rename(columns={"datetime": "datetime_ts"}, inplace=True)
    print("[OK] Renamed 'datetime' -> 'datetime_ts'")

# --- CONVERT DATE FORMAT ---
# CSV has MIXED formats:
#   - "2024-09-01 18:00:00" (YYYY-MM-DD, ~215K rows)
#   - "02-09-2025 06:00"    (DD-MM-YYYY, ~21K rows)
# We parse both and convert to ISO format for PostgreSQL
if "datetime_ts" in df.columns:
    # Try ISO format first (YYYY-MM-DD), then DD-MM-YYYY as fallback
    parsed_iso = pd.to_datetime(df["datetime_ts"], format="%Y-%m-%d %H:%M:%S", errors="coerce")
    parsed_dmy = pd.to_datetime(df["datetime_ts"], dayfirst=True, errors="coerce")

    # Use ISO where it worked, fall back to dayfirst
    df["datetime_ts"] = parsed_iso.fillna(parsed_dmy)

    null_count = df["datetime_ts"].isna().sum()
    valid_count = df["datetime_ts"].notna().sum()
    print(f"[OK] Parsed {valid_count} dates ({null_count} still null)")

    # Convert to string for JSON upload
    df["datetime_ts"] = df["datetime_ts"].dt.strftime("%Y-%m-%d %H:%M:%S")
    df["datetime_ts"] = df["datetime_ts"].replace("NaT", None)

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

# --- SELECT ONLY EXPECTED COLUMNS ---
expected_columns = [
    "datetime_ts", "water_level", "barometric",
    "state", "district", "block", "site_name", "well_id",
    "latitude", "longitude", "wq_distance_km", "wq_ph",
    "wq_ec", "wq_cl", "wq_f", "wq_total_hardness",
    "aquifer_type", "specific_yield"
]

df = df[[c for c in expected_columns if c in df.columns]]
print("Uploading columns:", df.columns.tolist())

# --- DROP columns that are entirely None (reduces payload) ---
before = len(df.columns)
df = df.dropna(axis=1, how="all")
after = len(df.columns)
if before != after:
    print(f"  Dropped {before - after} all-null columns")

# --- INSERT IN BATCHES ---
total_rows = len(df)
batches = math.ceil(total_rows / BATCH_SIZE)

print(f"\n[UPLOAD] Uploading {total_rows} rows in {batches} batches of {BATCH_SIZE}...")
print("   This may take a few minutes...\n")

failed_batches = []
for i in range(batches):
    start = i * BATCH_SIZE
    end = min((i + 1) * BATCH_SIZE, total_rows)
    chunk = df.iloc[start:end]

    records = chunk.to_dict(orient="records")

    try:
        response = supabase.table(TABLE_NAME).insert(records).execute()
        pct = round((end / total_rows) * 100, 1)
        print(f"  [OK] Batch {i+1}/{batches} -- rows {start+1}-{end} ({pct}%)")
    except Exception as e:
        print(f"  [FAIL] Batch {i+1}/{batches} FAILED -- rows {start+1}-{end}: {e}")
        failed_batches.append((start, end))

print(f"\n{'='*50}")
if failed_batches:
    print(f"[WARN] {len(failed_batches)} batches failed. You can retry them.")
    for s, e in failed_batches:
        print(f"   Rows {s+1}-{e}")
else:
    print(f"[DONE] All {total_rows} rows inserted into '{TABLE_NAME}' table.")
