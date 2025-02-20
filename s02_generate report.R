## libraries -------

library(tidyverse)
library(fs)
library(knitr)
library(rmarkdown)

## data --------

df_raw <- read_rds("data/df_for_reporting.rds")


## functions ------

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

write_population <- function(pop_type, pop_type_ind, pop_type_oth) {
  resp <- pop_type

  if (!is.na(pop_type_ind)) {
    resp <- str_replace(resp, "Individuals", str_glue("Individuals ({pop_type_ind})"))
  }

  if (!is.na(pop_type_oth)) {
    resp <- str_replace(resp, "Other", str_glue("Other ({pop_type_oth})"))
  }

  return(resp)
}

write_vendor <- function(vendor_checkbox, vendor_name, vendor_desc) {
  if(is.na(vendor_checkbox)) {
    return("")
  } else {

    resp <- str_glue(
      "
### Vendor Information

__Vendor Name__: {vendor_name}

{vendor_desc}
      "
    )

    return(resp)
  }
}

write_update <- function(updated, updated_desc) {
  if (updated != "Yes") {
    return ("")
  } else {
    resp <- str_glue(
      "
### Update Description

{updated_desc}

      "
    )

    return(resp)
  }
}

## edit data -----

df_mut <- df_raw |>
  mutate(
    date_use = map2_chr(month_use, year_use, write_date)
    , department = replace_na(department, "Not specified")
    , computation_type = replace_na(computation_type, "Not specified")
    , updated = replace_na(updated, "Not specified")
    , population_type = map_chr(population_type, str_c, collapse = "; ")
    , purpose_type = replace_na(purpose_type, "Not specified")
    , identifying_info = map_chr(identifying_info, write_identifying)
    , text_pop_type = pmap_chr(list(population_type, population_type_individual, population_type_other), write_population)
    , text_vendor = pmap_chr(list(vendor_checkbox, vendor_name, vendor_desc), write_vendor)
    , text_update = map2_chr(updated, updated_desc, write_update)
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

    | | |
    |:--|:--|
    | __Department__: {department}              |                                   |
    | __First Used__: {date_use}                | __Updated in 2024__: {updated}    |
    | __Computation Type__: {computation_type}  | __Purpose Type__: {purpose_type}  |
    | __Population Type__: {text_pop_type}      | __Identifying Information__: {identifying_info} |  |

    ### Tool Description

    {tool_desc}

    ### Tool Purpose

    {purpose_desc}
    
    {text_update}

    ### Data Analyzed

    | | |
    |:--|:--|
    | __Training Data__ | {data_training} |
    | __Input Data__ | {data_input} |
    | __Output Data__ | {data_output} |

    {text_vendor}
    
    "
  ) |>
    str_c(collapse = "\n")
}

tool_report <- group_split(df_mut, agency) |>
  map(tool_template)

agency_report <- map2(
  agencies, tool_report, str_c
)

## paste results into separate reports per agency

agency_abbr <- pull(distinct(df_mut, agency_abbr), agency_abbr)

walk2(
  agency_report, agency_abbr,
  ~cat(.x, file = str_c("agency_draft/", .y, ".md"), append = FALSE)
)

walk2(dir_ls("agency_draft", glob="*.md"), agency_abbr,
      ~render(.x, output_format = "word_document", output_dir = "agency_draft"))

## yaml ------

yaml <- "---
title: 'Local Law 35 Reporting'
author: 'renata gerecke'
output:
  pdf_document:
    fontsize: 11pt
    toc: true
    toc_depth: 1
---
"

## paste results into full report -----

cat(
  str_c(yaml, str_c(agency_report, collapse = "\n"), sep = "\n"), 
  file = str_glue("test_report_{today()}.md"), 
  append = FALSE
)

render(
  str_glue("test_report_{today()}.md")
  )

