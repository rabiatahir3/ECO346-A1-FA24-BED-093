# ==============================================================================
# Script 04: Age-Earnings Relationship Replication in Python (Question 5)
# Course: ECO346 - Data Visualization Techniques for Economists
# Student: Rabia Tahir (FA24-BED-093) <rabii.okiee@gmail.com> | Variant 5 (KP Urban: prov_code == 1, urban_rural == 2)
# ==============================================================================

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# 1. Load data
hh = pd.read_csv("data/pslm_hh_subset.csv")
person = pd.read_csv("data/pslm_person_subset.csv")

# 2. Merge and define sample
merged = person.merge(
    hh[["hhid", "hhweight", "prov_code", "urban_rural"]],
    on="hhid",
    how="left"
)

earners = merged[
    (merged["prov_code"] == 1) &
    (merged["urban_rural"] == 2) &
    (merged["age"] >= 15) &
    (merged["age"] <= 64) &
    (merged["earn_annual"] > 0)
].copy()

# Filter for plotting range [10,000 to 10,000,000]
earners_plot = earners[
    (earners["earn_annual"] >= 10000) & (earners["earn_annual"] <= 10000000)
].copy()

# 3. Compute 5-year age band table
bands = [
    (15, 19, 17),
    (20, 24, 22),
    (25, 29, 27),
    (30, 34, 32),
    (35, 39, 37),
    (40, 44, 42),
    (45, 49, 47),
    (50, 54, 52),
    (55, 59, 57),
    (60, 64, 62)
]

band_records = []
for low, high, mid in bands:
    sub = earners[(earners["age"] >= low) & (earners["age"] <= high)]
    n_obs = len(sub)
    w_sum = sub["hhweight"].sum()
    w_mean = round((sub["earn_annual"] * sub["hhweight"]).sum() / w_sum) if n_obs > 0 else np.nan
    is_thin = n_obs < 30
    band_records.append({
        "band": f"{low}-{high}",
        "midpoint": mid,
        "n_earners": n_obs,
        "weighted_mean": int(w_mean),
        "thin": is_thin
    })

band_df = pd.DataFrame(band_records)

cat_header = "--- Question 5 Band Table (Python Replication) ---"
print(cat_header)
print(band_df.to_string(index=False))
print("-" * len(cat_header))

mean_25_29_py = band_df.loc[band_df["band"] == "25-29", "weighted_mean"].values[0]
print(f"Python 25-29 band mean: Rs {mean_25_29_py:,}")

peak_row = band_df.loc[band_df["weighted_mean"].idxmax()]
print(f"Peak weighted mean band: {peak_row['band']} (Rs {peak_row['weighted_mean']:,} at midpoint {peak_row['midpoint']})")

# 4. Configure plot style
if os.path.exists("style/dvte.mplstyle"):
    plt.style.use("style/dvte.mplstyle")
else:
    plt.style.use("seaborn-v0_8-whitegrid" if "seaborn-v0_8-whitegrid" in plt.style.available else "default")

fig, ax = plt.subplots(figsize=(7.5, 4.8))

# 5. Jitter individual earner points horizontally (seed for reproducibility)
np.random.seed(346)
jitter = np.random.uniform(-0.35, 0.35, size=len(earners_plot))
ax.scatter(
    earners_plot["age"] + jitter,
    earners_plot["earn_annual"],
    color="#4a6572",
    alpha=0.35,
    s=18,
    edgecolors="none",
    zorder=2,
    label="Individual earners"
)

# 6. Plot conditional mean line
ax.plot(
    band_df["midpoint"],
    band_df["weighted_mean"],
    color="#d9534f",
    linewidth=2.2,
    zorder=3,
    label="Weighted conditional mean"
)

# 7. Plot markers: solid for normal bands, hollow for thin bands
regular_bands = band_df[~band_df["thin"]]
thin_bands = band_df[band_df["thin"]]

ax.scatter(
    regular_bands["midpoint"],
    regular_bands["weighted_mean"],
    facecolor="#d9534f",
    edgecolor="#2c3e50",
    s=70,
    linewidth=1.2,
    zorder=4
)

ax.scatter(
    thin_bands["midpoint"],
    thin_bands["weighted_mean"],
    facecolor="white",
    edgecolor="#d9534f",
    s=70,
    linewidth=2.0,
    zorder=4,
    label="Thin band (< 30 obs)"
)

# 8. Direct annotation of peak band
ax.annotate(
    f"Highest Mean: Band {peak_row['band']}\nRs {peak_row['weighted_mean']:,}",
    xy=(peak_row["midpoint"], peak_row["weighted_mean"]),
    xytext=(peak_row["midpoint"] - 8, peak_row["weighted_mean"] * 1.55),
    arrowprops=dict(facecolor="#c0392b", edgecolor="#c0392b", arrowstyle="->", lw=1.5),
    fontsize=9,
    fontweight="bold",
    color="#96281b"
)

# 9. Axes formatting and scales
ax.set_yscale("log")
ax.set_ylim(10000, 10000000)
ax.set_xlim(14, 65)
ax.set_xticks(np.arange(15, 66, 5))

# Rupee tick labels
formatter = ticker.FuncFormatter(lambda y, _: f"Rs {int(y):,}")
ax.yaxis.set_major_formatter(formatter)
ax.set_yticks([10000, 100000, 1000000, 10000000])

ax.set_xlabel("Age in Years (15–64)", fontsize=10, labelpad=8)
ax.set_ylabel("Annual Earnings in Rupees (logarithmic scale)", fontsize=10, labelpad=8)
ax.set_title(
    "Annual Earnings in Urban KP Rise Across Career Lifecycle, Peaking at Ages 55–59\n[Python / Matplotlib Replication]",
    fontsize=11,
    fontweight="bold",
    pad=12
)

# Caption
caption_text = (
    "Source: PSLM 2019–20. Sample: Earners aged 15–64 in KP Urban (N = 678). Weighted by hhweight.\n"
    "Hollow marker indicates thin band with fewer than 30 unweighted observations (band 60–64, N = 15).\n"
    "Individual observations jittered horizontally by ±0.35 years (alpha = 0.35) to mitigate overplotting."
)
plt.figtext(0.12, -0.04, caption_text, wrap=True, horizontalalignment="left", fontsize=7.5, color="#555555")

# 10. Save figure as SVG
os.makedirs("figures", exist_ok=True)
plt.savefig("figures/relationship_python.svg", format="svg", bbox_inches="tight")
print("Saved figures/relationship_python.svg successfully.")
