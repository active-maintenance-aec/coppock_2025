# coppock_2025/ground_truth/build_ground_truth.R
# Output: ground_truth/coppock_2025_ground_truth.csv
# Depends on: ground_truth/published_claims.csv, ground_truth/figure_1_plotted.csv,
#   maintained/output/, ground_truth/claims_gate.R
# Description: Assemble the ground truth from the extraction and the pipeline's output, then
#   run the coverage gate. The review deposits no code, and the book's Stata files were not
#   run, so value_script and match are NA on every row. A Figure 1 value matches when the
#   recomputation lies within the tolerance of the position read from the PDF's marks.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

plotted_tolerance <- 0.0005

claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(.default = col_character(), needs_block = col_logical(),
                                    digits = col_integer()))
output <- \(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)
estimates <- output("figure_1_estimates.csv")
specifications <- output("figure_1b_specifications.csv")
study_4 <- output("figure_1d_slopes.csv")

# Figure 1's cells ----
plotted <- read_csv(here::here("ground_truth", "figure_1_plotted.csv"), show_col_types = FALSE) |>
  mutate(party = str_to_title(str_remove(printed_group, "printed_"))) |>
  pivot_longer(c(estimate, conf_low, conf_high), names_to = "statistic", values_to = "position")

recomputed <- estimates |>
  pivot_longer(c(estimate, conf_low, conf_high), names_to = "statistic", values_to = "value_rewrite")

figure_rows <- plotted |>
  left_join(recomputed, by = c("panel", "facet", "item", "party", "statistic")) |>
  mutate(
    claim_id = str_c("f1", panel, str_replace_all(str_to_lower(facet), "[^a-z0-9]+", "_") |> str_remove("_$"),
                     item, str_to_lower(party),
                     recode(statistic, estimate = "est", conf_low = "low", conf_high = "high"), sep = "_"),
    claim = str_glue("Figure 1({panel}), {facet}, {item}, printed {party}, {statistic}"),
    match_rewrite = as.numeric(abs(position - value_rewrite) <= plotted_tolerance),
    holds = NA_real_
  ) |>
  select(claim_id, claim, value_rewrite, match_rewrite, holds)

stopifnot(nrow(figure_rows) == 114, !anyNA(figure_rows$value_rewrite))

# Descriptive claims, computed across the cells rather than cell by cell ----
expected_sign <- \(facet, party) if_else(str_sub(facet, 1, 3) == str_sub(party, 1, 3), 1, -1)

signs <- estimates |>
  filter(panel %in% c("a", "e")) |>
  mutate(as_expected = sign(estimate) == expected_sign(facet, party))

closer_to_zero <- estimates |>
  filter(panel == "a") |>
  group_by(facet, party) |>
  summarise(closer = abs(estimate[item == "two_thirds"]) > max(abs(estimate[item != "two_thirds"])),
            .groups = "drop")

means <- study_4 |>
  filter(quantity == "cue_mean") |>
  select(party, group, estimate) |>
  pivot_wider(names_from = group, values_from = estimate)

slopes <- study_4 |> filter(quantity == "cost_slope")

study_2_signs <- specifications |>
  group_by(party) |>
  summarise(all_negative = all(estimate < 0), all_positive = all(estimate > 0))
own_majority <- deframe(select(study_2_signs, party, all_negative))
other_majority <- deframe(select(study_2_signs, party, all_positive))

out_party_foods <- estimates |>
  filter(panel == "c", item %in% c("chili", "meatloaf"),
         (party == "Democrat" & facet == "Trump") | (party == "Republican" & facet == "Obama"))

descriptive_rows <- tribble(
  ~claim_id, ~holds,
  "s1_two_thirds_pattern", all(signs$as_expected[signs$item == "two_thirds"]),
  "s1_other_issues_closer", all(closer_to_zero$closer),
  "s2_republicans_more_conservative", own_majority[["Republican"]],
  "s2_democrats_less_liberal", other_majority[["Democrat"]],
  "s2_both_more_moderate_republican_majority", own_majority[["Democrat"]] && other_majority[["Republican"]],
  "s3_out_party_dislike", all(out_party_foods$estimate < 0),
  "s4_cue_direction",
  means$`Biden Treatment`[means$party == "Democrat"] > means$Control[means$party == "Democrat"] &&
    means$Control[means$party == "Democrat"] > means$`Trump Treatment`[means$party == "Democrat"] &&
    means$`Biden Treatment`[means$party == "Republican"] < means$Control[means$party == "Republican"] &&
    means$Control[means$party == "Republican"] < means$`Trump Treatment`[means$party == "Republican"],
  "s4_cost_direction",
  slopes$conf_high[slopes$party == "Democrat"] < 0 &&
    abs(slopes$estimate[slopes$party == "Republican"]) < abs(slopes$estimate[slopes$party == "Democrat"]),
  "s5_cue_direction", all(signs$as_expected[signs$panel == "e"])
) |>
  mutate(holds = as.numeric(holds), value_rewrite = holds, match_rewrite = NA_real_,
         claim = str_c("Descriptive: ", claim_id))

