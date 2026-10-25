# ==============================================================================
# Script 01: Default Age-Earnings Scatterplot (Question 4 baseline)
# Course: ECO346 - Data Visualization Techniques for Economists
# Student: Rabia Tahir (FA24-BED-093) <rabii.okiee@gmail.com> | Variant 5 (KP Urban: prov_code == 1, urban_rural == 2)
# ==============================================================================

library(readr)
library(dplyr)
library(ggplot2)
library(svglite)

# 1. Load local data copies
hh <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)
person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)

# 2. Merge household variables: hhweight, prov_code, urban_rural
# Sample definition: Variant 5 (KP Urban), earners aged 15-64 with earn_annual > 0
earners <- person %>%
  left_join(hh %>% select(hhid, hhweight, prov_code, urban_rural), by = "hhid") %>%
  filter(prov_code == 1, urban_rural == 2, age >= 15, age <= 64, earn_annual > 0)

# 3. R default plot: untouched defaults as specified in Question 4
p_default <- ggplot(earners, aes(x = age, y = earn_annual)) +
  geom_point()

# 4. Save figure as SVG
dir.create("figures", showWarnings = FALSE)
ggsave("figures/default.svg", plot = p_default, width = 7, height = 4.5, device = "svg")

cat("Saved figures/default.svg successfully.\n")
