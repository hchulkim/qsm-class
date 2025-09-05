# maintainer: Hyoungchul Kim
# date: 2025-09-04
# purpose: calculate distance between home and workplace for ii pairs

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, tigris, sf, dplyr, argparse, yaml)

# set working directory
#here::i_am("src/R/05_calculate_distance_ii.R")

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

# first solution

# for ii pairs, we will use the minimum distance between the centroid and the polygon edge
tracts_points <- st_centroid(tracts)

# Calculate distance from each centroid to the boundary of its own polygon
# We need to get the boundary/edge of each polygon first
tracts_boundary <- st_boundary(tracts)

# For ii pairs, we only need the diagonal elements (centroid to its own boundary)
# Calculate distance from each centroid to its own polygon boundary
distance_ii <- st_distance(tracts_points, tracts_boundary, by_element = TRUE)

# Create a data.table for ii pairs (same tract)
distance_dt_ii <- data.table(
    origin_tract = tract_ids,
    destination_tract = tract_ids,
    distance_meters = as.numeric(distance_ii)
)


# Merge with your bilateral data
data_with_distance <- merge(
    data,
    distance_dt,
    by.x = c("h_tract", "w_tract"),
    by.y = c("origin_tract", "destination_tract"),
    all.x = TRUE
)

# For ii pairs (same tract), use the centroid-to-boundary distance
ii_pairs <- data_with_distance[h_tract == w_tract]
if (nrow(ii_pairs) > 0) {
    # Merge ii pairs with their specific distances
    ii_pairs <- merge(
        ii_pairs[, .(h_tract, w_tract)],
        distance_dt_ii,
        by.x = c("h_tract"),
        by.y = c("origin_tract"),
        all.x = TRUE
    )

    # Update the main dataset with ii pair distances
    data_with_distance[h_tract == w_tract, distance_meters := ii_pairs$distance_meters]
}

# Convert distance to kilometers
data_with_distance[, distance_km := distance_meters / 1000]


# download the data
fwrite(data_with_distance, here("input", "temp", "philly_od_tract_tract_2022_with_distance_ii_solution1.csv.gz"))


# second solution
ii_pairs[, distance_km := distance_meters / 1000]

ii_pairs <- ii_pairs[h_tract == w_tract]

data_with_distance <- merge(
    data_with_distance,
    ii_pairs[, .(h_tract, h_distance_km = distance_km)],
    by.x = c("h_tract"),
    by.y = c("h_tract"),
    all.x = TRUE
)

data_with_distance <- merge(
    data_with_distance,
    ii_pairs[, .(w_tract, w_distance_km = distance_km)],
    by.x = c("w_tract"),
    by.y = c("w_tract"),
    all.x = TRUE
)

data_with_distance[w_tract != h_tract, distance_km := distance_km + h_distance_km + w_distance_km]

# save data
fwrite(data_with_distance, here("input", "temp", "philly_od_tract_tract_2022_with_distance_ii_solution2.csv.gz"))
