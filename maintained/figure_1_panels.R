# coppock_2025/maintained/figure_1_panels.R
# Output: maintained/output/figure_1_estimates.csv, figure_1b_specifications.csv,
#   figure_1d_slopes.csv
# Depends on: original/, maintained/helpers.R
# Description: Recompute Figure 1 from the book's surveys: Study 1 (2018), Study 2 (2014),
#   Study 3 (2017), Study 4 (2020), and Study 5 (2019). The review's own code is not deposited,
#   so the specification of each panel is inferred, and is tested against the plotted positions
#   in ground_truth/figure_1_plotted.csv by ground_truth/build_ground_truth.R. Panel b follows
#   chapter_3_chamberrcontrol.R in the review's project archive, which reads the 2014 survey.

source(here::here("maintained", "helpers.R"))

unasked <- \(x, top) if_else(x > top, NA_real_, x)

# Study 1: four issues, each with its own assignment, on a 0 to 1 favor scale ----
d18 <- read_survey("2018 UML YouGov Survey.dta")

issues <- c(minimum_wage = "408", arming_teachers = "409", citizenship = "410", two_thirds = "411")

study_1 <- imap(issues, \(q, item) {
  arm <- as.numeric(d18[[str_c("q", q, "treat")]])
  answer <- case_when(arm == 1 ~ as.numeric(d18[[str_c("Q", q, "a")]]),
                      arm == 2 ~ as.numeric(d18[[str_c("Q", q, "b")]]),
                      arm == 3 ~ as.numeric(d18[[str_c("Q", q, "c")]]))
  frame <- tibble(y = (4 - unasked(answer, 4)) / 3, condition = arm, party = party_of(d18$pid7))
  bind_rows(cate(frame, 2, 1) |> mutate(facet = "Democratic"),
            cate(frame, 3, 1) |> mutate(facet = "Republican")) |>
    mutate(panel = "a", item = item)
}) |> list_rbind()

# Study 2: chamber control, 2014. Form a says Republicans hold 40%, form b that Democrats do ----
d14 <- read_survey("UMAS0014_OUTPUT-3 with knowledge codes.dta")

study_2_frame <- d14 |>
  transmute(
    y = unasked(coalesce(as.numeric(Q58a), as.numeric(Q58b)), 5),
    condition = as.numeric(Q58_rand),
    party = party_of(as.numeric(pid7)),
    weight = as.numeric(weight)
  )

study_2 <- cate(study_2_frame, 2, 1, weights = "weight") |>
  mutate(panel = "b", facet = "Republicans control 60%", item = "chamber")

# The same design was fielded again in 2018 (Q401). The review does not plot it, and it is kept
# because its signs are the reverse of 2014's.
repeat_2018_frame <- d18 |>
  transmute(
    y = unasked(if_else(q401treat == 1, as.numeric(Q401a), as.numeric(Q401b)), 5),
    condition = as.numeric(q401treat),
    party = party_of(as.numeric(pid7)),
    weight = as.numeric(weight)
  )

# The two sentences' seat shares and the scale's direction, at the point of use.
stopifnot(str_detect(attr(d14$Q58a, "label"), "^R 40% D 60%"),
          str_detect(attr(d14$Q58b, "label"), "^D 40% R 60%"),
          str_detect(names(attr(d14$Q58a, "labels"))[1], "^Republican .* conservative"),
          str_detect(names(attr(d14$Q58a, "labels"))[5], "^Democratic .* liberal"),
          str_detect(attr(d18$Q401a, "label"), "^Republican Party .* 40%"),
          str_detect(attr(d18$Q401b, "label"), "^Democratic Party .* 40%"),
          str_detect(names(attr(d18$Q401a, "labels"))[1], "^a Republican .* conservative"),
          str_detect(names(attr(d18$Q401a, "labels"))[5], "^a Democratic .* liberal"))

# Panel b is the 2014 weighted row. The others are reported for comparison.
specifications <- bind_rows(
  cate(study_2_frame, 2, 1, weights = "weight") |> mutate(survey = 2014, weighted = TRUE),
  cate(study_2_frame, 2, 1) |> mutate(survey = 2014, weighted = FALSE),
  cate(repeat_2018_frame, 2, 1, weights = "weight") |> mutate(survey = 2018, weighted = TRUE),
  cate(repeat_2018_frame, 2, 1) |> mutate(survey = 2018, weighted = FALSE)
)
write_output(specifications, "figure_1b_specifications.csv")

# Study 3: foods, on a 0 to 1 scale. Each item has its own assignment ----
d17 <- read_survey("2017 UML YouGov Survey.dta")

foods <- list(
  chili = list(q = "q022all", arm = "treat_Q22", obama = 2, trump = 3),
  meatloaf = list(q = "q021all", arm = "treat_Q21", obama = 3, trump = 2),
  lasagna = list(q = "q020all", arm = "treat_Q20", obama = 3, trump = 2),
  salmon = list(q = "q019all", arm = "treat_Q19", obama = 3, trump = 2)
)

study_3 <- imap(foods, \(f, item) {
  frame <- tibble(y = (unasked(as.numeric(d17[[f$q]]), 4) - 1) / 3,
                  condition = as.numeric(d17[[f$arm]]), party = party_of(d17$pid7))
  bind_rows(cate(frame, f$obama, 1) |> mutate(facet = "Obama"),
            cate(frame, f$trump, 1) |> mutate(facet = "Trump")) |>
    mutate(panel = "c", item = item)
}) |> list_rbind()

# Study 5: the risky plan, against no cue. Arm 2 is the Republican cue and 3 the Democratic ----
d19 <- read_survey("2019 UML YouGov Data.dta")

study_5_frame <- tibble(
  y = as.numeric(unasked(as.numeric(d19$UML718), 2) == 1),
  condition = as.numeric(d19$treatment_UML718),
  # Panel e alone groups on the three-point scale, so leaners are not partisans here.
  party = case_when(d19$pid3 == 1 ~ "Democrat", d19$pid3 == 2 ~ "Republican"),
  weight = as.numeric(d19$weight)
)

study_5 <- bind_rows(
  cate(study_5_frame, 3, 1, weights = "weight") |> mutate(facet = "Democratic"),
  cate(study_5_frame, 2, 1, weights = "weight") |> mutate(facet = "Republican")
) |>
  mutate(panel = "e", item = "risky_tax")

write_output(bind_rows(study_1, study_2, study_3, study_5), "figure_1_estimates.csv")

# Study 4: support by cue and randomized cost. Panel d's sentences are about direction ----
d20 <- read_survey("2020 UML YouGov Data.dta")

study_4 <- tibble(
  y = (as.numeric(d20$UML930r) - 1) / 3,
  cue = as_factor(d20$form930r),
  cost = as.numeric(d20$AMOUNT_ASSIGN_UML930),
  party = party_of(d20$pid7)
) |>
  filter(!is.na(party), !is.na(y))

slopes <- study_4 |>
  group_by(party) |>
  group_modify(\(d, key) {
    tidy(lm_robust(y ~ cost, data = d)) |> filter(term == "cost") |>
      transmute(quantity = "cost_slope", group = "all", estimate, conf_low = conf.low, conf_high = conf.high)
  }) |>
  ungroup()

cue_means <- study_4 |>
  group_by(party, group = as.character(cue)) |>
  summarise(estimate = mean(y), .groups = "drop") |>
  mutate(quantity = "cue_mean")

write_output(bind_rows(slopes, cue_means), "figure_1d_slopes.csv")
