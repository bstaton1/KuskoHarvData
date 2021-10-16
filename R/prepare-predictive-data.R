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

