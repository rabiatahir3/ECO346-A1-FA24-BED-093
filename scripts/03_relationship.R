# ==============================================================================
# Script 03: Age-Earnings Relationship Redesign (Question 3)
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
earners <- person %>%
  left_join(hh %>% select(hhid, hhweight, prov_code, urban_rural), by = "hhid") %>%
  filter(prov_code == 1, urban_rural == 2, age >= 15, age <= 64, earn_annual > 0)

# Filter for plot display range [10,000 to 10,000,000]
earners_plot <- earners %>%
  filter(earn_annual >= 10000 & earn_annual <= 10000000)

# 3. Create five-year age bands and calculate weighted means
# Bands: 15-19, 20-24, ..., 60-64 (ten bands)
# Midpoints: 17, 22, ..., 62
earners <- earners %>%
  mutate(
    band = cut(
      age,
      breaks = seq(14.5, 64.5, by = 5),
      labels = c("15-19", "20-24", "25-29", "30-34", "35-39",
                 "40-44", "45-49", "50-54", "55-59", "60-64")
    ),
    midpoint = as.numeric(as.character(cut(
      age,
      breaks = seq(14.5, 64.5, by = 5),
      labels = seq(17, 62, by = 5)
    )))
  )

band_table <- earners %>%
  group_by(band, midpoint) %>%
  summarize(
    n_earners = n(),
    weighted_mean = round(sum(earn_annual * hhweight) / sum(hhweight)),
    thin = n_earners < 30,
    .groups = "drop"
  )

cat("--- Question 3 Band Table ---\n")
print(as.data.frame(band_table))
cat("-----------------------------\n")

mean_25_29 <- band_table %>% filter(band == "25-29") %>% pull(weighted_mean)
mean_45_49 <- band_table %>% filter(band == "45-49") %>% pull(weighted_mean)
peak_row   <- band_table %>% filter(weighted_mean == max(weighted_mean))

cat(sprintf("Weighted mean earnings of band 25-29: Rs %s\n", format(mean_25_29, big.mark = ",")))
cat(sprintf("Weighted mean earnings of band 45-49: Rs %s\n", format(mean_45_49, big.mark = ",")))
cat(sprintf("Highest weighted mean band: %s (Rs %s at midpoint %d)\n", 
            peak_row$band, format(peak_row$weighted_mean, big.mark = ","), peak_row$midpoint))

# 4. Load course theme if available
if (file.exists("style/theme_dvte.R")) {
  source("style/theme_dvte.R")
  theme_set(theme_dvte)
} else {
  theme_set(theme_gray(base_size = 9))
}

# 5. Plot relationship
set.seed(346) # for reproducible jittering
p_rel <- ggplot() +
  # Individual earners: jittered horizontally (width = 0.35 <= 0.4), alpha = 0.35
  geom_jitter(
    data = earners_plot,
    aes(x = age, y = earn_annual),
    width = 0.35,
    height = 0,
    alpha = 0.35,
    color = "#4a6572",
    size = 1.3
  ) +
  # Weighted conditional mean line
  geom_line(
    data = band_table,
    aes(x = midpoint, y = weighted_mean),
    color = "#d9534f",
    linewidth = 1.1
  ) +
  # Solid markers for regular bands (n >= 30)
  geom_point(
    data = band_table %>% filter(!thin),
    aes(x = midpoint, y = weighted_mean),
    shape = 21,
    fill = "#d9534f",
    color = "#2c3e50",
    size = 3.8,
    stroke = 1.0
  ) +
  # Hollow markers for thin bands (n < 30)
  geom_point(
    data = band_table %>% filter(thin),
    aes(x = midpoint, y = weighted_mean),
    shape = 21,
    fill = "white",
    color = "#d9534f",
    size = 3.8,
    stroke = 1.6
  ) +
  # Direct annotation of the highest weighted mean band
  annotate(
    "segment",
    x = peak_row$midpoint - 3,
    y = peak_row$weighted_mean * 1.55,
    xend = peak_row$midpoint - 0.5,
    yend = peak_row$weighted_mean * 1.08,
    arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
    color = "#c0392b",
    linewidth = 0.75
  ) +
  annotate(
    "text",
    x = peak_row$midpoint - 3.2,
    y = peak_row$weighted_mean * 1.65,
    label = paste0("Highest Mean: Band ", peak_row$band, "\nRs ", format(peak_row$weighted_mean, big.mark = ",")),
    color = "#96281b",
    fontface = "bold",
    size = 3.2,
    hjust = 1
  ) +
  # Scales
  scale_y_log10(
    limits = c(10000, 10000000),
    breaks = c(10000, 100000, 1000000, 10000000),
    labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")
  ) +
  scale_x_continuous(
    limits = c(14, 65),
    breaks = seq(15, 65, by = 5)
  ) +
  labs(
    title = "Annual Earnings in Urban KP Rise Across Career Lifecycle, Peaking at Ages 55–59",
    subtitle = "Semi-transparent individual earners with weighted 5-year age band conditional means",
    x = "Age in Years (15–64)",
    y = "Annual Earnings in Rupees (logarithmic scale)",
    caption = paste0(
      "Source: PSLM 2019–20. Sample: Earners aged 15–64 in KP Urban (N = 678). Weighted by hhweight.\n",
      "Hollow marker indicates thin band with fewer than 30 unweighted observations (band 60–64, N = 15).\n",
      "Individual observations jittered horizontally by ±0.35 years (alpha = 0.35) to mitigate overplotting."
    )
  )

# 6. Save figure as SVG
ggsave("figures/relationship.svg", plot = p_rel, width = 7.5, height = 4.8, device = "svg")
cat("Saved figures/relationship.svg successfully.\n")
