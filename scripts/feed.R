library(tidyverse)
library(lubridate)
library(jsonlite)

# Read raw data exported from Huckleberry
dt <- read_csv("data-raw/data.csv", show_col_types = FALSE)

# Process feeding events
feed <- dt |>
  filter(Type == "Feed") |>
  mutate(
    start = ymd_hms(Start),
    end = ymd_hms(End),
    # Parse duration string "HH:MM" to seconds
    duration_seconds = {
      parts <- str_split(Duration, ":", simplify = TRUE)
      as.numeric(parts[, 1]) * 3600 + as.numeric(parts[, 2]) * 60
    },
    # Right breast duration from Start Condition (e.g., "00:09R")
    right_breast = `Start Condition`,
    # Left breast duration from End Condition (e.g., "00:10L")
    left_breast = `End Condition`,
    notes = Notes
  ) |>
  # Convert timestamps to ISO-8601 strings
  mutate(
    start = format(start, "%Y-%m-%dT%H:%M:%S-03:00"),
    end = format(end, "%Y-%m-%dT%H:%M:%S-03:00")
  ) |>
  # Replace NA with null for JSON
  mutate(
    across(c(right_breast, left_breast, notes),
           ~if_else(is.na(.) | . == "", NA_character_, .))
  ) |>
  select(start, end, duration_seconds, right_breast, left_breast, notes) |>
  # Remove complete duplicate rows
  distinct() |>
  arrange(start)

# Output as JSON for index.html
events_json <- toJSON(feed, pretty = TRUE, na = "null")
write(events_json, "data/feed.json")

cat("Wrote", nrow(feed), "feed events to data/feed.json\n")
