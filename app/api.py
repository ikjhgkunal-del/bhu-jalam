# app/api.py
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd

from app.analytics import compute_daily_fluctuation, estimate_yield, plot_mean_levels
from app.scoring import compute_sustainability_score
from app.db import client, fetch_block_data

app = FastAPI(title="Groundwater Analytics API")

# ✅ Allow all origins for dev (restrict in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


# -------------------
# Health Check
# -------------------
@app.get("/")
def health():
    return {"status": "ok"}


# -------------------
# Districts & Blocks
# -------------------
@app.get("/districts")
def get_districts():
    response = client.rpc("get_districts").execute()
    if not response.data:
        raise HTTPException(
            status_code=404,
            detail={"error": "No districts found", "reason": "Database returned empty result"}
        )
    districts = sorted({row["district"].strip().title() for row in response.data if row.get("district")})
    return list(districts)



@app.get("/blocks")
def get_blocks(district: str = Query(...)):
    response = client.rpc("get_blocks_by_district", {"district_name": district}).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="No blocks found for this district")
    blocks = sorted({row["block"].strip().title() for row in response.data if row.get("block")})
    return blocks


@app.get("/district-by-block")
def get_district_by_block(block: str = Query(...)):
    """Find the district for a given block."""
    response = (
        client.table("groundwater")
        .select("district")
        .eq("block", block)
        .limit(1)
        .execute()
    )
    if not response.data:
        raise HTTPException(status_code=404, detail="No district found for this block")

    return {"block": block, "district": response.data[0]["district"]}


@app.get("/blocks-all")
def get_blocks_all():
    """Return mapping of block → district for all records."""
    response = client.rpc("get_blocks_all").execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="No blocks found")

    mapping = {row["block"].strip(): row["district"].strip() for row in response.data}
    return {"blocks": mapping}


# -------------------
# Analytics Endpoints
# -------------------
@app.get("/fluctuations-daily")
def fluctuations_daily(district: str, block: str):
    """Daily fluctuation in mean water level (last two days)."""
    result = compute_daily_fluctuation(district, block)
    if not result or "error" in result:
        raise HTTPException(status_code=404, detail=result.get("error", "No data found"))
    return result


from fastapi import HTTPException
import re

@app.get("/plot-mean-levels")
def plot_mean_levels_api(district: str, block: str, days: int = 10):
    """Return a base64 PNG plot of mean water levels for the last N days (case-insensitive + cleaned)."""

    # normalize inputs
    def normalize(text: str) -> str:
        if not text:
            return ""
        text = text.lower().strip()
        text = re.sub(r"[_\-\s]+", " ", text)   # collapse _, - and multiple spaces
        return text

    norm_district = normalize(district)
    norm_block = normalize(block)

    print(f"🔎 Normalized request → District={norm_district}, Block={norm_block}")

    # Call your existing function
    encoded = plot_mean_levels(norm_district, norm_block, days)

    if not encoded:
        raise HTTPException(
            status_code=404,
            detail=f"No data found for district='{district}', block='{block}'"
        )

    return {"plot_base64": encoded}



# -------------------
# Yield Endpoint
# -------------------
@app.get("/yield")
def yield_endpoint(district: str, block: str, days: int = 30):
    result = estimate_yield(district, block, days=days)
    if not result:
        raise HTTPException(status_code=404, detail="No yield data available")
    return {"estimated_irrigated_area_ha": result}



# -------------------
# Metadata Endpoints
# -------------------
@app.get("/last-recorded")
def last_recorded(district: str = Query(...), block: str = Query(...)):
    """Return last recorded timestamp for a block."""
    resp = (
        client.table("groundwater")
        .select("datetime_ts")
        .eq("district", district)
        .eq("block", block)
        .order("datetime_ts", desc=True)
        .limit(1)
        .execute()
    )
    if not resp.data:
        return {"last_recorded": None}
    return {"last_recorded": resp.data[0]["datetime_ts"]}


