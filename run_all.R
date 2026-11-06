# coppock_2025/run_all.R
# Runs the reproduction in order: fetch and verify the deposit, then recompute Figure 1.

library(here)
here::i_am("run_all.R")

source(here::here("download_original.R"))
source(here::here("maintained", "figure_1_panels.R"))
