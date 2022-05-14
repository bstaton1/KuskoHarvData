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

#' Obtain Northerly Wind Speed Vector
#'
#' Decomposes a directional wind speed vector into
#' its northerly speed
#'
#' @param speed Numeric; wind speed associated with the angle
#' @param angle Numeric; wind directional angle associated with the speed.
#' @param digits Numeric; how many decimal places to round to? Passed to [base::round()] and defaults to 1
#' @details The `angle` represents degrees from exactly northerly wind:
#'   * `angle = 0`: exactly northerly wind (i.e., from north to south, blowing in your face standing north)
#'   * `angle = 45`: exactly northeasterly wind
#'   * `angle = 180`: exactly southerly wind
#' @return A numeric value representing the vector of northerly wind speed.
#'   Positive values correspond to northerly winds, negative values to southerly winds.
#'   The absolute magnitude of the number corresponds to the speed in the north or south direction.

get_Nwind = function(speed, angle, digits = 1) {
  round(speed * cos(pi * angle/180), digits = digits)
}

#' Obtain Easterly Wind Speed Vector
#'
#' Decomposes a directional wind speed vector into
#' its easterly speed
#'
#' @param speed Numeric; wind speed associated with the angle
#' @param angle Numeric; wind directional angle associated with the speed.
#' @param digits Numeric; how many decimal places to round to? Passed to [base::round()] and defaults to 1
#' @details The `angle` represents degrees from exactly northerly wind:
#'   * `angle = 0`: exactly northerly wind (i.e., from north to south, blowing in your face standing north)
#'   * `angle = 45`: exactly northeasterly wind
#'   * `angle = 180`: exactly southerly wind
#' @return A numeric value representing the vector of easterly wind speed.
#'   Positive values correspond to easterly winds, negative values to westerly winds.
#'   The absolute magnitude of the number corresponds to the speed in the east or west direction.

get_Ewind = function(speed, angle, digits = 1) {
  round(speed * sin(pi * angle/180), digits = digits)
}

#' @title Obtain the "Period" of the Season the Record Falls In
#' @param x Either a numeric value representing days past May 31 that year
#'   or a date object, which will be coerced to days past May 31 prior to the calculation.
#' @return The period number corresponding to the input date(s) supplied to `x`:
#'   * `1`: June 12 - June 19; first week of drift fishing allowed.
#'   * `2`: June 20 - June 30; remainder of June.
#'   * `3`: July 1 - July 30; any date in July.
#'   * `NA`: if the date does not fall in any of these periods.

get_period = function(x) {

  # convert to "days past may 31 if necessary and possible
  if (class(x) %in% c("numeric", "integer")) {
    day = x
  } else {
    if (class(x) == "Date") {
      day = KuskoHarvData:::to_days_past_may31(x)
    } else {
      stop ("x must be a numeric or Date object")
    }
  }

  # build the days in each period
  d1 = 12:19  # first week of drift fishing
  d2 = 20:30  # remainder of June
  d3 = 31:60  # any date in July

  # build the period indicators
  p1 = rep(1, length(d1)); names(p1) = d1
  p2 = rep(2, length(d2)); names(p2) = d2
  p3 = rep(3, length(d3)); names(p3) = d3
  period_key = c(p1, p2, p3)

  # determine which period this day is in
  period = period_key[as.character(day)]

  # return the period found
  return(unname(period))
}
