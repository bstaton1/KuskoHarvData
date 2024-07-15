#' Prepare a data set containing response variables for regression modeling
#'
#' Extracts total effort, species composition, and catch rate data from historical
#' openers, intended for fitting in regression models.
#'
#' @param dates Object of class `"POSIXct/POSIXt"`; vector of historical fishing dates to include.
#'   If `NULL` (the default) all dates included in the meta data set (`?KuskoHarvData::openers_all`) will be included.
#' @param comp_species Character; vector specifying the species to calculate proportional contribution for.
#'   Accepted options are any combinations of `"chinook"`, `"chum"`, and `"sockeye"`.
#' @param cpt_species Character; a vector specifying the species to calculate catch rate (catch/trip) for.
#'   Accepted options are any combinations of `"chinook"`, `"chum"`, `"sockeye"`, and `"total"`.
#' @param include_transformed Logical; if `TRUE` (the default), additional columns will be returned on a transformed scale.
#'   Effort and catch rate variables will be log-transformed and composition variables will be logit-transformed.
#' @return Data frame with rows for individual dates and columns for date, effort, and composition/catch rate for the requested species.
#'   All values are calculated for drift nets only, using the mean harvest estimates, and geographic strata A, B, C, and D1..

prepare_response_vars = function(dates = NULL, comp_species = c("chinook", "chum", "sockeye"), cpt_species = "total", include_transformed = TRUE) {

  # load the data
  data("harv_est_all", package = "KuskoHarvData", envir = environment())
  data("effort_est_all", package = "KuskoHarvData", envir = environment())

  # rename for shorthand
  H_ests = harv_est_all
  E_ests = effort_est_all

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

  # perform transformations if requested
  if (include_transformed) {

    # extract the date and log-transform effort
    t_response = data.frame(
      date = response$date,
      log_effort = log(response$effort)
    )

    # extract the variable names of all catch rate variables
    cpt_vars = colnames(response)[stringr::str_detect(colnames(response), "cpt")]

    # extract the variable names of all species composition variables
    comp_vars = colnames(response)[stringr::str_detect(colnames(response), "comp")]

    # create a data frame with log-transformed catch rate variables
    t_cpt = data.frame(log(response[,cpt_vars])); colnames(t_cpt) = paste0("log_", cpt_vars)

    # create a data frame with logit-transformed composition variables
    t_comp = data.frame(response[,comp_vars])
    t_comp = as.data.frame(apply(t_comp, 2, qlogis))
    colnames(t_comp) = paste0("logit_", comp_vars)

    # combine these transformed variables into one data frame
    t_response = cbind(t_response, t_cpt, t_comp)

    # combine transformed variables with non-transformed variables
    response = merge(response, t_response, by = "date")
  }

  # return the response data set
  return(response)
}

#' Prepare a data set containing predictor variables for regression modeling
#'
#' Quickly summarizes various date/time and Bethel Test Fishery summaries,
#' intended for fitting in regression models.
#'
#' @inheritParams prepare_response_vars
#' @return Data frame with rows for individual dates and columns for:
#'   * `date`: the date of the opener
#'   * `year`: the year of the opener
#'   * `day`: days past May 31st in the year of the opener (see [KuskoHarvUtils::to_days_past_may31()])
#'   * `hours_open`: the number of hours fishing was allowed that day
#'   * `fished_yesterday`: `TRUE` if drift gillnet fishing occurred the previous day
#'   * `weekend`: `TRUE` if the fishing day occurred on Saturday or Sunday
#'   * `p_before_noon`: fraction of the open hours that occurred before noon that day
#'   * `total_btf_cpue`: daily catch-per-unit-effort from the Bethel Test Fishery, averaged over a three day period where `date` is the second day
#'   * `chinook_btf_comp`: daily proportional composition of Chinook salmon from the Bethel Test Fishery, averaged over a three day period where `date` is the second day
#'   * `chum_btf_comp`: daily proportional composition of chum salmon from the Bethel Test Fishery, averaged over a three day period where `date` is the second day
#'   * `sockeye_btf_comp`: daily proportional composition of sockeye salmon from the Bethel Test Fishery, averaged over a three day period where `date` is the second day
#'   * `mean_temp`: daily average air temperature, in degrees Fahrenheit
#'   * `mean_relh`: daily average percent relative humidity
#'   * `precip`: total daily precipitation, in inches
#' @note All Bethel Test Fishery variables obtained using [KuskoHarvData::summarize_btf()].

