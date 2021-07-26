# clear the workspace
rm(list = ls(all = TRUE))

# set the necessary KuskoHarvEst options
options(soak_sd_cut = 3, net_length_cut = 350, catch_per_trip_cut = 0.1, central_fn = mean, pooling_threshold = 10)

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

  # prepare raw flight data files for this opener: treat a bit different if missing
  flight_raw = read.csv(flight_file)
  if (all(is.na(flight_raw$start))) {
    flight_data = KuskoHarvEst::prepare_flights(flight_file)
    flight_data$start_time = flight_data$end_time = KuskoHarvEst:::combine_datetime(flight_raw$date[1], "0:00")
  } else {
    flight_data = KuskoHarvEst::prepare_flights(flight_file)
  }

  # combine prepared data for this opener with data from other openers
  interview_data_master = rbind(interview_data_master, interview_data)
  flight_data_master = rbind(flight_data_master, flight_data)
}

# remove information about set nets
interview_data_master = subset(interview_data_master, gear == "drift"); rownames(interview_data_master) = NULL
flight_data_master = flight_data_master[,-which(stringr::str_detect(colnames(flight_data_master), "_set"))]

# export these data objects
# when package is installed, these are accessible using e.g., data(flight_data_master)
save(flight_data_master, file = "data/flight_data_master.Rdata")
save(interview_data_master, file = "data/interview_data_master.Rdata")

