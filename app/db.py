from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

URL = os.getenv("SUPABASE_URL")
KEY = os.getenv("SUPABASE_KEY")

if not URL or not KEY:
    raise RuntimeError("❌ Set SUPABASE_URL and SUPABASE_KEY in .env")

client = create_client(URL, KEY)

# -------------------------------
# Fetch districts and blocks
# -------------------------------
def fetch_districts():
    """
    Get all unique districts in groundwater table.
    """
    resp = client.table("groundwater").select("district").execute()
    if not resp.data:
        return []
    districts = sorted({row["district"] for row in resp.data if row.get("district")})
    return districts


def fetch_blocks(district: str):
    """
    Get all unique blocks in a given district.
    """
    resp = (
        client.table("groundwater")
        .select("block")
        .ilike("district", district)
        .execute()
    )
    if not resp.data:
        return []
    blocks = sorted({row["block"] for row in resp.data if row.get("block")})
    return blocks


# -------------------------------
# Fetch groundwater data
# -------------------------------
def fetch_groundwater(district: str, block: str, limit: int = 1000):
    """
    Fetch groundwater readings for a district/block.
    """
    resp = (
        client.table("groundwater")
        .select(
            "datetime_ts, water_level, rainfall_mm, specific_yield, district, block"
        )
        .ilike("district", district)
        .ilike("block", block)
        .order("datetime_ts", desc=True)
        .limit(limit)
        .execute()
    )
    return resp.data or []


def fetch_block_data(district: str, block: str, limit: int = 1000):
    """
    Fetch groundwater + water quality for a block.
    """
    resp = (
        client.table("groundwater")
        .select(
            "datetime_ts, water_level, rainfall_mm, specific_yield, district, block, aquifer_type, wq_ph, wq_ec, wq_cl, wq_f, wq_total_hardness"
        )
        .ilike("district", district)
        .ilike("block", block)
        .order("datetime_ts", desc=True)
        .limit(limit)
        .execute()
    )
    print(
        f"🔍 Query for district={district}, block={block} returned {len(resp.data)} rows"
    )
    return resp.data or []
