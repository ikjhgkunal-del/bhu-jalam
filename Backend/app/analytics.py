import pandas as pd
from app.db import client

# --------------------------
# Helper: fetch block data
# --------------------------
def fetch_block_data(district: str, block: str, limit: int = 1000):
    """
    Fetch groundwater rows for a district+block (case-insensitive).
    """
    resp = (
        client.table("groundwater")
        .select("*")
        .ilike("district", f"%{district}%")
        .ilike("block", f"%{block}%")
        .order("datetime_ts", desc=True)
        .limit(limit)
        .execute()
    )

    rows = resp.data or []
    print(f"[DEBUG] Fetched {len(rows)} rows for {district} / {block}")
    return rows


# --------------------------
# Daily fluctuation
# --------------------------
def compute_daily_fluctuation(district: str, block: str):
    rows = fetch_block_data(district, block, limit=500)
    if not rows:
        return {"error": "No data found"}

    df = pd.DataFrame(rows)
    df["datetime_ts"] = pd.to_datetime(df["datetime_ts"])
    df["date"] = df["datetime_ts"].dt.date

    daily = df.groupby("date")["water_level"].mean().reset_index(name="mean_level_m")

    if len(daily) < 2:
        return {"daily_fluctuation": None, "reason": "Not enough daily data"}

    fluctuation = round(
        daily["mean_level_m"].iloc[-1] - daily["mean_level_m"].iloc[-2], 3
    )

    return {
        "last_date": str(daily["date"].iloc[-1]),
        "daily_fluctuation": fluctuation,
        "records_used": len(daily),
    }


# --------------------------
# Mean water level data (JSON, no matplotlib)
# --------------------------
def get_mean_levels_data(district: str, block: str, days: int = 10):
    """
    Return daily mean water levels as JSON data points.
    The Flutter app renders the chart client-side using fl_chart.
    """
    rows = fetch_block_data(district, block, limit=1000)
    if not rows:
        return None

    df = pd.DataFrame(rows)
    df["datetime_ts"] = pd.to_datetime(df["datetime_ts"])
    df["date"] = df["datetime_ts"].dt.date

    daily = df.groupby("date")["water_level"].mean().reset_index(name="mean_level_m")
    daily = daily.sort_values("date")
    daily = daily.tail(min(days, len(daily)))

    if daily.empty:
        print(f"[DEBUG] No daily means for {district} / {block}")
        return None

    # Return as list of {date, value} objects
    data_points = []
    for _, row in daily.iterrows():
        data_points.append({
            "date": str(row["date"]),
            "value": round(float(row["mean_level_m"]), 3)
        })

    return data_points


# --------------------------
# Yield estimate (with area)
# --------------------------
DEFAULT_AREA_HA = 1000.0  # fallback if no area passed


def estimate_yield(district: str, block: str, days: int = 30, area_ha: float = 1000.0):
    rows = fetch_block_data(district, block, limit=1000)
    if not rows:
        return None

    df = pd.DataFrame(rows)
    df["datetime_ts"] = pd.to_datetime(df["datetime_ts"])
    df["date"] = df["datetime_ts"].dt.date

    recent = df.groupby("date").agg({
        "water_level": "mean",
        "specific_yield": "mean"
    }).reset_index()

    recent = recent.tail(min(days, len(recent)))
    if recent.empty:
        return None

    avg_level = recent["water_level"].mean()
    avg_sy = recent["specific_yield"].mean()

    # ✅ Assume 1 hectare = 10,000 m², thickness 5 m, crop demand = 5000 m³/ha
    thickness_m = 5.0
    crop_demand_m3_per_ha = 5000.0

    available_volume_m3 = area_ha * 10000 * thickness_m * (avg_sy / 100 if avg_sy > 1 else avg_sy)
    irrigated_area_ha = available_volume_m3 / crop_demand_m3_per_ha

    return round(irrigated_area_ha, 2)  # ✅ return single number
