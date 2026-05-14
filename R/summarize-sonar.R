#' Summarize Sonar Count data
#'
#' Obtains a species-specific summary in terms of either proportional composition or daily count
#' with the ability to average over a several day window to smooth out daily variability.
#'
#' @param date Datetime; the date to summarize. Must be of length 1.
#'   If `plus_minus > 0`, becomes the center of window across which the average is calculated.
#' @param stat Character; the summary stat/species combination to return. Must be of length 1.
#'   Accepted values are:
#'   * `"chinook_count"` -- returns the daily count of Chinook salmon, averaged over a window if `plus_minus > 0`
#'   * `"chum_count"`
#'   * `"sockeye_count"`
#'   * `"total_count"`
#'   * `"chinook_comp"` -- returns proportion of all daily counts made up of Chinook salmon, averaged over a window if `plus_minus > 0`
#'   * `"chum_comp"`
#'   * `"sockeye_comp"`
#' @param plus_minus Numeric; the number of days before and after `date` to include in the average statistic returned. Must be of length 1.
#'   `plus_minus = 0` (default) will return the observed daily value, `plus_minus = 1` will return a three day average with `date` as the center day.
#'   Greater values of `plus_minus` will introduce more smoothing of between-day variability.
#' @note If the requested date is not found in the sonar data (e.g., 2016, 2017, late-season in 2024) an `NA` value will be returned.

summarize_sonar = function(date, stat, plus_minus = 0) {

  # load sonar data
  data("sonar_data_all", package = "KuskoHarvData", envir = environment())

  # list of acceptable summary statistics
  accepted_stats = c("chinook_comp", "chum_comp", "sockeye_comp", "chinook_count", "chum_count", "sockeye_count", "total_count")

  # ensure only one date was supplied and it is correctly formatted
  if (length(date) != 1 | !lubridate::is.Date(date)) {
    stop ("date must be of class 'date' and be of length 1")
  }

  # ensure only one statistic type was supplied and it is correctly formatted
  if (length(stat) != 1 | !is.character(stat)) {
    stop ("stat must be a character vector of length 1")
  }

  # ensure the statistic is accepted by function
  if (!(stat %in% accepted_stats)) {
    stop ("supplied value of stat (", stat, ") is not accepted. \nAcceptable values include: ", paste(accepted_stats, collapse = ", "))
  }

  # determine which species to calculate the statistic for
  spp_stat = stringr::str_extract(stat, "^[:alpha:]+")

  # determine the type of statistic to calculate
  type_stat = stringr::str_extract(stat, "[:alpha:]+$")

  # build the window around the supplied date: larger values of plus_minus smooth out more daily variability
  keep_dates = date + seq(-plus_minus, plus_minus)

  # if the date is not found in the sonar data set, return NA, otherwise, perform calculations
  if (!all(keep_dates %in% sonar_data_all$date)) {
    out = NA
  } else {

    # if the stat type is a count, calculate the average daily count
    if (type_stat == "count") {
      sonar_sub = subset(sonar_data_all, date %in% keep_dates & species == spp_stat)
      out = sum(sonar_sub$count)/length(keep_dates)
    }

    # if the stat type is comp, calculate the average daily proportional contribution of the species to total count
    if (type_stat == "comp") {
      sonar_sub = subset(sonar_data_all, date %in% keep_dates)
      numerator_total = sum(sonar_sub$count[sonar_sub$species == spp_stat])
      denominator_total = sum(sonar_sub$count[sonar_sub$species == "total"])
      out = numerator_total/denominator_total
    }
  }

  # return the summary stat
  return(out)
}
