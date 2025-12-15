library(tidyverse)
library(lubridate)
library(jsonlite)

# Read raw data exported from Huckleberry
dt <- read_csv("data-raw/data.csv", show_col_types = FALSE)

# Process sleep events
sleep <- dt |>
  filter(Type == "Sleep") |>
  mutate(
    start = ymd_hms(Start),
    end = ymd_hms(End),
    type = case_when(
      hour(start) >= 18 ~ "night sleep",
      hour(start) < 6 ~ "night sleep",
      TRUE ~ "day sleep"
    ),
    start_condition = `Start Condition`,
    end_condition = `End Condition`,
    start_location = `Start Location`,
    notes = Notes
  ) |>
  # Convert timestamps to ISO-8601 strings
  mutate(
    start = format(start, "%Y-%m-%dT%H:%M:%S-03:00"),
    end = format(end, "%Y-%m-%dT%H:%M:%S-03:00")
  ) |>
  # Replace NA with null for JSON
  mutate(
    across(c(start_condition, end_condition, start_location, notes),
           ~if_else(is.na(.) | . == "", NA_character_, .))
  ) |>
  select(start, end, type, start_condition, end_condition, start_location, notes) |>
  arrange(start)

# Output as JSON for index.html
events_json <- toJSON(sleep, pretty = TRUE, na = "null")
write(events_json, "data/sleep.json")

cat("Wrote", nrow(sleep), "sleep events to data/sleep.json\n")