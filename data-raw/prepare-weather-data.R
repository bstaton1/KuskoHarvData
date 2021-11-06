# THIS SCRIPT DOWNLOADS WEATHER DATA FROM THE BETHEL AIRPORT
# AND PREPARES THE HOURLY MEASUREMENTS INTO DAILY SUMMARIES
# IT SAVES A DATA SET CALLED 'weather_data_master' THAT IS SUPPLIED BY THIS PACKAGE

# determine which years to get weather data for
# include only years for which in-season harvest monitoring data are available
yr_range = sort(unique(as.numeric(substr(list.files("data-raw", pattern = "^[0-9]"), 1, 4))))

# loop through years and query PABE weather data for June and July
dat_list = lapply(yr_range, function(yr) {
  cat("\rDownloading PABE Weather Data:", yr)
  riem::riem_measures(
    station = "PABE",
    date_start = stringr::str_replace("YYYY-06-01", "YYYY", as.character(yr)),
    date_end = stringr::str_replace("YYYY-08-02", "YYYY", as.character(yr))
  )
})

# rbind the list elements
dat = do.call(rbind, dat_list)

# convert the time zone to AK
dat$valid = lubridate::with_tz(dat$valid, "US/Alaska")

# keep only records with in June and July
dat = subset(dat, lubridate::month(valid) %in% c(6, 7))

# calculate daily summaries: mean temp, max temp, min_temp, mean relative humidity, total daily precipitation
# there are many other variables that could be summarized
mean_temp = tapply(dat$tmpf, lubridate::date(dat$valid), mean, na.rm = TRUE)
max_temp = tapply(dat$tmpf, lubridate::date(dat$valid), max, na.rm = TRUE)
min_temp = tapply(dat$tmpf, lubridate::date(dat$valid), min, na.rm = TRUE)
mean_relh = tapply(dat$relh, lubridate::date(dat$valid), min, na.rm = TRUE)
precip = tapply(dat$p01i, lubridate::date(dat$valid), sum, na.rm = TRUE)

# combine these into a data frame
weather_data_master = data.frame(
  date = lubridate::as_date(names(mean_temp)),
  mean_temp = mean_temp,
  min_temp = min_temp,
  max_temp = max_temp,
  mean_relh = mean_relh,
  precip = precip
)

# remove rownames
rownames(weather_data_master) = NULL

# export the dataset
save(weather_data_master, file = "data/weather_data_master.rda")
