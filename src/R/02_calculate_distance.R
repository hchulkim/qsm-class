# maintainer: Hyoungchul Kim
# date: 2025-09-01
# purpose: calculate distance between home and workplace

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, tigris, sf, dplyr, argparse, yaml, osrm)

# set working directory
# here::i_am("src/R/02_calculate_distance.R")

parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- yaml.load_file(args$input)

# load the cleaned data
data <- fread(here("input", "temp", input_yaml$tract_tract$main),
    colClasses = list(character = c("h_tract", "w_tract"))
)

# load the census tracts
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020)

# Calculate all pairwise distances between tracts (centroid to centroid)
distance_matrix <- st_distance(st_centroid(tracts), st_centroid(tracts))

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

# ## Let's try to use osrm to calculate the travel time
# data_osrm <- tracts[1:2, ] |> mutate(point = st_centroid(geometry))

# travel_time <- osrmTable(data_osrm, osrm.server = "http://localhost:5000", loc = geometry)

# pharmacy <- st_read("system.file())


# download the data
fwrite(data_with_distance, here("input", "temp", "philly_od_tract_tract_2022_with_distance.csv.gz"))
