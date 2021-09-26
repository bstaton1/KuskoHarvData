# THIS SCRIPT PREPARES THE RAW BTF CPUE DATA FILE FOR USE BY OTHER FUNCTIONS IN THE PACKAGE
# IT SAVES A DATA SET CALLED 'btf_master' THAT IS SUPPLIED BY THIS PACKAGE

# load in the raw BTF data
dat = read.csv("data-raw/PUB_Bethel Test Fish - Daily CPUE.csv")

# change the column names
colnames(dat) = c("date", "year", "cpue", "species")

# discard any records from years prior to 2016
dat = subset(dat, year >= 2016)

# change species name to lower case
dat$species = tolower(dat$species)

# remove any records of coho salmon
dat = subset(dat, species != "coho")

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

# reorder columns
dat = dat[,c("date", "species", "cpue")]

# add cumulative cpue by looping over species and year
dat_new = NULL
for (s in unique(dat$species)) {
  for (y in unique(lubridate::year(dat$date))) {
    # extract data for this species and year
    dat_sub = subset(dat, species == s & lubridate::year(date) == y)

    # calculate ccpue
    dat_sub$ccpue = cumsum(dat_sub$cpue)

    # combine with other years/species
    dat_new = rbind(dat_new, dat_sub)
  }
}
dat = dat_new; rm(dat_new)

# add a total species group, just sum up other species by date
dat_total = subset(dat, species == "chinook")
dat_total$species = "total"
dat_total$cpue = tapply(dat$cpue, dat$date, sum)
dat_total$ccpue = tapply(dat$ccpue, dat$date, sum)
dat = rbind(dat, dat_total)

# rename dat to btf_master
btf_master = dat; rm(dat)

# export these data objects
# when package is installed, this data set is accessible using data(btf_master)
save(btf_master, file = "data/btf_master.rda")
