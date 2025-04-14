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

date_fmt <- function(month, year){
  if (month == "Unknown") {
    month_num <- "00"
  } else {
    month_num <- match(month, month.name)
  }
  return(str_c(year, "/", str_pad(month_num, 2, "left", "0")))
}

pop_type_fmt <- function(pop_type) {
  if (is.na(pop_type)) {
    pop_out <- NA_character_
  } else if (str_detect(pop_type, "\\: ")) {
    pop_out <- str_extract(pop_type, ".*(?=\\: )")
  } else {
    pop_out <- pop_type
  }

  return(pop_out)
}

df_agencies <- distinct(df_raw, agency_full, agency_abbr) |>
  add_row(
    agency_full = "NYC Public Schools",
    agency_abbr = "DOE"
  ) |>
  add_row(
    agency_full = "School Construction Authority",
    agency_abbr = "SCA"
  ) |>
  add_row(
    agency_full = "Department of Consumer and Worker Protection",
    agency_abbr = "DCWP"
  ) |>
  add_row(
    agency_full = "Health + Hospitals",
    agency_abbr = "HH"
  ) |>
  add_row(
    agency_full = "Department of Corrections",
    agency_abbr = "DOC"
  )

df_history_mut <- df_history |>
  left_join(df_agencies, by = c(agency = "agency_abbr")) |>
  transmute(
    year = year,
    agency = agency_full,
    tool_name = tool_name,
    tool_desc = tool_desc_brief,
    date_use = date_use,
    data_training = data_training,
    data_input = data_input,
    data_output = data_output,
    vendor_name = vendor_name,
    identifying_info = identifying_info,
    analysis_type = analysis_type,
    computation_type = NA,
    population_type_other = str_extract(population_type, "(?<=Other\\: ).*"),
    population_type = map_chr(population_type, pop_type_fmt),
    updated = updated,
    updated_desc = updated_desc,
    vendor_desc = vendor_desc,
    data = data,
    vendor = vendor,
    purpose_type = NA,
    purpose_desc = tool_desc_detail
  )

df_mut <- df_raw |>
  transmute(
    year = "2024",
    agency = agency_full,
    tool_name,
    tool_desc = tool_desc,
    date_use = map2_chr(month_use, year_use, date_fmt),
    data_training = data_training,
    data_input = data_input,
    data_output = data_output,
    vendor_name = replace_na(vendor_name, "N/A"),
    identifying_info = replace_na(identifying_info, FALSE),
    analysis_type = NA,
    computation_type = replace_na(computation_type, "Not specified"),
    population_type = map_chr(population_type, str_c, collapse = "; "),
    population_type_individual = population_type_individual,
    population_type_other = population_type_other,
    updated = str_replace(updated, "Tool created in CY2024", "N/A"),
    updated_desc = updated_desc,
    vendor_desc = vendor_desc,
    data = NA,
    vendor = NA,
    purpose_type = replace_na(purpose_type, "Not specified"),
    purpose_desc = purpose_desc
  )

df_all <- bind_rows(df_mut, df_history_mut)

# `write_excel_csv` function prevents character encoding issues in excel
write_excel_csv(df_all, str_glue("data/csv_for_opendata_{today()}.csv"), )
