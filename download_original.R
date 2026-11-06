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

verified <- planned |>
  mutate(md5_ok = unname(tools::md5sum(path)) == md5_served,
         bytes_ok = file.size(path) == bytes,
         published_agrees = md5_served == md5_published)

stopifnot(all(verified$md5_ok), all(verified$bytes_ok))

# original/ must hold the deposit and nothing else. all.files = TRUE is not optional: without
# it a stray dotfile passes unseen.
extra <- setdiff(
  list.files(here::here("original"), recursive = TRUE, all.files = TRUE, no.. = TRUE),
  manifest$file
)
if (length(extra) > 0) stop("original/ holds unlisted files: ", str_c(extra, collapse = ", "))

print(str_glue("All {nrow(verified)} files match on MD5 and byte size, and original/ holds ",
               "nothing else. {sum(!verified$published_agrees)} carry a published checksum ",
               "that disagrees with what Dataverse serves."))