# The abstract's summary states no scope, so it gets a share and no verdict. The claim that the
# reanalyses match the authors' estimates is not tested here, because nothing in this repo
# holds the book's printed estimates.
unscored_rows <- tibble(
  claim_id = c("abstract_cue_pattern", "intro_same_estimates"),
  value_rewrite = c(mean(signs$as_expected), NA_real_),
  holds = NA_real_, match_rewrite = NA_real_,
  claim = c("Abstract: share of Figure 1(a) and (e) cells with the in-party and out-party signs",
            "Introduction: the reanalyses arrive at the authors' estimates")
)

# Assembly, with the locus rule ----
source_notes <- c(
  s1_two_thirds_pattern = "All four signs hold. The Republican cue's interval for Republicans covers zero, which sits uneasily with 'clear evidence' and is not a wrong sign.",
  s2_both_more_moderate_republican_majority = "False on the 2018 survey and supported by Figure 1(b)'s marks; see errata entry 1 and review queue row 8.",
  s2_republicans_more_conservative = "Sign holds, weighted and unweighted; the intervals cover zero. Figure 1(b)'s printed Republican mark has the opposite sign.",
  s2_democrats_less_liberal = "Sign holds, weighted and unweighted; the intervals cover zero. Figure 1(b)'s printed Democrat mark has the opposite sign.",
  abstract_cue_pattern = "A summary with no stated scope, so the share is reported without a verdict.",
  intro_same_estimates = "Not tested: this repo holds no copy of the book's printed estimates.",
  book_quote_page = "The book is not in this repo; unchecked.",
  footnote_1_book_year = "The book is not in this repo; unchecked.",
  footnote_3_volume = "Crossref, doi 10.1038/s41562-023-01551-7, 2026-11-05.",
  footnote_3_issue = "Crossref, doi 10.1038/s41562-023-01551-7, 2026-11-05.",
  footnote_3_first_page = "Crossref, doi 10.1038/s41562-023-01551-7, 2026-11-05.",
  footnote_3_last_page = "Crossref, doi 10.1038/s41562-023-01551-7, 2026-11-05.",
  footnote_3_year = "Crossref, doi 10.1038/s41562-023-01551-7, 2026-11-05.",
  s2_seat_shares_60 = "maintained/figure_1_panels.R asserts the survey's 40% label; 60 is its complement.",
  s2_seat_shares_40 = "maintained/figure_1_panels.R asserts the survey's 40% label."
)

gt <- bind_rows(figure_rows, descriptive_rows, unscored_rows)

ground_truth <- claims |>
  left_join(gt, by = "claim_id") |>
  mutate(
    paper_id = "coppock_2025",
    table_figure = location,
    claim = coalesce(claim, str_c(location, ": ", claim_id)),
    value_script = NA_real_,
    match = NA_real_,
    defect_locus = case_when(
      str_detect(claim_id, "^f1_b_") ~ "unresolved",
      (!is.na(match_rewrite) & match_rewrite == 0) | (!is.na(holds) & holds == 0) ~ "unresolved",
      .default = NA_character_
    ),
    notes = case_when(
      claim_id %in% names(source_notes) ~ source_notes[claim_id],
      str_detect(claim_id, "^f1_b_") ~ "Panel b reproduces under no specification tried; see errata entry 1 and figure_1b_specifications.csv.",
      !needs_block ~ "No counterpart in the pipeline.",
      .default = NA_character_
    )
  ) |>
  select(paper_id, claim_id, table_figure, claim, claim_type, value_script, value_paper, match,
         value_rewrite, match_rewrite, holds, defect_locus, notes)

adverse <- (!is.na(ground_truth$match_rewrite) & ground_truth$match_rewrite == 0) |
  (!is.na(ground_truth$holds) & ground_truth$holds == 0)
clean <- !is.na(ground_truth$match_rewrite) & ground_truth$match_rewrite == 1
stopifnot(all(!is.na(ground_truth$defect_locus[adverse])),
          all(is.na(ground_truth$defect_locus[clean])))

# Every cell outside panel b has to match, or the inferred specification no longer holds.
stopifnot(all(ground_truth$match_rewrite[str_detect(ground_truth$claim_id, "^f1_(a|c|e)_")] == 1))

write_csv(ground_truth, here::here("ground_truth", "coppock_2025_ground_truth.csv"), na = "NA")

source(here::here("ground_truth", "claims_gate.R"), local = new.env())
