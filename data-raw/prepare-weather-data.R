# THIS SCRIPT DOWNLOADS WEATHER DATA FROM THE BETHEL AIRPORT
# AND PREPARES THE HOURLY MEASUREMENTS INTO DAILY SUMMARIES
# IT SAVES A DATA SET CALLED 'PABE_data_all' THAT IS SUPPLIED BY THIS PACKAGE

# print a message
cat("\nPreparing Weather Data Set\n")

# create a data directory in package if it doesn't exist already
if (!dir.exists("data")) dir.create("data")

# determine which years to get weather data for
# include only years for which in-season harvest monitoring data are available
yr_range = sort(unique(as.numeric(substr(list.files("data-raw", pattern = "^[0-9]"), 1, 4))))

# loop through years and query PABE weather data for June and July
dat_list = lapply(yr_range, function(yr) {
  cat("\r  Downloading PABE Weather Data:", yr)
  riem::riem_measures(
    station = "PABE",
    date_start = stringr::str_replace("YYYY-06-01", "YYYY", as.character(yr)),
    date_end = stringr::str_replace("YYYY-08-31", "YYYY", as.character(yr))
  )
})

# rbind the list elements
dat = do.call(rbind, dat_list)

# convert the time zone to AK
dat$valid = lubridate::with_tz(dat$valid, "US/Alaska")

# keep only records with in June, July, and August
dat = subset(dat, lubridate::month(valid) %in% c(6, 7, 8))

# convert wind speed in knots to speed in miles per hour
# more readily accessible in-season
dat$smph = dat$sknt * 0.868976

# add wind variables: suggested by G. Decossas
# NWind: (+) winds from the north, (-) winds from south, magnitude implies wind strength
# EWind: (+) winds from the east, (-) winds from the west, magnitude implies wind strength
# These are vector legs of a right triangle, the hypotenuse is total wind speed
dat$Nwind = KuskoHarvUtils::get_Nwind(speed = dat$smph, angle = dat$drct, digits = 1)
dat$Ewind = KuskoHarvUtils::get_Ewind(speed = dat$smph, angle = dat$drct, digits = 1)

# gust is only reported if it is > 14knts (https://www.weather.gov/media/asos/aum-toc.pdf; sec 3.2.2.2a)
# convert all NA values to zero
dat$gust[is.na(dat$gust)] = 0

# calculate daily summaries: mean temp, max temp, min_temp, mean relative humidity, total daily precipitation
# there are many other variables that could be summarized
mean_temp = tapply(dat$tmpf, lubridate::date(dat$valid), mean, na.rm = TRUE)
max_temp = tapply(dat$tmpf, lubridate::date(dat$valid), max, na.rm = TRUE)
min_temp = tapply(dat$tmpf, lubridate::date(dat$valid), min, na.rm = TRUE)
mean_relh = tapply(dat$relh, lubridate::date(dat$valid), min, na.rm = TRUE)
precip = tapply(dat$p01i, lubridate::date(dat$valid), sum, na.rm = TRUE)
mean_Nwind = tapply(dat$Nwind, lubridate::date(dat$valid), mean, na.rm = TRUE)
mean_Ewind = tapply(dat$Ewind, lubridate::date(dat$valid), mean, na.rm = TRUE)
mean_wind = tapply(dat$smph, lubridate::date(dat$valid), mean, na.rm = TRUE)
max_gust = tapply(dat$gust, lubridate::date(dat$valid), max, na.rm = TRUE)

# combine these into a data frame
PABE_data_all = data.frame(
  date = lubridate::as_date(names(mean_temp)),
  mean_temp = mean_temp,
  min_temp = min_temp,
  max_temp = max_temp,
  mean_relh = mean_relh,
  precip = precip,
  mean_Nwind = mean_Nwind,
  mean_Ewind = mean_Ewind,
  mean_wind = mean_wind,
  max_gust = max_gust
)

# remove rownames
rownames(PABE_data_all) = NULL

# export the dataset
save(PABE_data_all, file = "data/PABE_data_all.rda")
cat("\nOutput File Saved: data/PABE_data_all.rda\n")
