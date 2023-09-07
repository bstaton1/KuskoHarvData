# THIS SCRIPT EXECUTES ALL SCRIPTS THAT COMPILE/PREPARE DATA SETS FOR EXPORTING

{

  # run the opener meta data script
  source("data-raw/prepare-opener-metadata.R")

  # run the script to prepare master interview/flight data sets and recompile all harvest/effort estimates
  source("data-raw/prepare-master-datasets.R")

  # run the script to prepare Bethel Test Fishery Data
  source("data-raw/prepare-btf-data.R")

  # run the script to compile all weather data
  source("data-raw/prepare-weather-data.R")

}