@app.get("/last-water-level")
def last_water_level(district: str = Query(...), block: str = Query(...)):
    """Return last water level for a block."""
    resp = (
        client.table("groundwater")
        .select("water_level, datetime_ts")
        .eq("district", district)
        .eq("block", block)
        .order("datetime_ts", desc=True)
        .limit(1)
        .execute()
    )
    if not resp.data:
        return {"last_water_level": None}
    return resp.data[0]


@app.get("/rainfall")
def rainfall(district: str = Query(...), block: str = Query(...)):
    """Return last recorded rainfall for a block."""
    resp = (
        client.table("groundwater")
        .select("rainfall_mm, datetime_ts")
        .eq("district", district)
        .eq("block", block)
        .order("datetime_ts", desc=True)
        .limit(1)
        .execute()
    )
    if not resp.data:
        return {"rainfall_mm": None}
    return resp.data[0]


@app.get("/aquifer")
def get_aquifer_type(district: str = Query(...), block: str = Query(...)):
    """Return aquifer type for a block."""
    resp = (
        client.table("groundwater")
        .select("aquifer_type")
        .eq("district", district)
        .eq("block", block)
        .order("datetime_ts", desc=True)
        .limit(1)
        .execute()
    )
    if not resp.data:
        return {"aquifer_type": None}
    return {"district": district, "block": block, "aquifer_type": resp.data[0].get("aquifer_type")}


# -------------------
# Sustainability Score
# -------------------
@app.get("/score")
def get_sustainability_score(district: str = Query(...), block: str = Query(...)):
    try:
        resp = client.table("groundwater") \
            .select("datetime_ts, water_level, rainfall_mm, specific_yield, aquifer_type, wq_ph, wq_ec, wq_cl, wq_f, wq_total_hardness") \
            .ilike("district", f"%{district}%") \
            .ilike("block", f"%{block}%") \
            .order("datetime_ts", desc=True) \
            .limit(1000) \
            .execute()

        if not resp.data:
            return {"error": f"No groundwater data found for district='{district}', block='{block}'"}

        df = pd.DataFrame(resp.data)
        df["datetime_ts"] = pd.to_datetime(df["datetime_ts"], errors="coerce")
        df = df.dropna(subset=["datetime_ts", "water_level"])

        if df.empty:
            return {"error": "Not enough valid data for scoring"}

        # Aggregate into daily means
        df["date"] = df["datetime_ts"].dt.date
        daily = df.groupby("date").agg({
            "water_level": "mean",
            "rainfall_mm": "mean",
            "specific_yield": "mean",
            "aquifer_type": "last",
            "wq_ph": "mean",
            "wq_ec": "mean",
            "wq_cl": "mean",
            "wq_f": "mean",
            "wq_total_hardness": "mean"
        }).reset_index()

        daily.rename(columns={"water_level": "mean_level"}, inplace=True)

        score = compute_sustainability_score(daily.tail(30))

        return {
            "district": district,
            "block": block,
            "final_score_pct": score.get("final_score_pct"),
            "components": {k: v for k, v in score.items() if k != "final_score_pct"}
        }
    except Exception as e:
        return {"error": f"Score computation failed: {str(e)}"}




# -------------------
# Combined Extras Endpoint
# -------------------
def safe_round(value, digits=2):
    try:
        return round(float(value), digits)
    except (TypeError, ValueError):
        return None


from fastapi import Query
import pandas as pd
from app.db import client
from app.analytics import compute_daily_fluctuation, estimate_yield, plot_mean_levels
from app.scoring import compute_sustainability_score

