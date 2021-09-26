# THIS SCRIPT FORMATS THE RAW META DATA FILE AND SAVES IT AS A DATA SET TO EXPORT

# load the meta-data file
meta = read.csv("data-raw/opener-metadata.csv")

# format start and end times for each opener
meta$start = KuskoHarvEst:::combine_datetime(meta$date, meta$start_time)
meta$end = KuskoHarvEst:::combine_datetime(meta$date, meta$end_time)

# re-order and keep only relevant columns
meta = meta[,c("start", "end", "flights_planned", "flights_flown", "announcement")]

# save the output
save(meta, file = "data/meta.rda")
