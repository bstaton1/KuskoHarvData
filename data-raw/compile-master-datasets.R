# THIS SCRIPT COMBINES ALL RAW DATA FILES INTO MASTER DATA SETS AND PRODUCES HARVEST/EFFORT ESTIMATES
# FOUR FILES TOTAL:
# interview_data_master, flight_data_master
# harvest_estimate_master, effort_estimate_master

# clear the workspace
rm(list = ls(all = TRUE))

# extract the names of all openers with data
dirs = dir("data-raw", full.names = TRUE, pattern = "_[0-9][0-9]$")

# create a data directory in package if it doesn't exist already
if (!dir.exists("data")) dir.create("data")

##### PART 1: COMPILE RAW DATA INTO MASTER DATA SETS TO BE INCLUDED WITH PACKAGE #####

# containers
interview_data_master = NULL
flight_data_master = NULL

# print a message
cat("\nProcessing Raw Data Files into Master Data Sets\n")

# loop through openers
for (i in 1:length(dirs)) {

  # print a progress message
  cat("\rOpener: ", basename(dirs[i]), " (", stringr::str_pad(i, width = nchar(length(dirs)), pad = " "), "/", length(dirs), ")", sep = "")

  # extract and categorize file names for this opener
  files = list.files(dirs[i], full.names = TRUE)
  interview_files = files[stringr::str_detect(files, "ADFG|BBH|CBM|FC|LE")]
  flight_file = files[stringr::str_detect(files, "Flight")]

  # prepare raw interview data files for this opener
  interview_data = suppressWarnings(KuskoHarvEst::prepare_interviews(interview_files))

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

  # add a UID variable to identify which opener the data came from
  flight_data = cbind(UID = basename(dirs[i]), flight_data)

  # combine prepared data for this opener with data from other openers
  interview_data_master = rbind(interview_data_master, interview_data)
  flight_data_master = rbind(flight_data_master, flight_data)
}

# remove information about set nets
interview_data_master = subset(interview_data_master, gear == "drift"); rownames(interview_data_master) = NULL
flight_data_master = flight_data_master[,-which(stringr::str_detect(colnames(flight_data_master), "_set"))]

# export these data objects
# when package is installed, these are accessible using e.g., data(flight_data_master)
save(flight_data_master, file = "data/flight_data_master.rda")
save(interview_data_master, file = "data/interview_data_master.rda")

##### PART 2: OBTAIN HARVEST AND EFFORT ESTIMATES

# extract the unique IDs of all openers
UIDs = unique(interview_data_master$UID)

# print a message
cat("\nEstimating Harvest and Effort Estimates from Master Data Sets\n")
cat("(This will take several minutes to run)\n")

# containers
effort_estimate_master = NULL
harvest_estimate_master = NULL

# loop through openers and generate harvest and effort estimates for each
starttime = Sys.time()
for (i in 1:length(UIDs)) {

  # print a progress message
  cat("\rOpener: ", UIDs[i], " (", stringr::str_pad(i, width = nchar(length(UIDs)), pad = " "), "/", length(UIDs), ")", sep = "")

  # subset flight/interview data for this opener
  flight_data_sub = subset(flight_data_master, UID == UIDs[i])
  interview_data_sub = subset(interview_data_master, UID == UIDs[i])

  # produce effort estimate for this opener
  effort_info = KuskoHarvEst::estimate_effort(
    interview_data = interview_data_sub,
    flight_data = flight_data_sub,
    gear = "drift", method = "dbl_exp"
  )

  # combine effort estimates with those from other openers
  tmp = c(effort_info$effort_est_stratum, total = effort_info$effort_est_total)
  tmp = data.frame(date = unique(lubridate::date(flight_data_sub$start_time)), stratum = names(tmp), estimate = unname(tmp))
  effort_estimate_master = rbind(effort_estimate_master, tmp); rm(tmp)

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
      harvest_estimate_master = rbind(harvest_estimate_master, tmp); rm(tmp)
    }
  }
}
stoptime = Sys.time()
cat("\nEstimation Time Elapsed:", format(round(stoptime - starttime, 2)))

# export these data objects
# when package is installed, these are accessible using e.g., data(flight_data_master)
save(effort_estimate_master, file = "data/effort_estimate_master.rda")
save(harvest_estimate_master, file = "data/harvest_estimate_master.rda")
