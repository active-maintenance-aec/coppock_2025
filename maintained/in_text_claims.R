# coppock_2025/maintained/in_text_claims.R
# Output: printed CLAIM lines, one per published quantity
# Depends on: maintained/output/ (run run_all.R first), ground_truth/published_claims.csv
# Description: The second instrument. It selects each quantity from the pipeline's output cell
#   by cell, by a path that does not run through the ground truth, and prints
#   CLAIM <claim_id> = <value> || <label>. ground_truth/claims_gate.R runs this file and
#   compares every line with value_rewrite. Nothing here refits a model or reads the article.

source(here::here("maintained", "helpers.R"))

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

# Read for the set of claim ids and each one's printed precision, and nothing else.
claims_meta <- read_csv(here::here("ground_truth", "published_claims.csv"),
                        col_types = cols(.default = col_character(), needs_block = col_logical(),
                                         digits = col_integer()))

claim <- function(claim_id, value, label) {
  meta <- claims_meta[claims_meta$claim_id == claim_id, ]
  stopifnot(nrow(meta) == 1, !is.na(meta$digits))
  shown <- if (is.na(value)) "NA" else sprintf(paste0("%.", meta$digits, "f"), value)
  cat(sprintf("CLAIM %s = %s || %s\n", claim_id, shown, label))
}

estimates <- out("figure_1_estimates.csv")
specifications <- out("figure_1b_specifications.csv")
study_4 <- out("figure_1d_slopes.csv")

cell <- function(panel_id, facet_name, item_name, party_name) {
  hit <- estimates |>
    filter(panel == panel_id, facet == facet_name, item == item_name, party == party_name)
  stopifnot(nrow(hit) == 1)
  hit$estimate
}

specification <- function(party_name, is_weighted) {
  hit <- specifications |> filter(party == party_name, weighted == is_weighted)
  stopifnot(nrow(hit) == 1)
  hit$estimate
}

cue_mean <- function(party_name, cue) {
  hit <- study_4 |> filter(party == party_name, quantity == "cue_mean", group == cue)
  stopifnot(nrow(hit) == 1)
  hit$estimate
}

slope <- function(party_name) {
  hit <- study_4 |> filter(party == party_name, quantity == "cost_slope")
  stopifnot(nrow(hit) == 1)
  hit
}

# Abstract ----
# "party support cues increase policy support among in-partisans and decrease it among
# out-partisans."
# covers: abstract_cue_pattern
cue_cells <- estimates |> filter(panel %in% c("a", "e"))
in_party <- with(cue_cells, (facet == "Democratic") == (party == "Democrat"))
claim("abstract_cue_pattern",
      mean(if_else(in_party, cue_cells$estimate > 0, cue_cells$estimate < 0)),
      "share of panel a and e cells with the stated sign; a summary, so no verdict")

# Introduction ----
# "In every case where direct comparison is possible, my reanalyses arrive at the same
# estimates as the authors"
# covers: intro_same_estimates
claim("intro_same_estimates", NA, "no counterpart here: the book's printed estimates are not in this repo")

# Study 1 ----
# "we see clear evidence of the usual pattern that Republican party support cues have positive
# effects for Republican subjects and negative effects for Democratic subjects; the Democratic
# party support cue has the opposite effects."
# covers: s1_two_thirds_pattern
claim("s1_two_thirds_pattern",
      as.numeric(cell("a", "Republican", "two_thirds", "Republican") > 0 &&
                   cell("a", "Republican", "two_thirds", "Democrat") < 0 &&
                   cell("a", "Democratic", "two_thirds", "Republican") < 0 &&
                   cell("a", "Democratic", "two_thirds", "Democrat") > 0),
      "the four two-thirds cells have the stated signs")

# "The estimates on the other three issues are closer to zero."
# covers: s1_other_issues_closer
closer <- expand_grid(facet = c("Democratic", "Republican"), party = c("Democrat", "Republican"),
                      item = c("minimum_wage", "arming_teachers", "citizenship")) |>
  mutate(closer = pmap_lgl(list(facet, party, item), \(f, p, i) {
    abs(cell("a", f, i, p)) < abs(cell("a", f, "two_thirds", p))
  }))
claim("s1_other_issues_closer", as.numeric(all(closer$closer)),
      "each other issue is closer to zero than two-thirds in the same facet and party")

