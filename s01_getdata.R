# get data from airtable

library(rairtable)

get_ll35_data <- function () {
  set_airtable_api_key(Sys.getenv("AIRTABLE_KEY"))
  
  ll35_at <- airtable(
    base = "appsmK6xweIG90aYB",
    table = "tblfXUuSjpWurNZlN"
  )
}