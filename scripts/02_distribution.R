# ==============================================================================
# Script 02: Distribution of Annual Earnings (Question 2)
# Course: ECO346 - Data Visualization Techniques for Economists
# Student: Rabia Tahir (FA24-BED-093) <rabii.okiee@gmail.com> | Variant 5 (KP Urban: prov_code == 1, urban_rural == 2)
# ==============================================================================

library(readr)
library(dplyr)
library(ggplot2)
library(svglite)

# 1. Load data
hh <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)
person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)

# 2. Merge and define sample
# Variant 5: Khyber Pakhtunkhwa Urban (prov_code == 1, urban_rural == 2)
# Earners: aged 15-64 with earn_annual > 0
earners <- person %>%
  left_join(hh %>% select(hhid, hhweight, prov_code, urban_rural), by = "hhid") %>%
  filter(prov_code == 1, urban_rural == 2, age >= 15, age <= 64, earn_annual > 0)

n_total_earners <- nrow(earners)

# 3. Exclude earners outside [10,000, 10,000,000]
earners_in_range <- earners %>%
  filter(earn_annual >= 10000 & earn_annual <= 10000000)

n_excluded <- n_total_earners - nrow(earners_in_range)

# 4. Compute weighted quantiles according to exact specification:
# "sort the observations by x, compute the cumulative share of weight, 
#  and take the smallest x at which that share reaches or exceeds p."
weighted_quantile <- function(x, w, p) {
  ord <- order(x)
  x_sorted <- x[ord]
  w_sorted <- w[ord]
  cum_share <- cumsum(w_sorted) / sum(w_sorted)
  x_sorted[which(cum_share >= p)[1]]
}

unw_median <- median(earners$earn_annual)
w_median   <- weighted_quantile(earners$earn_annual, earners$hhweight, 0.50)
w_p10      <- weighted_quantile(earners$earn_annual, earners$hhweight, 0.10)
w_p90      <- weighted_quantile(earners$earn_annual, earners$hhweight, 0.90)
p90_p10_ratio <- w_p90 / w_p10

cat("--- Question 2 Reported Statistics ---\n")
cat(sprintf("Number of earners: %d\n", n_total_earners))
cat(sprintf("Unweighted median: Rs %s\n", format(unw_median, big.mark = ",")))
cat(sprintf("Weighted median: Rs %s\n", format(w_median, big.mark = ",")))
cat(sprintf("Weighted 10th percentile: Rs %s\n", format(w_p10, big.mark = ",")))
cat(sprintf("Weighted 90th percentile: Rs %s\n", format(w_p90, big.mark = ",")))
cat(sprintf("90th to 10th percentile ratio: %.2f\n", p90_p10_ratio))
cat(sprintf("Number excluded (< Rs 10,000 or > Rs 10,000,000): %d\n", n_excluded))
cat("---------------------------------------\n")

# 5. Load course theme if available
if (file.exists("style/theme_dvte.R")) {
  source("style/theme_dvte.R")
  theme_set(theme_dvte)
} else {
  theme_set(theme_gray(base_size = 9))
}

# 6. Plot weighted histogram on log scale
p_dist <- ggplot(earners_in_range, aes(x = earn_annual, weight = hhweight)) +
  geom_histogram(
    aes(y = after_stat(density)),
    binwidth = 0.1,
    boundary = 4.0,
    fill = "#3b6998",
    color = "white",
    linewidth = 0.3
  ) +
  scale_x_log10(
    limits = c(10000, 10000000),
    breaks = c(10000, 100000, 1000000, 10000000),
    labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")
  ) +
  scale_y_continuous(
    limits = c(0, 1.9),
    breaks = seq(0, 1.8, by = 0.3),
    expand = expansion(mult = c(0, 0.05))
  ) +
  # Dashed line for weighted median
  geom_vline(xintercept = w_median, linetype = "dashed", color = "#c0392b", linewidth = 0.85) +
  # Dashed line for weighted 90th percentile
  geom_vline(xintercept = w_p90, linetype = "dashed", color = "#16a085", linewidth = 0.85) +
  # Direct text annotations
  annotate("text", x = w_median * 0.78, y = 1.72, 
           label = paste0("Weighted Median\nRs ", format(w_median, big.mark = ",")),
           color = "#96281b", size = 3.2, fontface = "bold", hjust = 0.5) +
  annotate("text", x = w_p90 * 1.35, y = 1.72, 
           label = paste0("90th Percentile\nRs ", format(w_p90, big.mark = ",")),
           color = "#0e6655", size = 3.2, fontface = "bold", hjust = 0.5) +
  labs(
    title = "Annual Earnings in Urban KP Peak Near Rs 240,000 with Substantial Upper-Decile Inequality",
    subtitle = "Weighted distribution of annual earnings for employed individuals aged 15–64 (bins: 0.1 log10 units)",
    x = "Annual Earnings in Rupees (logarithmic scale)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019–20 person and household files. Sample: Working earners aged 15–64 in KP Urban (prov_code=1, urban_rural=2).\n",
      "Weighted by household weight (hhweight). Exactly ", n_excluded, 
      " earner earning below Rs 10,000 (Rs 5,000) is excluded from the plot."
    )
  )

# 7. Save figure as SVG
ggsave("figures/distribution.svg", plot = p_dist, width = 7.5, height = 4.8, device = "svg")
cat("Saved figures/distribution.svg successfully.\n")
