# THIS SCRIPT FORMATS THE RAW META DATA FILE AND SAVES IT AS A DATA SET TO EXPORT

# print a message
cat("\nProcessing Opener Meta Data")

# create a data directory in package if it doesn't exist already
if (!dir.exists("data")) dir.create("data")

# load the meta-data file
openers_all = read.csv("data-raw/opener-metadata.csv")

# format start and end times for each opener
openers_all$start = KuskoHarvUtils::combine_datetime(openers_all$date, openers_all$start_time)
openers_all$end = KuskoHarvUtils::combine_datetime(openers_all$date, openers_all$end_time)

# re-order and keep only relevant columns
openers_all = openers_all[,c("start", "end", "flights_planned", "flights_flown", "announcement")]

# save the output
save(openers_all, file = "data/openers_all.rda")
cat("\n  Output File Saved: data/openers_all.rda")
