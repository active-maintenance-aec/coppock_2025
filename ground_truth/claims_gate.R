# coppock_2025/ground_truth/claims_gate.R
# Output: printed gate summary; halts the run on any coverage or agreement failure
# Depends on: ground_truth/published_claims.csv, ground_truth/coppock_2025_ground_truth.csv,
#   maintained/in_text_claims.R, maintained/output/
# Description: The coverage gate. It runs maintained/in_text_claims.R as a program rather
#   than reading it as text, because a block that errors at runtime, or that ends in a bare
#   expression and so prints nothing, satisfies any check that merely looks for its claim id
#   in the file. It then asserts that the number of printed claims equals the number of
#   extraction rows requiring one, that the two id sets are equal in both directions, and
#   that every printed value agrees with the ground truth's value_rewrite at the precision
#   the published page uses.

library(here)
library(tidyverse)

here::i_am("ground_truth/claims_gate.R")

claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(.default = col_character(), value_paper = col_character(),
                   needs_block = col_logical(), digits = col_integer())
)

ground_truth <- read_csv(
  here::here("ground_truth", "coppock_2025_ground_truth.csv"),
  col_types = cols(.default = col_character(), value_paper = col_character(),
                   value_script = col_double(), value_rewrite = col_double(),
                   match = col_double(), match_rewrite = col_double(), holds = col_double())
)

# The float rows of the extraction were written from figure_1_plotted.csv, and each read of the
# ground truth passes through the extraction, so these two comparisons should never fail. They
# are what makes that guarantee checkable.
paper_check <- inner_join(
  claims |> select(claim_id, extraction = value_paper),
  ground_truth |> select(claim_id, ground_truth = value_paper),
  by = "claim_id"
)
stopifnot(nrow(paper_check) == nrow(claims),
          all(paper_check$extraction == paper_check$ground_truth))

positions <- read_csv(here::here("ground_truth", "figure_1_plotted.csv"), show_col_types = FALSE) |>
  pivot_longer(c(estimate, conf_low, conf_high), values_to = "position") |>
  arrange(position) |>
  pull(position)
extracted <- claims |>
  filter(str_detect(claim_id, "^f1_")) |>
  mutate(value = as.numeric(value_paper)) |>
  arrange(value) |>
  pull(value)
stopifnot(length(positions) == length(extracted), all(positions == extracted))

# A claim id in the errata spine has to name a row of the extraction. In-spine ids are the join
# the corpus left unchecked elsewhere, so here it is checked.
errata_file <- here::here("errata_entries.csv")
if (file.exists(errata_file)) {
  errata_ids <- read_csv(errata_file, show_col_types = FALSE) |>
    pull(claim_ids) |>
    discard(is.na) |>
    str_split(";") |>
    unlist()
  stopifnot(all(errata_ids %in% claims$claim_id))
}

# Source into its own environment. The two files necessarily read the same output files
# and name objects for what they hold, so a bare source() would replace this script's
# claims, out() and friends with the claims file's, and the gate would then run against
# the wrong objects.
claims_log <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env())
)

printed <- str_match(claims_log, "^CLAIM (\\S+) = (\\S+) \\|\\| (.*)$")
printed <- tibble(claim_id = printed[, 2], printed_value = printed[, 3],
                  label = printed[, 4]) |>
  filter(!is.na(claim_id))

declared <- claims$claim_id[claims$needs_block]

stopifnot(
  !any(duplicated(printed$claim_id)),
  nrow(printed) == length(declared),
  length(setdiff(declared, printed$claim_id)) == 0,
  length(setdiff(printed$claim_id, declared)) == 0
)

# The two instruments, value by value. build_ground_truth.R reshapes each output file
# into a long table keyed by claim id; in_text_claims.R selects the same numbers cell by
# cell. Where the two disagree, one of them is wrong.
cross_check <- printed |>
  inner_join(claims |> select(claim_id, digits), by = "claim_id") |>
  inner_join(ground_truth |> select(claim_id, value_rewrite), by = "claim_id") |>
  mutate(
    gt_printed = if_else(is.na(value_rewrite), "NA",
                         sprintf(paste0("%.", digits, "f"), value_rewrite)),
    agrees = printed_value == gt_printed
  )

if (any(!cross_check$agrees)) print(filter(cross_check, !agrees), n = Inf, width = 200)
stopifnot(nrow(cross_check) == nrow(printed), all(cross_check$agrees))

print(tibble(
  check = c("extraction rows", "extraction rows requiring a block",
            "claims printed by in_text_claims.R",
            "claims compared across the two instruments",
            "value_paper entries reconciled with the extraction"),
  value = c(nrow(claims), length(declared), nrow(printed), nrow(cross_check),
            nrow(paper_check))
))
