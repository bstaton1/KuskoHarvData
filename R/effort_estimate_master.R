#' Compiled Effort Estimates
#'
#' Data set containing all compiled estimates of the number of drift gillnet trips
#'   that occurred in each drift gillnet subsistence fishery opener, as estimated by
#'   the Lower Kuskokwim River In-season Subsistence Salmon Harvest Monitoring Program.
#'
#' @format See `vignette("datasets", package = "KuskoHarvData")`.
#' @note This data set will be updated automatically when adding new interview and flight data,
#'     see Steps 3 and 6 in `vignette("updating-data", package = "KuskoHarvData")`.
#' @source The number of trips is estimated by combining aerial boat counts
#'     (found in `data("flight_data_master", package = "KuskoHarvData"`) and
#'     access point completed trip interviews (found in `data("interview_data_all")`).
#'     The estimator is described in Staton et al. (In Review).
#'

"effort_estimate_master"
