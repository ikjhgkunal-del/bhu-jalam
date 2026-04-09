-- ============================================
-- BHU-JALAM: Supabase Database Setup
-- Run this ENTIRE script in Supabase SQL Editor
-- (Dashboard → SQL Editor → New Query → Paste → Run)
-- ============================================

-- 1. Create the groundwater table
CREATE TABLE IF NOT EXISTS groundwater (
  id BIGSERIAL PRIMARY KEY,
  datetime_ts TIMESTAMPTZ,
  water_level DOUBLE PRECISION,
  barometric DOUBLE PRECISION,
  state TEXT,
  district TEXT,
  block TEXT,
  site_name TEXT,
  well_id TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  wq_distance_km DOUBLE PRECISION,
  wq_ph DOUBLE PRECISION,
  wq_ec DOUBLE PRECISION,
  wq_cl DOUBLE PRECISION,
  wq_f DOUBLE PRECISION,
  wq_total_hardness DOUBLE PRECISION,
  aquifer_type TEXT,
  specific_yield DOUBLE PRECISION,
  rainfall_mm DOUBLE PRECISION
);

-- 2. Create indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_gw_district ON groundwater(district);
CREATE INDEX IF NOT EXISTS idx_gw_block ON groundwater(block);
CREATE INDEX IF NOT EXISTS idx_gw_datetime ON groundwater(datetime_ts DESC);
CREATE INDEX IF NOT EXISTS idx_gw_district_block ON groundwater(district, block);

-- 3. RPC function: get all distinct districts
CREATE OR REPLACE FUNCTION get_districts()
RETURNS TABLE(district TEXT) AS $$
  SELECT DISTINCT district FROM groundwater WHERE district IS NOT NULL;
$$ LANGUAGE sql STABLE;

-- 4. RPC function: get blocks for a specific district
CREATE OR REPLACE FUNCTION get_blocks_by_district(district_name TEXT)
RETURNS TABLE(block TEXT) AS $$
  SELECT DISTINCT block FROM groundwater
  WHERE district ILIKE district_name AND block IS NOT NULL;
$$ LANGUAGE sql STABLE;

-- 5. RPC function: get all blocks with their districts
CREATE OR REPLACE FUNCTION get_blocks_all()
RETURNS TABLE(block TEXT, district TEXT) AS $$
  SELECT DISTINCT block, district FROM groundwater
  WHERE block IS NOT NULL AND district IS NOT NULL;
$$ LANGUAGE sql STABLE;

-- 6. Enable Row Level Security (allow public read via anon key)
ALTER TABLE groundwater ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access"
  ON groundwater
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Allow service role full access"
  ON groundwater
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Done! You should see "Success" in the SQL Editor.
