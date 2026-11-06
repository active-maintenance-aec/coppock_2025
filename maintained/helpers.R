# coppock_2025/maintained/helpers.R
# Output: none (sourced)
# Depends on: nothing
# Description: Shared setup, the survey reader, and the estimator every Figure 1 panel uses.

library(here)
library(haven)
library(tidyverse)
library(estimatr)

here::i_am("maintained/helpers.R")

read_survey <- function(file) read_dta(here::here("original", file))

write_output <- function(x, file) {
  write_csv(x, here::here("maintained", "output", file))
  invisible(x)
}

# The article's groups: 1 to 3 on the seven-point scale are Democrats, 5 to 7 Republicans.
# Pure independents (4) and "not sure" (8) belong to neither.
party_of <- function(pid7) {
  case_when(pid7 %in% 1:3 ~ "Democrat", pid7 %in% 5:7 ~ "Republican")
}

# Difference in means of arm against the reference arm, within each party.
cate <- function(data, arm, reference, ..., weights = NULL) {
  data |>
    filter(!is.na(party), .data$condition %in% c(reference, arm)) |>
    mutate(z = as.numeric(condition == arm)) |>
    group_by(party) |>
    group_modify(\(d, key) {
      fit <- if (is.null(weights)) lm_robust(y ~ z, data = d)
             else lm_robust(y ~ z, data = d, weights = d[[weights]])
      tidy(fit) |>
        filter(term == "z") |>
        transmute(estimate, conf_low = conf.low, conf_high = conf.high, n = nobs(fit))
    }) |>
    ungroup()
}
