# coppock_2025/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original_manifest.csv
# Description: The archive record. The review deposits no code of its own, and the deposit
#   this repo reads is the book's: seven Stata files and four surveys. Stata is not available
#   here, so no script is run in either pass, and each gets a not_run row saying why. Every
#   script fits or plots the book's models, so each is an analysis script. The deposit ships
#   no intermediate file, so the copy stripped to data plus code is the copy as shipped, and
#   nothing is added, overwritten, rebuilt, withheld, or deleted.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

scripts <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE) |>
  filter(str_ends(file, "\\.do")) |>
  pull(file)

stopifnot(length(scripts) == 7)

archive_run_status <- expand_grid(pass = c("as_shipped", "stripped"), script = scripts) |>
  mutate(
    role = "analysis",
    exit_status = NA_integer_,
    outcome = "not_run",
    stopped_at = "Not run: Stata is not available here, and the maintained code is a rewrite in R from the deposited .dta files"
  )

archive_overwrites <- tibble(pass = character(), file = character(), effect = character(),
                             matches_deposit = logical())

write_csv(archive_run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(archive_overwrites, here::here("ground_truth", "archive_overwrites.csv"))
