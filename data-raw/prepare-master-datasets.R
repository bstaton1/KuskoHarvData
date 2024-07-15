# THIS SCRIPT COMBINES ALL RAW DATA FILES INTO MASTER DATA SETS AND PRODUCES HARVEST/EFFORT ESTIMATES
# FOUR FILES TOTAL:
# interview_data_all, flight_data_all
# harv_est_all, effort_est_all

# clear the workspace
rm(list = ls(all = TRUE))

# extract the names of all openers with data
dirs = dir("data-raw", full.names = TRUE, pattern = "_[0-9][0-9]$")

# create a data directory in package if it doesn't exist already
if (!dir.exists("data")) dir.create("data")

##### PART 1: COMPILE RAW DATA INTO MASTER DATA SETS TO BE INCLUDED WITH PACKAGE #####

# containers
interview_data_all = NULL
flight_data_all = NULL

# print a message
cat("\nPreparing Raw Data Files into Master Data Sets\n")

# loop through openers
for (i in 1:length(dirs)) {

  # print a progress message
  cat("\r  Opener: ", basename(dirs[i]), " (", stringr::str_pad(i, width = nchar(length(dirs)), pad = " "), "/", length(dirs), ")", sep = "")

  # extract and categorize file names for this opener
  files = list.files(dirs[i], full.names = TRUE)
  interview_files = files[stringr::str_detect(files, "ADFG|BBH|CBM|FC")]
  flight_file = files[stringr::str_detect(files, "Flight")]

  # prepare raw interview data files for this opener
  interview_data = suppressWarnings({
    KuskoHarvEst::prepare_interviews(
      input_files = interview_files,
      include_salmon = c("chinook", "chum", "sockeye"),
      include_nonsalmon = "none",
      include_village = TRUE,
      include_goals = FALSE
    )
  })

  # add a UID variable to identify which opener the data came from
  interview_data = cbind(UID = basename(dirs[i]), interview_data)

  # prepare raw flight data files for this opener: treat a bit different if missing
  flight_raw = read.csv(flight_file)
  if (all(is.na(flight_raw$start))) {
    flight_data = KuskoHarvEst::prepare_flights(flight_file)
    flight_data$start_time = flight_data$end_time = KuskoHarvUtils::combine_datetime(flight_raw$date[1], "0:00")
  } else {
    flight_data = KuskoHarvEst::prepare_flights(flight_file)
  }

  # discard D2 counts if present
  flight_data = flight_data[,!stringr::str_detect(colnames(flight_data), "D2")]

  # add a UID variable to identify which opener the data came from
  flight_data = cbind(UID = basename(dirs[i]), flight_data)

  # combine prepared data for this opener with data from other openers
  interview_data_all = rbind(interview_data_all, interview_data)
  flight_data_all = rbind(flight_data_all, flight_data)
}

# remove information about set nets
interview_data_all = subset(interview_data_all, gear == "drift"); rownames(interview_data_all) = NULL
flight_data_all = flight_data_all[,-which(stringr::str_detect(colnames(flight_data_all), "_set"))]

# remove information about geographic stratum D2
interview_data_all = subset(interview_data_all, stratum != "D2"); rownames(interview_data_all) = NULL

# export these data objects
# when package is installed, these are accessible using e.g., data(flight_data_all)
save(flight_data_all, file = "data/flight_data_all.rda")
save(interview_data_all, file = "data/interview_data_all.rda")
cat("\n  Output File Saved: data/flight_data_all.rda")
cat("\n  Output File Saved: data/interview_data_all.rda")

##### PART 2: OBTAIN HARVEST AND EFFORT ESTIMATES #####

# extract the unique IDs of all openers
UIDs = unique(interview_data_all$UID)

# print a message
cat("\nRecompiling Harvest and Effort Estimates")
cat("\n  (**This will take several minutes to run**)\n")

# containers
effort_est_all = NULL
harv_est_all = NULL

# loop through openers and generate harvest and effort estimates for each
starttime = Sys.time()
for (i in 1:length(UIDs)) {

  # print a progress message
  cat("\r  Opener: ", UIDs[i], " (", stringr::str_pad(i, width = nchar(length(UIDs)), pad = " "), "/", length(UIDs), ")", sep = "")

  # subset flight/interview data for this opener
  flight_data_sub = subset(flight_data_all, UID == UIDs[i])
  interview_data_sub = subset(interview_data_all, UID == UIDs[i])

  # produce effort estimate for this opener
  effort_info = KuskoHarvEst::estimate_effort(
    interview_data = interview_data_sub,
    flight_data = flight_data_sub,
    gear = "drift", method = "dbl_exp"
  )

  # combine effort estimates with those from other openers
  tmp = c(effort_info$effort_est_stratum, total = effort_info$effort_est_total)
  tmp = data.frame(date = unique(lubridate::date(flight_data_sub$start_time)), stratum = names(tmp), estimate = unname(tmp))
  effort_est_all = rbind(effort_est_all, tmp); rm(tmp)

  # obtain bootstrap harvest estimates
  boot_out = KuskoHarvEst::bootstrap_harvest(
    interview_data = interview_data_sub,
    effort_info = effort_info,
    gear = "drift",
    n_boot = 1000,
    stratify_interviews = TRUE
  )

  # summarize bootstrap samples by species and stratum
  for (spp in c("chinook", "chum", "sockeye", "total")) {
    for (strat in c("A", "B", "C", "D1", "total")) {
      # extract the bootstrap samples for this species/stratum combo
      boot_samples = subset(boot_out, stratum == strat)[,spp]

      # calculate and round the summaries
      tmp = c(mean = mean(boot_samples, na.rm = TRUE), sd = sd(boot_samples, na.rm = TRUE),
              lwr95 = unname(quantile(boot_samples, 0.025, na.rm = TRUE)), upr95 = unname(quantile(boot_samples, 0.975, na.rm = TRUE)))
      tmp[tmp == "NaN"] = NA
      tmp = round(tmp)

      # build data frame and combine with other estimates
      tmp = data.frame(date = unique(na.omit(lubridate::date(interview_data_sub$trip_start))), species = spp, stratum = strat, quantity = names(tmp), estimate = unname(tmp))
      harv_est_all = rbind(harv_est_all, tmp); rm(tmp)
    }
  }
}
stoptime = Sys.time()
cat("\n  Estimation Time Elapsed:", format(round(stoptime - starttime, 2)))

# export these data objects
# when package is installed, these are accessible using e.g., data(flight_data_all)
save(effort_est_all, file = "data/effort_est_all.rda")
save(harv_est_all, file = "data/harv_est_all.rda")
cat("\n  Output File Saved: data/effort_est_all.rda")
cat("\n  Output File Saved: data/harv_est_all.rda")
