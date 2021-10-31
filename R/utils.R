#' Convert date to 'days past May 31'
#'
#' Standardizes a `datetime` object to be the number of days
#' past May 31 of that year
#'
#' @param dates Datetime; can be of length > 1

to_days_past_may31 = function(dates) {
  ref_date = lubridate::as_datetime(paste0(lubridate::year(dates), "-05-31"))
  floor(as.numeric(lubridate::as.period(lubridate::interval(ref_date, dates)), units = "day"))
}

#' Convert 'days past May 31' to a date
#'
#' Unstandardizes a number of days past May 31
#' to be a `datetime` object
#'
#' @param day Numeric; number of days past May 31 to convert to a `datetime` object. Can be of length > 1
#' @param year Numeric or character; the year of the output `datetime` object. Can be of length > 1, but if so, should be the same length as `day`

from_days_past_may31 = function(days, year = "1900") {
  ref_date = lubridate::as_date(paste0(as.character(year), "-05-31"))
  ref_date + days
}
