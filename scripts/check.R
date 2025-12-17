library(tidyverse)
library(lubridate)
library(jsonlite)

# Read raw data
raw <- read_csv("data-raw/data.csv", show_col_types = FALSE)

# Read generated JSON files
sleep_json <- fromJSON("data/sleep.json")
feed_json <- fromJSON("data/feed.json")

cat("=== Data Quality Check ===\n\n")

# -------------------------
# SLEEP DATA CHECK
# -------------------------
cat("--- SLEEP DATA ---\n")

raw_sleep <- raw |>
  filter(Type == "Sleep") |>
  mutate(
    start = ymd_hms(Start),
    end = ymd_hms(End),
    duration_minutes = as.numeric(difftime(end, start, units = "mins"))
  ) |>
  filter(!is.na(start) & !is.na(end))

raw_sleep_count <- nrow(raw_sleep)
json_sleep_count <- nrow(sleep_json)

cat(sprintf("Raw CSV sleep records: %d\n", raw_sleep_count))
cat(sprintf("JSON sleep records: %d\n", json_sleep_count))

if (raw_sleep_count != json_sleep_count) {
  cat(sprintf("  WARNING: Count mismatch! Difference: %d\n", abs(raw_sleep_count - json_sleep_count)))

  # Find missing records
  raw_starts <- format(raw_sleep$start, "%Y-%m-%dT%H:%M:%S")
  json_starts <- substr(sleep_json$start, 1, 19)

  missing_in_json <- setdiff(raw_starts, json_starts)
  extra_in_json <- setdiff(json_starts, raw_starts)

  if (length(missing_in_json) > 0) {
    cat("  Records in CSV but not in JSON:\n")
    for (m in head(missing_in_json, 10)) {
      cat(sprintf("    - %s\n", m))
    }
    if (length(missing_in_json) > 10) {
      cat(sprintf("    ... and %d more\n", length(missing_in_json) - 10))
    }
  }

  if (length(extra_in_json) > 0) {
    cat("  Records in JSON but not in CSV:\n")
    for (e in head(extra_in_json, 10)) {
      cat(sprintf("    - %s\n", e))
    }
    if (length(extra_in_json) > 10) {
      cat(sprintf("    ... and %d more\n", length(extra_in_json) - 10))
    }
  }
} else {
  cat("  OK: Record counts match\n")
}

# Check total duration
raw_sleep_total_mins <- sum(raw_sleep$duration_minutes, na.rm = TRUE)
json_sleep_total_mins <- sum(
  as.numeric(difftime(
    ymd_hms(substr(sleep_json$end, 1, 19)),
    ymd_hms(substr(sleep_json$start, 1, 19)),
    units = "mins"
  )),
  na.rm = TRUE
)

cat(sprintf("\nRaw CSV total sleep: %.1f hours\n", raw_sleep_total_mins / 60))
cat(sprintf("JSON total sleep: %.1f hours\n", json_sleep_total_mins / 60))

if (abs(raw_sleep_total_mins - json_sleep_total_mins) > 1) {
  cat(sprintf("  WARNING: Duration mismatch! Difference: %.1f minutes\n",
              abs(raw_sleep_total_mins - json_sleep_total_mins)))
} else {
  cat("  OK: Total durations match\n")
}

# -------------------------
# FEED DATA CHECK
# -------------------------
cat("\n--- FEED DATA ---\n")

raw_feed <- raw |>
  filter(Type == "Feed") |>
  mutate(
    start = ymd_hms(Start),
    end = ymd_hms(End),
    duration_minutes = as.numeric(difftime(end, start, units = "mins"))
  ) |>
  filter(!is.na(start) & !is.na(end))

raw_feed_count <- nrow(raw_feed)
json_feed_count <- nrow(feed_json)

cat(sprintf("Raw CSV feed records: %d\n", raw_feed_count))
cat(sprintf("JSON feed records: %d\n", json_feed_count))

if (raw_feed_count != json_feed_count) {
  cat(sprintf("  WARNING: Count mismatch! Difference: %d\n", abs(raw_feed_count - json_feed_count)))

  # Find missing records
  raw_starts <- format(raw_feed$start, "%Y-%m-%dT%H:%M:%S")
  json_starts <- substr(feed_json$start, 1, 19)

  missing_in_json <- setdiff(raw_starts, json_starts)
  extra_in_json <- setdiff(json_starts, raw_starts)

  if (length(missing_in_json) > 0) {
    cat("  Records in CSV but not in JSON:\n")
    for (m in head(missing_in_json, 10)) {
      cat(sprintf("    - %s\n", m))
    }
    if (length(missing_in_json) > 10) {
      cat(sprintf("    ... and %d more\n", length(missing_in_json) - 10))
    }
  }

  if (length(extra_in_json) > 0) {
    cat("  Records in JSON but not in CSV:\n")
    for (e in head(extra_in_json, 10)) {
      cat(sprintf("    - %s\n", e))
    }
    if (length(extra_in_json) > 10) {
      cat(sprintf("    ... and %d more\n", length(extra_in_json) - 10))
    }
  }
} else {
  cat("  OK: Record counts match\n")
}

# Check total duration
raw_feed_total_mins <- sum(raw_feed$duration_minutes, na.rm = TRUE)
json_feed_total_mins <- sum(feed_json$duration_seconds, na.rm = TRUE) / 60

cat(sprintf("\nRaw CSV total feed: %.1f hours\n", raw_feed_total_mins / 60))
cat(sprintf("JSON total feed: %.1f hours\n", json_feed_total_mins / 60))

if (abs(raw_feed_total_mins - json_feed_total_mins) > 1) {
  cat(sprintf("  WARNING: Duration mismatch! Difference: %.1f minutes\n",
              abs(raw_feed_total_mins - json_feed_total_mins)))
} else {
  cat("  OK: Total durations match\n")
}

# -------------------------
# DATE RANGE CHECK
# -------------------------
cat("\n--- DATE RANGES ---\n")

raw_min_date <- min(c(raw_sleep$start, raw_feed$start), na.rm = TRUE)
raw_max_date <- max(c(raw_sleep$end, raw_feed$end), na.rm = TRUE)

cat(sprintf("Raw data range: %s to %s\n",
            format(raw_min_date, "%Y-%m-%d"),
            format(raw_max_date, "%Y-%m-%d")))

json_sleep_dates <- ymd_hms(substr(sleep_json$start, 1, 19))
json_feed_dates <- ymd_hms(substr(feed_json$start, 1, 19))

json_min_date <- min(c(json_sleep_dates, json_feed_dates), na.rm = TRUE)
json_max_date <- max(c(json_sleep_dates, json_feed_dates), na.rm = TRUE)

cat(sprintf("JSON data range: %s to %s\n",
            format(json_min_date, "%Y-%m-%d"),
            format(json_max_date, "%Y-%m-%d")))

# -------------------------
# SUMMARY
# -------------------------
cat("\n=== SUMMARY ===\n")

issues <- 0
if (raw_sleep_count != json_sleep_count) issues <- issues + 1
if (abs(raw_sleep_total_mins - json_sleep_total_mins) > 1) issues <- issues + 1
if (raw_feed_count != json_feed_count) issues <- issues + 1
if (abs(raw_feed_total_mins - json_feed_total_mins) > 1) issues <- issues + 1

if (issues == 0) {
  cat("All checks passed!\n")
} else {
  cat(sprintf("%d issue(s) found. Review warnings above.\n", issues))
}
