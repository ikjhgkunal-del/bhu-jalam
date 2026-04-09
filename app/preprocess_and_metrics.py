import pandas as pd
import numpy as np
from pathlib import Path

# -------------------------
# Paths
# -------------------------
DATA_DIR = Path("data")

# Prefer "parquet_chunks", fallback to "parquets"
if (DATA_DIR / "parquet_chunks").exists():
    PARQUET_DIR = DATA_DIR / "parquet_chunks"
else:
    PARQUET_DIR = DATA_DIR / "parquets"

PARQUET_DIR.mkdir(parents=True, exist_ok=True)


# -------------------------
# Functions
# -------------------------

def preprocess_and_chunk():
    """
    Dummy placeholder. 
    In your pipeline this should generate parquet files into PARQUET_DIR.
    """
    print(f"✅ Using parquet directory: {PARQUET_DIR}")


def load_district(district: str) -> pd.DataFrame:
    """
    Load one district parquet file into a DataFrame.
    District name should match filename (case insensitive).
    """
    fname = district.lower().replace(" ", "_") + ".parquet"
    path = PARQUET_DIR / fname
    if not path.exists():
        raise FileNotFoundError(f"No parquet file found for {district} at {path}")
    return pd.read_parquet(path)


def compute_daily(df: pd.DataFrame, block: str = None) -> pd.DataFrame:
    """
    Resample groundwater data to daily averages.
    Includes rainfall and yield if available.
    """
    if block:
        df = df.loc[
            df["block"].astype(str).str.strip().str.title() == block.strip().title()
        ]
    if df.empty:
        return pd.DataFrame()

    df["datetime"] = pd.to_datetime(df["datetime"], errors="coerce")
    df = df.dropna(subset=["datetime"])
    df = df.set_index("datetime")

    # Find water level column
    wl_col = next(
        (c for c in df.columns if "water" in c.lower() and "level" in c.lower()), None
    )
    if not wl_col:
        return pd.DataFrame()

    # Daily mean water level
    daily = df.resample("D")[wl_col].mean().to_frame("mean_level")

    # Daily rainfall (sum, mm)
    rain_col = next((c for c in df.columns if "rain" in c.lower()), None)
    if rain_col:
        daily["rainfall_mm"] = df[rain_col].resample("D").sum(min_count=1)

    # Yield % (take last known / median as block property)
    yield_col = next((c for c in df.columns if "yield" in c.lower()), None)
    if yield_col:
        daily["yield_percent"] = df[yield_col].resample("D").median()

    # Daily fluctuation
    daily["delta_h_m"] = daily["mean_level"].diff()
    # Convert fluctuation to equivalent recharge in mm (proxy)
    daily["delta_h_eq_mm"] = daily["delta_h_m"] * -1000  # negative = decline

    return daily.reset_index()


def compute_score(daily_df: pd.DataFrame) -> dict:
    """
    Advanced sustainability scoring system.
    Considers deviation, storage trend, recharge efficiency, extraction pressure, threshold penalty.
    Includes aquifer yield and rainfall if available.
    """
    if daily_df.empty:
        return {"score": None}

    # --- Config ---
    weights = {
        "level_deviation": 0.40,
        "storage_trend": 0.25,
        "recharge_efficiency": 0.20,
        "extraction_pressure": 0.10,
        "threshold_penalty": 0.05,
    }
    thresholds = {
        "WL_deviation_max_m": 10.0,            # serious if >10 m deviation
        "storage_negativity_max_m3": 2_000_000, # proxy for severe depletion
        "critical_depth_m": 50.0,              # critical threshold depth
        "max_recharge_efficiency": 0.5,        # 50% rainfall recharge efficiency
    }

    # --- Baseline level ---
    baseline_level = daily_df["mean_level"].dropna().iloc[:30].mean()
    latest_level = daily_df["mean_level"].dropna().iloc[-1]

    # Factor 1: Level deviation
    WL_dev = abs(latest_level - baseline_level)
    score_level_dev = 1 - min(WL_dev / thresholds["WL_deviation_max_m"], 1)

    # Factor 2: Storage trend (proxy from last 30 days)
    recent = daily_df.tail(30)
    mean_storage = recent["delta_h_m"].sum()  # simple proxy
    score_storage = 1 - min(abs(mean_storage) / thresholds["storage_negativity_max_m3"], 1)

    # Factor 3: Recharge efficiency
    if "rainfall_mm" in daily_df.columns and daily_df["rainfall_mm"].sum() > 0:
        rainy = recent[recent["rainfall_mm"] > 0]
        if not rainy.empty:
            rainy["re_eff"] = rainy["delta_h_eq_mm"] / rainy["rainfall_mm"]
            re_eff = rainy["re_eff"].mean()
            score_recharge = min(max(re_eff / thresholds["max_recharge_efficiency"], 0), 1)
        else:
            score_recharge = 0.5
    else:
        score_recharge = 0.5

    # Factor 4: Extraction pressure
    neg_days = (recent["delta_h_m"] < 0).sum()
    total_days = len(recent)
    score_extraction = 1 - (neg_days / total_days) if total_days > 0 else 0.5

    # Factor 5: Threshold penalty
    score_threshold = 0 if latest_level > thresholds["critical_depth_m"] else 1

    # Combine
    final_score = (
        score_level_dev * weights["level_deviation"]
        + score_storage * weights["storage_trend"]
        + score_recharge * weights["recharge_efficiency"]
        + score_extraction * weights["extraction_pressure"]
        + score_threshold * weights["threshold_penalty"]
    )
    final_score_pct = round(final_score * 100, 2)

    return {
        "baseline_level": baseline_level,
        "latest_level": latest_level,
        "score_level_dev": score_level_dev,
        "score_storage": score_storage,
        "score_recharge": score_recharge,
        "score_extraction": score_extraction,
        "score_threshold": score_threshold,
        "final_score_pct": final_score_pct,
    }
