library(tidyverse)
library(lubridate)
library(knitr)
library(data.table)
library(ggplot2)
library(hms)

pretty <- function(x) {
    as_hms(as.numeric(x))
}

dt <- read_csv("data-raw/data.csv")

sleep <- dt |>
  filter(Type == "Sleep") |>
  mutate(
    start = ymd_hms(Start),
    end = ymd_hms(End),
    duration = as.duration(hm(Duration)),
    duration_pretty = Duration,
    start_condition = `Start Condition`,
    end_condition = `End Condition`,
    start_location = `Start Location`,
   notes = Notes) |>
  mutate(
    start_hour = hour(start),
    time = case_when(
      start_hour >= 18 ~ "night sleep",  # Evening sleep
      start_hour < 6 ~ "night sleep",    # Early morning sleep
      TRUE ~ "day sleep"
    ),
    day = case_when(
      start_hour < 6 ~ date(start) - days(1),
      TRUE ~ date(start)
    )
  ) |>
  select(-start_hour) |>
  select(day, time, duration, duration_pretty, start, end, start_condition, end_condition, start_location, notes) |>
  arrange(start) |> 
  filter(start >= dmy("05/11/2025"))
