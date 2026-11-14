# coppock_2025/run_all.R
# Runs the reproduction in order: fetch and verify the deposit, recompute Figure 1, record the
# archive, build the ground truth, run the gate, and print the in-text claims.

library(here)
here::i_am("run_all.R")

source(here::here("download_original.R"))
# Figure 1 needs the private 2014 survey, which download_original.R flags as unavailable on CI.
if (survey_2014_available) {
  source(here::here("maintained", "figure_1_panels.R"))
} else {
  print("Skipped maintained/figure_1_panels.R: the private 2014 survey is not available on CI.")
}

# Archive record ----
# The deposit's Stata files are not run here; this writes the two archive tables that say so.
source(here::here("ground_truth", "run_archive.R"), local = new.env())

# Ground truth ----
# The build ends by running ground_truth/claims_gate.R, which sources in_text_claims.R and
# halts if a published quantity has lost its block or the two instruments disagree.
source(here::here("ground_truth", "build_ground_truth.R"))

# In-text claims, printed for a reader ----
source(here::here("maintained", "in_text_claims.R"), local = new.env())

# Deposited files, again ----
# Nothing above writes to original/, and this second pass shows it.
source(here::here("download_original.R"))
