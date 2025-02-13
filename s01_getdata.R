# get data from airtable

#remotes::install_github('matthewjrogers/rairtable')
library(rairtable)
library(tidyverse)

set_airtable_api_key(Sys.getenv("AIRTABLE_KEY"))

get_ll35_data <- function () {
  tool_fields <- c(
    "tool_name",
    "agency",
    "department",
    "tool_desc",
    "updated",
    "updated_desc",
    "month_use",
    "year_use",
    "data_training",
    "data_input",
    "data_output",
    "vendor_checkbox",
    "vendor_name",
    "vendor_desc",
    "identifying_info",
    "population_type",
    "population_type_individual",
    "population_type_other",
    "purpose_type",
    "purpose_desc",
    "computation_type"
  )

  ll35_tools <- airtable(
    base = "appsmK6xweIG90aYB",
    table = "tblfXUuSjpWurNZlN",
    view = "Tool Reporting"
  ) |>
    read_airtable(fields = tool_fields) |>
    unnest(agency)

  ll35_agency <- airtable(
    base = "appsmK6xweIG90aYB",
    table = "tbl9gC21ohoocjtkJ",
    view = "All Agencies"
  ) |>
    read_airtable(
      fields = c("Agency Name", "Agency Abbr")
    ) |>
    rename(agency_full = "Agency Name",
           agency_abbr = "Agency Abbr")

  res <- left_join(
    ll35_tools,
    ll35_agency,
    by = c(agency = "airtable_record_id")
  ) |>
    mutate(agency = str_glue("{agency_full} ({agency_abbr})"))

  return(res)
}

ll35_at <- get_ll35_data()

write_rds(ll35_at, str_glue("data/df_for_reporting_{today()}.rds"))
