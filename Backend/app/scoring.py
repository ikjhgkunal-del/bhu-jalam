import pandas as pd
import numpy as np

def compute_sustainability_score(
    daily_df: pd.DataFrame,
    rainfall_col: str = "rainfall_mm",
    yield_col: str = "yield_percent",
    weights: dict = None,
    thresholds: dict = None
):
    """
    Compute groundwater sustainability score with aquifer yield and rainfall.

    Parameters
    ----------
    daily_df : pd.DataFrame
        Must contain:
          - 'date' or 'datetime' column
          - 'mean_level' (m bgl, meters below ground level)
          - optionally rainfall_col (mm)
          - optionally yield_col (%)
    rainfall_col : str
        Column for rainfall (mm).
    yield_col : str
        Column for aquifer yield (%).
    weights : dict
        Custom weight for scoring components.
    thresholds : dict
        Threshold values for evaluation.

    Returns
    -------
    dict
        Components + final sustainability score.
    """

    # ---------------------------
    # Default weights and thresholds
    # ---------------------------
    if weights is None:
        weights = {
            "level_deviation": 0.30,
            "storage_trend": 0.20,
            "recharge_efficiency": 0.20,
            "extraction_pressure": 0.10,
            "threshold_penalty": 0.10,
            "yield_factor": 0.10
        }

    if thresholds is None:
        thresholds = {
            "WL_deviation_max_m": 10.0,             # critical deviation
            "storage_negativity_max": 2.0,          # m level drop over 30d
            "critical_depth_m": 50.0,               # below 50m is severe
            "max_recharge_efficiency": 0.5,         # max 50% rain → recharge
            "ideal_yield_percent": 30.0             # target good aquifer yield
        }

    # ---------------------------
    # Prep data
    # ---------------------------
    df = daily_df.copy()
    if "datetime" in df.columns:
        df["date"] = pd.to_datetime(df["datetime"])
    if "date" not in df.columns:
        raise ValueError("daily_df must contain 'date' or 'datetime' column")

    if "mean_level" not in df.columns:
        raise ValueError("daily_df must contain 'mean_level' column")

    df = df.sort_values("date").reset_index(drop=True)

    # baseline = first 30 days
    baseline = df["mean_level"].dropna().iloc[:30].mean()
    latest = df["mean_level"].dropna().iloc[-1]

    # ---------------------------
    # Factor 1: Level deviation
    # ---------------------------
    WL_dev = abs(latest - baseline)
    score_level_dev = 1 - min(WL_dev / thresholds["WL_deviation_max_m"], 1)

    # ---------------------------
    # Factor 2: Storage trend
    # (avg change in last 30 days)
    # ---------------------------
    recent = df.tail(30)
    if len(recent) >= 2:
        mean_storage_change = recent["mean_level"].diff().mean()
        score_storage = 1 - min(abs(mean_storage_change) / thresholds["storage_negativity_max"], 1)
    else:
        score_storage = 0.5

    # ---------------------------
    # Factor 3: Recharge efficiency
    # ---------------------------
    score_recharge = 0.5
    if rainfall_col in df.columns and df[rainfall_col].notna().any():
        rainy = df[df[rainfall_col] > 0].copy()
        if not rainy.empty:
            rainy["re_eff"] = rainy["mean_level"].diff() / rainy[rainfall_col].replace(0, np.nan)
            re_eff = rainy["re_eff"].dropna().mean()
            score_recharge = min(max(re_eff / thresholds["max_recharge_efficiency"], 0), 1)

    # ---------------------------
    # Factor 4: Extraction pressure
    # (fraction of days with negative Δh)
    # ---------------------------
    df["delta_h"] = df["mean_level"].diff()
    neg_days = (df["delta_h"] < 0).sum()
    total_days = len(df) - 1
    score_extraction = 1 - (neg_days / total_days) if total_days > 0 else 0.5

    # ---------------------------
    # Factor 5: Threshold penalty
    # ---------------------------
    score_threshold = 0 if latest > thresholds["critical_depth_m"] else 1

    # ---------------------------
    # Factor 6: Aquifer yield factor
    # ---------------------------
    if yield_col in df.columns and df[yield_col].notna().any():
        median_yield = df[yield_col].median()
    else:
        median_yield = thresholds["ideal_yield_percent"] / 2  # assume poor yield if missing

    score_yield = min(median_yield / thresholds["ideal_yield_percent"], 1)

    # ---------------------------
    # Combine all
    # ---------------------------
    final_score = (
        score_level_dev * weights["level_deviation"] +
        score_storage * weights["storage_trend"] +
        score_recharge * weights["recharge_efficiency"] +
        score_extraction * weights["extraction_pressure"] +
        score_threshold * weights["threshold_penalty"] +
        score_yield * weights["yield_factor"]
    )

    return {
        "baseline": baseline,
        "latest": latest,
        "score_level_dev": round(score_level_dev, 3),
        "score_storage": round(score_storage, 3),
        "score_recharge": round(score_recharge, 3),
        "score_extraction": round(score_extraction, 3),
        "score_threshold": round(score_threshold, 3),
        "score_yield": round(score_yield, 3),
        "final_score_pct": round(final_score * 100, 2)
    }


# ---------------------------
# Example usage
# ---------------------------
if __name__ == "__main__":
    # Example mock data
    dates = pd.date_range("2025-01-01", periods=60, freq="D")
    df = pd.DataFrame({
        "datetime": dates,
        "mean_level": np.linspace(-40, -48, 60),  # water level dropping
        "rainfall_mm": np.random.choice([0, 5, 10, 20], size=60),
        "yield_percent": np.random.uniform(10, 35, size=60)
    })

    result = compute_sustainability_score(df)
    print(result)
