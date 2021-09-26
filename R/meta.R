#' Meta-data for each opener with monitoring data
#'
#' A data set containing basic information about each opener with interview and/or flight data
#'
#' @format A data frame with rows representing a unique day in which the fishery was open and monitoring occurred.
#'   Variables include:
#'   * `start`: the earliest time fishing was allowed that day (stored as a datetime class)
#'   * `end`: the latest time fishing was allowed that day (stored as a datetime class)
#'   * `flights_planned`: the number of flights planned to be flown that day
#'   * `flights_flown`: the number of flights actually flown that day
#'   * `announcement`: the identifier of the official document announcing that fishing would be allowed that day

"meta"
