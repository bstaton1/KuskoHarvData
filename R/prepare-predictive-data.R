#' Prepare a data set containing response variables for regression modeling
#'
#' Extracts total effort, species composition, and catch rate data from historical
#' fishing days for fitting in regression models.
#'
#' @param dates Datetime; a vector of historical fishing dates to include.
#'   If `NULL` (the default) all dates included in the meta data set will be included.
#' @param comp_species Character; a vector specifying the species to calculate proportional contribution for.
#'   Accepted options are any combinations of `"chinook"`, `"chum"`, and `"sockeye"`
#' @param cpt_species Character; a vector specifying the species to calculate catch rate (catch/trip) for.
#'   Accepted options are any combinations of `"chinook"`, `"chum"`, `"sockeye"`, and `"total"`.
#' @return A data frame with rows for individual dates and columns for date, effort, and composition/catch rate for the requested species.
#'   All values are calculated for drift nets only, using the mean harvest estimates, and all geographic strata.
#' @export

prepare_response_vars = function(dates = NULL, comp_species = "chinook", cpt_species = "total") {

  # load the data
  data("harvest_estimate_master", package = "KuskoHarvData", envir = environment())
  data("effort_estimate_master", package = "KuskoHarvData", envir = environment())

  # rename for shorthand
  H_ests = harvest_estimate_master
  E_ests = effort_estimate_master

  # handle dates if not specified
  if (is.null(dates)) {
    keep_dates = unique(H_ests$date)
  } else {
    keep_dates = dates
  }

  # extract total effort estimates
  eff = E_ests[E_ests$stratum == "total",]
  eff = eff[,-which(colnames(eff) == "stratum")]
  colnames(eff) = c("date", "effort")

  # extract chinook and total salmon harvest by opener, filtered by other characteristics
  harv_sub = H_ests[H_ests$date %in% keep_dates & H_ests$stratum == "total" & H_ests$quantity == "mean" & H_ests$species %in% c(cpt_species, comp_species, "total"),]

  # re-order rows
  harv_sub = harv_sub[order(harv_sub$species, harv_sub$date),]

  # calculate proportional composition
  harv_sub$comp = unlist(tapply(harv_sub$estimate, harv_sub$species, function(x) x/harv_sub$estimate[harv_sub$species == "total"]))

  # calculate catch per trip
  harv_sub$cpt = unlist(tapply(harv_sub$estimate, harv_sub$species, function(x) x/eff$effort))

  # make two wide-format data frames, one for harvest and one for composition
  cpt = reshape2::dcast(subset(harv_sub, species %in% cpt_species), date ~ species, value.var = "cpt")
  comp = reshape2::dcast(subset(harv_sub, species %in% comp_species), date ~ species, value.var = "comp")

  # update column names so unique when merged
  colnames(cpt)[-1] = paste0(colnames(cpt)[-1], "_cpt")
  colnames(comp)[-1] = paste0(colnames(comp)[-1], "_comp")

  # merge harvest-based and effort response variables
  response = merge(eff, merge(cpt, comp, by = "date"), by = "date")

  # return the response data set
  return(response)
}

#' Prepare a data set containing predictor variables for regression modeling
#'
#' Quickly summarizes various date/time and Bethel Test Fishery summaries
#' for fitting in regression models.
#'
#' @param dates Datetime; a vector of historical fishing dates to include.
#'   If `NULL` (the default) all dates included in the meta data set will be included.
#' @return A data frame with rows for individual dates and columns for:
#'   * `date`: the date of the fishing day
#'   * `year`: the year of the fishing day
#'   * `day`: days past May 31st in the year of fishing
#'   * `hours_open`: the number of hours that day fishing was allowed that day
#'   * `not_first_day`: `TRUE` if the day is not the first day of fishing in a consecutive set of fishing days
#'   * `weekend`: `TRUE` if the fishing day occurred on Saturday or Sunday
#'   * `p_before_noon`: fraction of the allowed fishing hours that occurred before noon that day
#'   * `total_btf_cpue`: daily catch-per-unit-effort from the Bethel Test Fishery, averaged over a three day period where `date` is the second day
#'   * `chinook_btf_comp`: daily proportional composition of Chinook salmon from the Bethel Test Fishery, averaged over a three day period where `date` is the second day
#' @export

prepare_predictor_vars = function(dates = NULL) {

  ### PREDICTOR DATA TYPE #1: BASED ON META-DATA ONLY ###

  # load the meta data
  data("meta", package = "KuskoHarvData", envir = environment())

  # start the output object with the date
  out = data.frame(date = lubridate::date(meta$start))

  # add a year variable
  out$year = lubridate::year(out$date)

  # determine days past may 31st
  ref_date = lubridate::as_datetime(paste0(lubridate::year(out$date), "-05-31"))
  out$day = floor(as.numeric(lubridate::as.period(lubridate::interval(ref_date, out$date)), units = "day"))

  # determine the duration of allowed fishing that day
  out$hours_open = ceiling(as.numeric(lubridate::as.period(lubridate::interval(meta$start, meta$end)), units = "hours"))

  # determine if the fishing day is not the first of the opener
  # e.g., if the order of days open is 6/12 12:00-23:59; 6/16 12:00-23:59; 6/17 0:00-12:00, then 6/17 is a not first day
  out$not_first_day = logical(nrow(out))
  for (d in 2:nrow(out)) {
    if(lubridate::date(meta$start[d]) == (lubridate::date(meta$start[d-1])+1) & lubridate::hour(meta$start[d]) == 0 & lubridate::minute(meta$start[d]) == 0) {
      out$not_first_day[d] = TRUE
    }
  }

  # determine if the fishing day is a weekend day
  out$weekend = lubridate::wday(out$date, label = TRUE) %in% c("Sat", "Sun")

  # determine the fraction of the fishing period before noon
  noon = meta$start; lubridate::hour(noon) = 12; lubridate::minute(noon) = 0; lubridate::second(noon) = 0
  hrs_before_noon = as.numeric(lubridate::as.period(lubridate::interval(meta$start, noon)), units = "hours")
  hrs_before_noon[hrs_before_noon < 0] = 0
  out$p_before_noon = hrs_before_noon/out$hours_open

  ### PREDICTOR DATA TYPE #2: BTF-BASED QUANTITIES ###
  out$total_btf_cpue = sapply(out$date, function(d) summarize_btf(d, "total_cpue", plus_minus = 1))
  out$chinook_btf_comp = sapply(out$date, function(d) summarize_btf(d, "chinook_comp", plus_minus = 1))

  ### PREDICTOR DATA TYPE #3: WEATHER-BASED QUANTITIES? ###

  ### RETURN ONLY REQUESTED DATES
  if (is.null(dates)) {
    keep_dates = unique(lubridate::date(meta$start))
  } else {
    keep_dates = dates
  }
  out = subset(out, date %in% keep_dates)

  return(out)
}