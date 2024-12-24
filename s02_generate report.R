## libraries -------

library(tidyverse)
library(readxl)
library(janitor)
# library(fs)


## data --------

df_raw <- read_rds("data/df_for_reporting.rds")

write_date <- function(month_use, year_use) {
  if (month_use == "Unknown") {
    return(as.character(year_use))
  } else {
    return(paste(month_use, year_use))
  }
}

write_identifying <- function(identifying_info) {
  if (is.na(identifying_info)) {
    return("No")
  } else{
    return("Yes")
  }
}

df_mut <- df_raw |>
  mutate(
    date_use = map2_chr(month_use, year_use, write_date)
    , computation_type = replace_na(computation_type, "")
    , population_type = map_chr(population_type, str_c, collapse = "; ")
    , identifying_info = map_chr(identifying_info, write_identifying)
  )

agencies <- df_mut |>
  distinct(agency) |>
  str_glue_data("
        # {agency}

        ")

tool_template <- function(data) {
  str_glue_data(
    data,
    "
    ## {tool_name}

    __First Used__: {date_use}

    | | |
    |:--|:--|
    | __Computation Type__: {computation_type} | __Purpose Type__: {purpose_type} |
    | __Identifying Information__: {identifying_info} | __Updated in 2024__: {updated} |

    ### Tool Description

    {tool_desc}

    ### Tool Purpose

    {purpose_desc}

    ### Populations Impacted

    {population_type}

    {
    ifelse(!is.na(population_type_individual),
      str_c('Individuals impacted include: ',
        population_type_individual),
      ''
    )
    }

    ### Data Analyzed

    | | |
    |:--|:--|
    | __Training Data__ | {data_training} |
    | __Input Data__ | {data_input} |
    | __Output Data__ | {data_output} |

    "
  ) |>
    str_c(collapse = "\n")
}

tool_report <- group_split(head(df_mut), agency) |>
  map(tool_template)

agency_report <- map2(
  c("ACS", "DOE"), tool_report, str_c
) |>
  str_c(collapse = "\n")

clipr::write_clip(agency_report)

## paste results into `test_report.md` and knit to word document
