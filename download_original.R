# coppock_2025/download_original.R
# Output: original/ (the deposited data and code, not redistributed in this repo)
# Depends on: original_manifest.csv
# Description: Fetch the surveys Figure 1 reanalyzes from the UNC Dataverse collection "The
#   Power of Partisanship (OUP 2023)" and verify every file. The review itself has no deposit:
#   these are the book's data, released under CC0 by Dyck and Pearson-Merkowitz. Re-running is
#   free, since files already present with the right checksum are not downloaded again.

library(tidyverse)
library(here)

here::i_am("download_original.R")

base_url <- "https://dataverse.unc.edu/api/access/datafile"

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

dir.create(here::here("original"), showWarnings = FALSE)

planned <- manifest |>
  mutate(
    path = here::here("original", file),
    url = str_glue("{base_url}/{dataverse_file_id}?format=original"),
    md5_local = unname(tools::md5sum(path)),
    needs_download = is.na(md5_local) | md5_local != md5_served
  )

walk2(
  planned$url[planned$needs_download],
  planned$path[planned$needs_download],
  \(url, path) download.file(url, destfile = path, mode = "wb", quiet = TRUE)
)

# Study 2 is the book's 2014 survey. It is not in this manifest's datasets, and whether the
# collection holds it was not established, since the Dataverse search API refuses anonymous
# queries. This copy comes from the review's project archive, so a stranger cannot fetch it.
survey_2014 <- "UMAS0014_OUTPUT-3 with knowledge codes.dta"
survey_2014_source <- file.path(
  "~/Library/CloudStorage/Dropbox/archived_projects/coppock_2025/original_materials",
  "2014 UML YouGov Survey", survey_2014
)
if (!file.exists(here::here("original", survey_2014))) {
  stopifnot(file.copy(path.expand(survey_2014_source), here::here("original", survey_2014)))
}
stopifnot(unname(tools::md5sum(here::here("original", survey_2014))) == "840f103137191d70bfd192be2591b071")

verified <- planned |>
  mutate(md5_ok = unname(tools::md5sum(path)) == md5_served,
         bytes_ok = file.size(path) == bytes,
         published_agrees = md5_served == md5_published)

stopifnot(all(verified$md5_ok), all(verified$bytes_ok))

# original/ must hold the deposit and nothing else. all.files = TRUE is not optional: without
# it a stray dotfile passes unseen.
extra <- setdiff(
  list.files(here::here("original"), recursive = TRUE, all.files = TRUE, no.. = TRUE),
  c(manifest$file, survey_2014)
)
if (length(extra) > 0) stop("original/ holds unlisted files: ", str_c(extra, collapse = ", "))

print(str_glue("All {nrow(verified)} files match on MD5 and byte size, and original/ holds ",
               "nothing else. {sum(!verified$published_agrees)} carry a published checksum ",
               "that disagrees with what Dataverse serves."))
