#' Bethel Airport Weather Data
#'
#' A data set containing daily weather data summaries collected at the Bethel airport.
#'
#' @format A data frame with rows representing a unique date.
#'   Variables include:
#'   * `date`: the date the data correspond to; only dates between June 1 and July 31 in years after and including 2016 are included
#'   * `mean_temp`: the average of all temperature measurements available on that date, in degrees Fahrenheit
#'   * `min_temp`: the minimum of all temperature measurements available on that date, in degrees Fahrenheit
#'   * `max_temp`: the maximum of all temperature measurements available on that date, in degrees Fahrenheit
#'   * `mean_relh`: the average of all relative humidity measurements on that date, in percent of maximum
#'   * `precip`: the sum of all precipitation measurements on that date, in inches
#'   * `mean_wind`: the average of all daily wind speed measurements, in miles per hour
#'   * `mean_Nwind`: the average of all daily wind measurements (in miles per hour) after converting to a northerly speed vector.
#'       See [KuskoHarvUtils::get_Nwind()] for details.
#'   * `mean_Ewind`: the average of all daily wind measurements (in miles per hour) after converting to a easterly speed vector. Calculated as
#'       See [KuskoHarvUtils::get_Ewind()] for details.
#'   * `max_gust`: the daily maximum of all gust measurements. Note that gusts only register if they exceed 14 knots.
#' @note This data set will need to be updated regularly (at least annually).
#'   To do this, execute the script `data-raw/prepare-weather-data.R` and rebuild the package.
#' @source This data set relies on the '[riem package](https://docs.ropensci.org/riem/index.html)' to query the ASOS database (airports),
#'   hosted by the [Iowa State University Environmental Mesonet](https://mesonet.agron.iastate.edu/request/download.phtml?network=IN__ASOS).
#'

"weather_data_master"
