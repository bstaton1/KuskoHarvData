
rm(list = ls(all = TRUE))

# BTF environmental data file: work out solution for storing this in the package
inFile = "C:/Users/bstaton/Downloads/BTF Water Data.xlsx"

# extract the two data sheets: now in identical format
water_temp = openxlsx::read.xlsx(xlsxFile = inFile, sheet = "Temperature Historical", startRow = 4, detectDates = TRUE, na.strings = "n/a")
water_clar = openxlsx::read.xlsx(xlsxFile = inFile, sheet = 1, startRow = 3, detectDates = TRUE, na.strings = "n/a")

# function to prepare one of the data sets: either water clarity or temperature
prep_btf_env_data = function(dat) {

  # get the name of the variable based on the name of the object passed to dat argument
  var_name = as.character(as.list(sys.call())$dat)

  # fix column names
  colnames(dat) = tolower(colnames(dat))

  # format date column as a date
  dat$date = lubridate::as_date(dat$date)

  # reformat to long
  dat = reshape2::melt(dat, id.vars = "date", value.name = var_name, variable.name = "year")

  # fix the date column
  dat$year = as.numeric(as.character(dat$year))
  lubridate::year(dat$date) = dat$year

  # order rows
  dat = dat[order(dat$date),]

  # drop the year column, no longer needed since it is part of the date now
  dat = dat[,-which(colnames(dat) == "year")]

  # return output
  return(dat)
}

# prepare the btf water data for all years
btf_env_data_master = merge(
  prep_btf_env_data(dat = water_clar),
  prep_btf_env_data(dat = water_temp),
  by = "date", all = TRUE
)

# keep only relevant years
btf_env_data_master = subset(btf_env_data_master, lubridate::year(date) %in% 2016:2021)

# remove rownames
rownames(btf_env_data_master) = NULL

# export the data set
save(btf_env_data_master, file = "data/btf_water_data_master.rda")
