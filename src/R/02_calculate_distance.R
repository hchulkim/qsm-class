# maintainer: Hyoungchul Kim
# date: 2025-09-01
# purpose: calculate distance between home and workplace

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, tigris, sf, dplyr)

# set working directory
here::i_am("src/R/02_calculate_distance.R")

# load the cleaned data
data <- fread(here("input", "temp", "philly_od_tract_tract_2022.csv.gz"),
    colClasses = list(character = c("h_tract", "w_tract"))
)

# load the census tracts
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020)

# Calculate all pairwise distances between tracts
distance_matrix <- st_distance(tracts, tracts)

# Convert to data.table for easier merging
tract_ids <- tracts$GEOID
distance_dt <- data.table(
    origin_tract = rep(tract_ids, each = length(tract_ids)),
    destination_tract = rep(tract_ids, length(tract_ids)),
    distance_meters = as.numeric(distance_matrix)
)

# Merge with your bilateral data
data_with_distance <- merge(
    data,
    distance_dt,
    by.x = c("h_tract", "w_tract"),
    by.y = c("origin_tract", "destination_tract"),
    all.x = TRUE
)

# Convert distance to kilometers
data_with_distance[, distance_km := distance_meters / 1000]

# create travel time between locations?

# download the data
fwrite(data_with_distance, here("input", "temp", "philly_od_tract_tract_2022_with_distance.csv.gz"))
