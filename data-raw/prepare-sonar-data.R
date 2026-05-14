# THIS SCRIPT PREPARES THE RAW SONAR COUNT DATA FILES FOR USE BY OTHER FUNCTIONS IN THE PACKAGE
# IT SAVES A DATA SET CALLED 'sonar_data_all' THAT IS SUPPLIED BY THIS PACKAGE

# print a message
cat("\nPreparing Sonar Data Set")

# create a data directory in package if it doesn't exist already
if (!dir.exists("data")) dir.create("data")

# load in the raw sonar data files and combine into one data frame
dat = rbind(
  read.csv("data-raw/PUB Kusko Escapement Daily-Chinook.csv"),
  read.csv("data-raw/PUB Kusko Escapement Daily-Chum.csv"),
  read.csv("data-raw/PUB Kusko Escapement Daily-Sockeye.csv")
)

# keep only relevant columns
dat = dat[,c("Observation.Year", "Observation.Month.Day", "Species", "Fish.Count")]

# change the column names
colnames(dat) = c("year", "date", "species", "count")

# change species name to lower case
dat$species = tolower(dat$species)

# format the date variable and remove year variable
month = stringr::str_extract(dat$date, "^[:digit:]+")
day = stringr::str_extract(dat$date, "[:digit:]+$")
dat$date = lubridate::as_date(paste(dat$year, month, day, sep = "-"))
dat = dat[,-which(colnames(dat) == "year")]

# discard records before June 1 from all years
start_compare = paste(lubridate::year(dat$date), "06", "01", sep = "-")
dat = dat[dat$date >= start_compare,]

# discard records after August 24 from all years
end_compare = paste(lubridate::year(dat$date), "08", "24", sep = "-")
dat = dat[dat$date <= end_compare,]

# order the records by increasing date
dat = dat[order(dat$species, dat$date),]

# reset the rownames
rownames(dat) = NULL

# add cumulative count by looping over species and year
dat_new = NULL
for (s in unique(dat$species)) {
  for (y in unique(lubridate::year(dat$date))) {
    # extract data for this species and year
    dat_sub = subset(dat, species == s & lubridate::year(date) == y)

    # calculate ccpue
    dat_sub$ccount = cumsum(dat_sub$count)

    # combine with other years/species
    dat_new = rbind(dat_new, dat_sub)
  }
}
dat = dat_new; rm(dat_new)

# add a total species group, just sum up other species by date
dat_total = subset(dat, species == "chinook")
dat_total$species = "total"
dat_total$count = tapply(dat$count, dat$date, sum)
dat_total$ccount = tapply(dat$ccount, dat$date, sum)
dat = rbind(dat, dat_total)

# rename dat to sonar_data_all
sonar_data_all = dat; rm(dat)

# export these data objects
# when package is installed, this data set is accessible using data(sonar_data_all)
save(sonar_data_all, file = "data/sonar_data_all.rda")
cat("\n  Output File Saved: data/sonar_data_all.rda")