prepare_predictor_vars = function(dates = NULL) {

  ### PREDICTOR DATA TYPE #1: BASED ON META-DATA ONLY ###

  # load the meta data
  data("openers_all", package = "KuskoHarvData", envir = environment())

  # start the output object with the date
  out = data.frame(date = lubridate::date(openers_all$start))

  # add a year variable
  out$year = lubridate::year(out$date)

  # determine days past may 31st
  out$day = KuskoHarvUtils::to_days_past_may31(out$date)

  # determine the duration of allowed fishing that day
  out$hours_open = ceiling(as.numeric(lubridate::as.period(lubridate::interval(openers_all$start, openers_all$end)), units = "hours"))

  # determine if drift fishing occurred the previous day
  # e.g., if the order of days open is 6/12 12:00-23:59; 6/16 12:00-23:59; 6/17 0:00-12:00, then 6/17 is a not first day
  out$fished_yesterday = logical(nrow(out))
  for (d in 2:nrow(out)) {
    if (lubridate::date(openers_all$start[d]) == lubridate::date(openers_all$start[d-1]) + 1) {
      out$fished_yesterday[d] = TRUE
    }
  }

  # determine if the fishing day is a weekend day
  out$weekend = lubridate::wday(out$date, label = TRUE) %in% c("Sat", "Sun")

  # determine the fraction of the fishing period before noon
  noon = openers_all$start; lubridate::hour(noon) = 12; lubridate::minute(noon) = 0; lubridate::second(noon) = 0
  hrs_before_noon = as.numeric(lubridate::as.period(lubridate::interval(openers_all$start, noon)), units = "hours")
  hrs_before_noon[hrs_before_noon < 0] = 0
  out$p_before_noon = hrs_before_noon/out$hours_open

  ### PREDICTOR DATA TYPE #2: BTF-BASED QUANTITIES ###
  out$total_btf_cpue = sapply(out$date, function(d) summarize_btf(d, "total_cpue", plus_minus = 1))
  out$chinook_btf_comp = sapply(out$date, function(d) summarize_btf(d, "chinook_comp", plus_minus = 1))
  out$chum_btf_comp = sapply(out$date, function(d) summarize_btf(d, "chum_comp", plus_minus = 1))
  out$sockeye_btf_comp = sapply(out$date, function(d) summarize_btf(d, "sockeye_comp", plus_minus = 1))

  ### PREDICTOR DATA TYPE #3: WEATHER-BASED QUANTITIES ###

  # load the weather data
  data("weather_data_master", package = "KuskoHarvData", envir = environment())

  # keep only dates that are within the harvest data
  weather_dat = weather_data_master[weather_data_master$date %in% out$date,]

  # keep only the average temperature, relh, and precipitation
  weather_dat = weather_dat[,c("date", "mean_temp", "mean_relh", "precip", "mean_Nwind", "mean_Ewind", "mean_wind", "max_gust")]

  # combine with other variables
  out = merge(out, weather_dat, by = "date")

  ### RETURN ONLY REQUESTED DATES
  if (is.null(dates)) {
    keep_dates = unique(lubridate::date(openers_all$start))
  } else {
    keep_dates = dates
  }
  out = subset(out, date %in% keep_dates)

  return(out)
}

#' Prepare a data set containing predictor and response variables for regression modeling
#'
#' A wrapper around [prepare_predictor_vars()] and [prepare_response_vars()] for one-line
#' regression data preparation.
#'
#' @inheritParams prepare_response_vars
#' @param na.omit Logical; if `TRUE` (default), any rows with an `NA` value for any variable will be discarded.
#' @param ... Optional arguments passed to [prepare_response_vars()]
#' @return Data frame with rows for individual dates and columns for several variables to be used in regression modeling.
#'   See [prepare_predictor_vars()] and [prepare_response_vars()] for variable definitions.
#'   In addition to those variables, there is also a `period` variable (see [KuskoHarvUtils::get_period()]).
#' @export

prepare_regression_data = function(dates = NULL, na.omit = TRUE, ...) {

  # prepare predictor variables
  predictors = prepare_predictor_vars(dates = dates)

  # prepare response variables
  responses = prepare_response_vars(dates = dates, ...)

  # merge them by the date
  out = merge(responses, predictors, by = "date")

  # drop out NA rows if requested
  if (na.omit) {
    na_rows = unique(unname(unlist(apply(out, 2, function(x) which(is.na(x))))))
    out = out[-na_rows,]
    rownames(out) = NULL
  }

  # obtain the period of the season each record occurred in
  out = cbind(period = KuskoHarvUtils::get_period(out$day), out)

  # obtain total harvest by species
  out$chinook_harv = round(out$effort * out$total_cpt * out$chinook_comp)
  out$chum_harv = round(out$effort * out$total_cpt * out$chum_comp)
  out$sockeye_harv = round(out$effort * out$total_cpt * out$sockeye_comp)

  # return the output data set
  return(out)
}