@app.get("/extras")
def get_extras(district: str = Query(...), block: str = Query(...)):
    try:
        # 🔹 Fetch raw data from Supabase
        resp = client.table("groundwater") \
            .select("datetime_ts, water_level, rainfall_mm, specific_yield, aquifer_type, wq_ph, wq_ec, wq_cl, wq_f, wq_total_hardness") \
            .eq("district", district) \
            .eq("block", block) \
            .order("datetime_ts", desc=True) \
            .limit(500) \
            .execute()

        rows = resp.data or []
        if not rows:
            return {
                "error": f"No groundwater data found for district={district}, block={block}"
            }

        # 🔹 Convert to DataFrame
        df = pd.DataFrame(rows)
        if df.empty:
            return {
                "error": "Fetched rows but DataFrame is empty after conversion"
            }

        df["datetime_ts"] = pd.to_datetime(df["datetime_ts"], errors="coerce")
        df = df.dropna(subset=["datetime_ts", "water_level"])
        if df.empty:
            return {
                "error": "All rows invalid after cleaning (no datetime_ts or water_level)"
            }

        # 🔹 Daily aggregation
        df["date"] = df["datetime_ts"].dt.date
        daily = df.groupby("date").agg({
            "water_level": "mean",
            "rainfall_mm": "mean",
            "specific_yield": "mean",
            "aquifer_type": "last",
            "wq_ph": "mean",
            "wq_ec": "mean",
            "wq_cl": "mean",
            "wq_f": "mean",
            "wq_total_hardness": "mean"
        }).reset_index()

        daily.rename(columns={"water_level": "mean_level"}, inplace=True)

        if daily.empty:
            return {"error": "Not enough aggregated daily data"}

        # 🔹 Safely extract last record
        last_row = daily.iloc[-1].to_dict()
        last_date = str(last_row.get("date"))
        last_level = safe_round(last_row.get("mean_level"), 2)
        rainfall = safe_round(last_row.get("rainfall_mm"), 2)
        aquifer = last_row.get("aquifer_type", "Unknown")

        # 🔹 Compute sustainability score
        try:
            score = compute_sustainability_score(daily.tail(60))
            final_score = score.get("final_score_pct", None)
        except Exception as e:
            final_score = None
            score = {"error": f"Scoring failed: {str(e)}"}

        # 🔹 Daily fluctuation (last 2 days)
        fluctuation = None
        if len(daily) >= 2:
            fluctuation = safe_round(daily["mean_level"].iloc[-1] - daily["mean_level"].iloc[-2], 2)

        # 🔹 Yield estimation (if specific_yield exists)
        yield_info = None
        if "specific_yield" in daily and daily["specific_yield"].notna().any():
            try:
                area_used = 1000  # hectares (reference area)
                sy = daily["specific_yield"].median()
                available_volume = round(area_used * sy * 3.5, 2)  # dummy factor
                irrigated_area = round(area_used * 0.7, 2)
                yield_info = {
                    "area_ha_used": area_used,
                    "available_volume_m3": available_volume,
                    "estimated_irrigated_area_ha": irrigated_area
                }
            except Exception as e:
                yield_info = {"error": f"Yield calc failed: {str(e)}"}

        # 🔹 Water Quality
        wq = {
            "pH": safe_round(last_row.get("wq_ph"), 2),
            "EC": safe_round(last_row.get("wq_ec"), 2),
            "Cl": safe_round(last_row.get("wq_cl"), 2),
            "F": safe_round(last_row.get("wq_f"), 2),
            "Hardness": safe_round(last_row.get("wq_total_hardness"), 2),
        }

        return {
            "district": district,
            "block": block,
            "last_date": last_date,
            "last_water_level": last_level,
            "rainfall_mm": rainfall,
            "aquifer_type": aquifer,
            "final_score_pct": final_score,
            "score_components": score,
            "daily_fluctuation": fluctuation,
            "yield": yield_info,
            "water_quality": wq,
            "debug": {
                "rows_fetched": len(rows),
                "daily_rows": len(daily),
                "last_row": last_row,
            }
        }

    except Exception as e:
        return {
            "error": f"Internal error in extras: {str(e)}"
        }

