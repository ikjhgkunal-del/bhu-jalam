import pandas as pd
import matplotlib.pyplot as plt
import io, base64
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
# Mean water level plot
# --------------------------
def plot_mean_levels(district: str, block: str, days: int = 10):
    rows = fetch_block_data(district, block, limit=1000)
    if not rows:
        return None

    df = pd.DataFrame(rows)
    df["datetime_ts"] = pd.to_datetime(df["datetime_ts"])
    df["date"] = df["datetime_ts"].dt.date

    daily = df.groupby("date")["water_level"].mean().reset_index(name="mean_level_m")
    daily = daily.tail(min(days, len(daily)))

    if daily.empty:
        print(f"[DEBUG] No daily means for {district} / {block}")
        return None

    plt.figure(figsize=(8, 4))
    plt.plot(
        daily["date"],
        daily["mean_level_m"],
        marker="o",
        linestyle="-",
        label="Mean Level",
    )
    plt.xticks(rotation=45)
    plt.xlabel("Date")
    plt.ylabel("Mean Water Level (m)")
    plt.title(f"Daily Mean Water Level (last {len(daily)} days)")
    plt.legend()

    buf = io.BytesIO()
    plt.tight_layout()
    plt.savefig(buf, format="png")
    plt.close()
    return base64.b64encode(buf.getvalue()).decode()


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
