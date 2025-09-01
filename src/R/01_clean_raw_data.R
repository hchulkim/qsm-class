# maintainer: Hyoungchul Kim
# date: 2025-08-29
# purpose: clean raw data

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils)

# set working directory
here::i_am("src/R/01_clean_raw_data.R")

# load main data and geography crosswalk
data <- fread(here("input", "pa_od_main_JT00_2022.csv.gz"),
    colClasses = list(character = c("w_geocode", "h_geocode"))
)
geography_walk <- fread(here("input", "pa_xwalk.csv.gz"),
    colClasses = list(character = c("tabblk2020"))
)

# use geography_walk to merge data and aggregated to census tract level
# add workplace
data <- merge(data, geography_walk[, .(tabblk2020, st, stusps, stname, cty, ctyname, trct, trctname, blklatdd, blklondd)], by.x = "w_geocode", by.y = "tabblk2020", all.x = TRUE)
setnames(data, c("st", "stusps", "stname", "cty", "ctyname", "trct", "trctname", "blklatdd", "blklondd"), c("w_state", "w_state_abbr", "w_state_name", "w_county", "w_county_name", "w_tract", "w_tract_name", "w_block_lat", "w_block_lon"))

# add home location
data <- merge(data, geography_walk[, .(tabblk2020, st, stusps, stname, cty, ctyname, trct, trctname, blklatdd, blklondd)], by.x = "h_geocode", by.y = "tabblk2020", all.x = TRUE)
setnames(data, c("st", "stusps", "stname", "cty", "ctyname", "trct", "trctname", "blklatdd", "blklondd"), c("h_state", "h_state_abbr", "h_state_name", "h_county", "h_county_name", "h_tract", "h_tract_name", "h_block_lat", "h_block_lon"))

# only keep philadelphia county
data <- data[w_county == 42101 & h_county == 42101]

# aggregate the data by tract-tract level
data <- data[, lapply(.SD, sum, na.rm = TRUE), by = .(w_tract, w_tract_name, h_tract, h_tract_name, w_county, h_county), .SDcols = patterns("^S")]


# save data
fwrite(data, here("input", "temp", "philly_od_tract_tract_2022.csv.gz"))
