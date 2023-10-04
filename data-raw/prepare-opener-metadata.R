# THIS SCRIPT FORMATS THE RAW META DATA FILE AND SAVES IT AS A DATA SET TO EXPORT

# print a message
cat("\nProcessing Opener Meta Data")

# create a data directory in package if it doesn't exist already
if (!dir.exists("data")) dir.create("data")

# load the meta-data file
meta = read.csv("data-raw/opener-metadata.csv")

# format start and end times for each opener
meta$start = KuskoHarvUtils::combine_datetime(meta$date, meta$start_time)
meta$end = KuskoHarvUtils::combine_datetime(meta$date, meta$end_time)

# re-order and keep only relevant columns
meta = meta[,c("start", "end", "flights_planned", "flights_flown", "announcement")]

# save the output
save(meta, file = "data/meta.rda")
cat("\n  Output File Saved: data/meta.rda")
