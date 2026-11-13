# Active Maintenance Report: coppock_2025

2026-11-05

- [Summary](#summary)
- [Paper overview](#paper-overview)
- [Original archive reproducibility](#original-archive-reproducibility)
- [Errata](#errata)
- [The extraction and the two
  instruments](#the-extraction-and-the-two-instruments)
- [Coverage](#coverage)
- [Number-by-number comparison](#number-by-number-comparison)
- [Maintained rewrite](#maintained-rewrite)
- [Figure verification](#figure-verification)
- [R environment](#r-environment)

**Archived at Zenodo:**
[doi:10.5281/zenodo.24168326](https://doi.org/10.5281/zenodo.24168326).
This DOI always resolves to the latest release of the maintained
version.

# Summary

This repository recomputes Figure 1 and checks the prose of a four-page
review article, which reanalyzes five survey experiments from *The Power
of Partisanship* (Dyck and Pearson-Merkowitz 2023). The review deposited
no code and no data. Its data are the book’s, from the UNC Dataverse
collection, and are released under CC0.

- **Panels (a), (c), and (e) reproduce.** 108 of 108 plotted values
  agree within 0.0005. The largest gaps are 0.0001 on estimates and
  0.0002 on interval ends. **The specifications behind that agreement
  were inferred from the plotted positions**, so it shows that this
  rewrite finds what was plotted. It is not an independent check that
  the specifications are the right ones. The panels use three different
  weight and party codings, which the article does not state.
- **Panel (b) reproduces from the 2014 survey, and p. 3 contradicts
  itself.** The review’s script for the panel,
  `chapter_3_chamberrcontrol.R`, is in the project archive and in no
  deposit. This repo’s rewrite follows it, and 6 of 6 plotted values
  agree within 0.0005. See [Errata](#errata).
- **Panel (d) is not compared.** See [Figure
  verification](#figure-verification).
- **The deposit’s Stata files were not run**, because Stata is not
  available here. `value_script` and `match` are NA throughout, so this
  repo has no archive-versus-page comparison.

| Link |  |
|----|----|
| Article | [10.1093/psquar/qqaf037](https://doi.org/10.1093/psquar/qqaf037) |
| Data collection | UNC Dataverse, datasets listed in `original_manifest.csv`; the 2014 survey from the project archive, so a stranger cannot fetch it (`download_original.R`) |
| Errata | `coppock_2025_errata.pdf` |

To reproduce, run `Rscript run_all.R`. It fetches the 11 deposited
files, verifies them against `original_manifest.csv` on MD5 and byte
size, recomputes the figure, builds the ground truth, and runs the gate.
The figure positions come from `ground_truth/extract_figure_1.py`, which
needs the article PDF as an argument. The PDF is not redistributed here.

    download_original.R, original_manifest.csv   the deposited surveys, not redistributed
    maintained/                                  the recomputation and in_text_claims.R
    ground_truth/                                the extraction, positions, ground truth, and gate
    errata.qmd, coppock_2025_errata.pdf          corrections to the article

# Paper overview

The review argues that the book’s experiments estimate the effects of
party cues and of chamber control, which do not manipulate the book’s
main causal variable. Study 1 uses the 2018 survey, Study 2 the 2014
survey, Study 3 the 2017 survey, Study 4 the 2020 survey, and Study 5
the 2019 survey.

The 2018 survey holds free-text responses in `Q149`, one of which
includes a respondent’s email address. Nothing in this repo reads or
redistributes that column, and the file comes from the public deposit
rather than from this repo.

# Original archive reproducibility

The review itself has nothing to run. The book’s Stata files are in
`original/` once fetched and were not executed. All 11 files match the
manifest. `ground_truth/run_archive.R` records each of the 7 Stata files
as `not_run` in both passes in `ground_truth/archive_run_status.csv`,
and `ground_truth/archive_overwrites.csv` has no rows. The maintained
code is a rewrite in R from the deposited `.dta` files, not a port of
the `.do` files.

# Errata

`coppock_2025_errata.pdf` carries two entries, defined in `errata.qmd`
and written to `errata_entries.csv`.

1.  **Study 2, corrected.** The first two Study 2 sentences contradicted
    the third and Figure 1(b), which agree with each other and with the
    2014 survey (Republicans 0.212, Democrats -0.121). The entry
    corrects them to “less conservative” and “more liberal” (review
    queue row 64, 2026-11-07). The repeat in the 2018 survey has the
    opposite signs, and the review does not plot it. All these intervals
    cover zero.
2.  **A dropped verb in Study 3.** “whether they given no cue” should
    read “whether they are given no cue”.

# The extraction and the two instruments

`ground_truth/published_claims.csv` holds 139 rows: 114 plotted values,
11 descriptive claims, and 14 structural, definitional, or transcribed
tokens. The article prints no estimate as a number. Its figure is
vector, so `extract_figure_1.py` converts each mark through its panel’s
axis ticks. The positions take nothing from the data.

`ground_truth/build_ground_truth.R` joins those positions to the
recomputation, and computes each descriptive claim across cells.
`maintained/in_text_claims.R` selects the same quantities cell by cell.
`ground_truth/claims_gate.R` runs the second as a program, requires one
printed line per declared claim in both directions, requires the two
instruments to agree at the printed precision, and requires every claim
id in the errata spine to name an extraction row.

Both instruments read the same output files, so their agreement is
evidence about the selection and arithmetic. It says nothing about
whether the inferred specification is the one the review used.

# Coverage

| Claim type   | Verdict       | Rows |
|:-------------|:--------------|-----:|
| definitional | no verdict    |    2 |
| descriptive  | does not hold |    2 |
| descriptive  | holds         |    7 |
| descriptive  | no verdict    |    2 |
| pipeline     | matches       |  114 |
| structural   | no verdict    |    5 |
| transcribed  | no verdict    |    7 |

**The nine descriptive verdicts are about direction.** Study 2’s first
two sentences hold in sign while every interval covers zero. In Study 1,
all four two-thirds signs hold, while the interval for Republicans under
the Republican cue covers zero, which sits uneasily with “clear
evidence”.

**Some claims have no verdict.** The abstract’s summary states no scope,
so the share of panel (a) and (e) cells with its signs (0.80) carries no
verdict. The sentence saying the reanalyses arrive at the authors’
estimates is not tested, because this repo holds no copy of the book’s
printed estimates. The book’s page and year are unchecked for the same
reason. Footnote 3’s citation was checked against Crossref on
2026-11-05.

# Number-by-number comparison

| Panel | Values | Within 0.0005 | Largest estimate gap | Largest interval gap |
|:------|-------:|--------------:|:---------------------|:---------------------|
| a     |     48 |            48 | 0.0001               | 0.0002               |
| b     |      6 |             6 | 0.0000               | 0.0000               |
| c     |     48 |            48 | 0.0001               | 0.0002               |
| e     |     12 |            12 | 0.0000               | 0.0002               |

The tolerance is set once in `build_ground_truth.R` and is half of the
third decimal. It is wider than the largest gap in the panels that
reproduce, and no precision of the marks was measured independently.
Panel (b)’s row compares with the weighted difference in means on the
2014 survey, as the review’s script computes it.
`maintained/output/figure_1b_specifications.csv` also reports the
unweighted one and both on the 2018 repeat.

# Maintained rewrite

`maintained/figure_1_panels.R` computes each panel with `lm_robust` as a
difference in means between cue and no cue within party. The
specifications are as follows.

| Panel | Study | Survey | Weights | Party                           |
|-------|-------|--------|---------|---------------------------------|
| a     | 1     | 2018   | none    | pid7, 1 to 3 and 5 to 7         |
| b     | 2     | 2014   | survey  | pid7, 1 to 3 and 5 to 7         |
| c     | 3     | 2017   | none    | pid7, 1 to 3 and 5 to 7         |
| d     | 4     | 2020   | none    | pid7, slopes and cue means only |
| e     | 5     | 2019   | survey  | pid3, 1 and 2                   |

The script asserts the survey’s 40 percent labels and the direction of
the candidate scale at the point of use.

# Figure verification

The figure is not redrawn. Its check is the comparison above, which uses
the positions of the published marks.

**Panel (d) is not read from the PDF.** The marks are points, lines, and
ribbons across cue, cost, and party, so reading them would mean
inferring a further specification for a comparison the review’s
sentences do not need. Those two sentences state direction only, and the
recomputed cost slopes and cue means test them. A plotting error in
panel (d) would not be caught here.

# R environment

| Package   | Version |
|:----------|:--------|
| R         | 4.6.2   |
| tidyverse | 2.0.0   |
| estimatr  | 2.0.1   |
| haven     | 2.5.5   |
