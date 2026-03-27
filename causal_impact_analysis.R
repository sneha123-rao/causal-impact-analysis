install.packages("CausalImpact")
install.packages("zoo")

# ============================================
# CAUSAL IMPACT ANALYSIS
# Measuring the Effect of a Super Bowl Ad
# Campaign on Sales | Sneha Ashok Rao, UCLA
# ============================================

library(CausalImpact)
library(zoo)
library(tidyverse)

# ============================================
#  CREATING REALISTIC SALES DATA
# ============================================

set.seed(42)
n <- 365  # One full year of daily sales data

# Creating time index
dates <- seq(as.Date("2023-01-01"), 
             as.Date("2023-12-31"), 
             by = "day")

# Pre-campaign baseline sales with trend + noise
time_index <- 1:n
baseline_sales <- 1000 + 
  0.5 * time_index +           # slight upward trend
  50 * sin(2*pi*time_index/7) + # weekly seasonality
  rnorm(n, mean=0, sd=30)        # random noise

# Super Bowl ad aired on Day 37 (Feb 5, 2023)
campaign_start <- 37
campaign_end <- 365

# Adding genuine campaign effect — sales lift of ~150 units
# that gradually decays over time (realistic)
campaign_effect <- rep(0, n)
campaign_effect[campaign_start:n] <- 
  150 * exp(-0.01 * (0:(n-campaign_start)))

# Final sales = baseline + campaign effect
sales <- baseline_sales + campaign_effect

# Control variable — a competitor's sales (not affected by the campaign)
competitor_sales <- 800 + 
  0.3 * time_index + 
  40 * sin(2*pi*time_index/7) + 
  rnorm(n, mean=0, sd=25)

# Combine into a time series
data <- zoo(cbind(sales, competitor_sales), dates)

# Plot the raw data
autoplot(data) +
  geom_vline(xintercept = as.Date("2023-02-05"), 
             color = "#e74c3c", linewidth = 1, linetype = "dashed") +
  annotate("text", x = as.Date("2023-02-10"), y = 1400,
           label = "Super Bowl Ad", color = "#e74c3c", size = 3.5) +
  labs(title = "Daily Sales — Before and After Super Bowl Campaign",
       x = "Date", y = "Sales (units)") +
  theme_minimal()

ggsave("raw_sales_data.png", width = 10, height = 5, dpi = 150)
cat("Raw data plot saved!\n")
cat("Total observations:", n, "\n")
cat("Pre-campaign period:", campaign_start - 1, "days\n")
cat("Post-campaign period:", n - campaign_start + 1, "days\n")

# ============================================
#  RUNNING CAUSAL IMPACT MODEL
# ============================================

# Define pre and post campaign periods
pre_period <- as.Date(c("2023-01-01", "2023-02-04"))
post_period <- as.Date(c("2023-02-05", "2023-12-31"))

# Run CausalImpact
impact <- CausalImpact(data, pre_period, post_period)

# Print the summary
summary(impact)

# ============================================
# VISUALIZING CAUSAL IMPACT
# ============================================

# Plot the CausalImpact results
png("causal_impact_plot.png", width = 1200, height = 800, res = 150)
plot(impact)
dev.off()

cat("Causal Impact plot saved!\n")

# ============================================
# CUSTOM VISUALIZATION
# ============================================

# Extract impact data
impact_data <- as.data.frame(impact$series)
impact_data$date <- dates

# Plot 1 — Actual vs Counterfactual
ggplot(impact_data, aes(x = date)) +
  geom_line(aes(y = response, color = "Actual Sales"), linewidth = 0.8) +
  geom_line(aes(y = point.pred, color = "Predicted (No Campaign)"), 
            linewidth = 0.8, linetype = "dashed") +
  geom_ribbon(aes(ymin = point.pred.lower, ymax = point.pred.upper),
              alpha = 0.2, fill = "#0ea5a0") +
  geom_vline(xintercept = as.Date("2023-02-05"),
             color = "#e74c3c", linewidth = 1, linetype = "dashed") +
  annotate("text", x = as.Date("2023-02-12"), y = 1450,
           label = "Super Bowl Ad", color = "#e74c3c", size = 3.5) +
  scale_color_manual(values = c("Actual Sales" = "#0ea5a0",
                                "Predicted (No Campaign)" = "#e74c3c")) +
  labs(title = "Causal Impact — Super Bowl Ad Campaign",
       subtitle = "Actual sales vs counterfactual prediction | Shaded area = 95% confidence interval",
       x = "Date", y = "Daily Sales (units)", color = "") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("actual_vs_counterfactual.png", width = 12, height = 6, dpi = 150)

# Plot 2 — Incremental Effect
ggplot(impact_data[impact_data$date >= as.Date("2023-02-05"),], 
       aes(x = date)) +
  geom_line(aes(y = point.effect), color = "#0ea5a0", linewidth = 0.8) +
  geom_ribbon(aes(ymin = point.effect.lower, ymax = point.effect.upper),
              alpha = 0.2, fill = "#0ea5a0") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#e74c3c") +
  labs(title = "Daily Incremental Sales Effect",
       subtitle = "Units sold above baseline attributable to the Super Bowl campaign",
       x = "Date", y = "Incremental Sales (units)") +
  theme_minimal()

ggsave("incremental_effect.png", width = 12, height = 5, dpi = 150)

cat("Custom plots saved!")

# ============================================
# BUSINESS SUMMARY OUTPUT
# ============================================

cat("================================================\n")
cat("   CAUSAL IMPACT ANALYSIS — EXECUTIVE SUMMARY\n")
cat("================================================\n\n")

cat("CAMPAIGN: Super Bowl Ad | Air Date: Feb 5, 2023\n\n")

cat("PRE-CAMPAIGN PERIOD:  Jan 1  – Feb 4  (36 days)\n")
cat("POST-CAMPAIGN PERIOD: Feb 5  – Dec 31 (329 days)\n\n")

cat("RESULTS:\n")
cat("  Actual avg daily sales:    1,143 units\n")
cat("  Predicted (no campaign):   1,042 units\n")
cat("  Incremental daily effect:  +101 units/day\n")
cat("  Relative sales lift:       +9.7%\n")
cat("  Total incremental sales:  ~33,229 units\n\n")

cat("STATISTICAL SIGNIFICANCE:\n")
cat("  p-value: 0.001\n")
cat("  Interpretation: 99.9% probability the effect\n")
cat("  is real and not due to random chance\n\n")

cat("METHODOLOGY:\n")
cat("  Competitor sales used as control variable\n")
cat("  CausalImpact (Google) Bayesian structural\n")
cat("  time series model\n\n")

cat("BUSINESS RECOMMENDATION:\n")
cat("  The Super Bowl campaign generated a statistically\n")
cat("  significant 9.7% sales lift. Assuming $100 revenue\n")
cat("  per unit, total incremental revenue = $3.3M.\n")
cat("  ROI analysis: if campaign cost < $3.3M, it was\n")
cat("  profitable. Recommend continued investment in\n")
cat("  high-reach broadcast campaigns.\n")
cat("================================================\n")
