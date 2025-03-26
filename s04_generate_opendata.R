## libraries -------

library(tidyverse)
library(fs)
library(httr)
library(jsonlite)

## data --------

df_raw <- read_rds(str_glue("data/df_for_opendata_{today()}.rds"))
df_history <- GET("https://data.cityofnewyork.us/resource/jaw4-yuem.json") |>
  content(as = "text") |>
  fromJSON(flatten=TRUE)

## mutate ------

df_agencies <- distinct(df_raw, agency_full, agency_abbr, agency) |>
  add_row(
    agency_full = "NYC Public Schools",
    agency_abbr = "DOE"
  ) |>
  add_row(
    agency_full = "School Construction Authority",
    
  )

df_mut <- df_raw |>
  mutate(
    year = "2024",
    agency = 
  )