# Study 2 ----
# The estimate is Republicans holding 60 percent minus Democrats holding 60 percent, on a scale
# from 1 (conservative Republican) to 5 (liberal Democrat).
# "When their party controls 60 percent of seats (compared with 40 percent), Republicans prefer
# a candidate who is more conservative."
# covers: s2_republicans_more_conservative
claim("s2_republicans_more_conservative",
      as.numeric(specification("Republican", FALSE) < 0 && specification("Republican", TRUE) < 0),
      "Republicans' estimate is negative, weighted and unweighted")

# "When their party controls 60 percent of seats (compared with 40 percent), Democrats prefer a
# candidate who is less liberal."
# covers: s2_democrats_less_liberal
claim("s2_democrats_less_liberal",
      as.numeric(specification("Democrat", FALSE) > 0 && specification("Democrat", TRUE) > 0),
      "Democrats' estimate is positive, weighted and unweighted")

# "Surprisingly (to me at least), subjects of both parties want more moderate candidates when
# the Republicans are in the majority and more extreme candidates when the Democrats are in the
# majority."
# covers: s2_both_more_moderate_republican_majority
claim("s2_both_more_moderate_republican_majority",
      as.numeric(specification("Democrat", FALSE) < 0 && specification("Democrat", TRUE) < 0 &&
                   specification("Republican", FALSE) > 0 && specification("Republican", TRUE) > 0),
      "Democrats' estimate negative and Republicans' positive, weighted and unweighted")

# Study 3 ----
# "The pattern here is that partisans express more dislike for foods favored by out-party
# leaders."
# covers: s3_out_party_dislike
claim("s3_out_party_dislike",
      as.numeric(cell("c", "Trump", "chili", "Democrat") < 0 &&
                   cell("c", "Trump", "meatloaf", "Democrat") < 0 &&
                   cell("c", "Obama", "chili", "Republican") < 0 &&
                   cell("c", "Obama", "meatloaf", "Republican") < 0),
      "out-party cues lower chili and meatloaf ratings in both parties")

# Study 4 ----
# "Democrats like the policy more when supported by Biden and less when supported by Trump;
# Republicans do the opposite."
# covers: s4_cue_direction
claim("s4_cue_direction",
      as.numeric(cue_mean("Democrat", "Biden Treatment") > cue_mean("Democrat", "Control") &&
                   cue_mean("Democrat", "Trump Treatment") < cue_mean("Democrat", "Control") &&
                   cue_mean("Republican", "Biden Treatment") < cue_mean("Republican", "Control") &&
                   cue_mean("Republican", "Trump Treatment") > cue_mean("Republican", "Control")),
      "cue means against no cue, by party")

# "Democrats like the policy less when it costs more; Republicans apparently are not as price
# sensitive."
# covers: s4_cost_direction
claim("s4_cost_direction",
      as.numeric(slope("Democrat")$conf_high < 0 &&
                   abs(slope("Republican")$estimate) < abs(slope("Democrat")$estimate)),
      "Democrats' cost slope is below zero and steeper than Republicans'")

# Study 5 ----
# "Relative to no cue, the Democratic party support cue increases support among Democrats and
# decreases it among Republicans; the Republican party support cue does the opposite."
# covers: s5_cue_direction
claim("s5_cue_direction",
      as.numeric(cell("e", "Democratic", "risky_tax", "Democrat") > 0 &&
                   cell("e", "Democratic", "risky_tax", "Republican") < 0 &&
                   cell("e", "Republican", "risky_tax", "Democrat") < 0 &&
                   cell("e", "Republican", "risky_tax", "Republican") > 0),
      "the four cells have the stated signs")

# Figure 1, panels a, b, c, and e ----
# covers: every f1_ row of the extraction. Float cells carry no quote.
figure_claims <- estimates |>
  pivot_longer(c(estimate, conf_low, conf_high), names_to = "statistic", values_to = "value") |>
  mutate(stat = recode(statistic, estimate = "est", conf_low = "low", conf_high = "high"),
         facet_slug = str_remove(str_replace_all(str_to_lower(facet), "[^a-z0-9]+", "_"), "_$"),
         id = str_glue("f1_{panel}_{facet_slug}_{item}_{str_to_lower(party)}_{stat}"),
         label = str_glue("Figure 1({panel}), {facet}, {item}, {party}, {statistic}"))
walk(seq_len(nrow(figure_claims)), \(i) {
  claim(figure_claims$id[i], figure_claims$value[i], figure_claims$label[i])
})
