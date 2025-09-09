# maintainer: Hyoungchul Kim
# date: 2025-09-06
# purpose: create market access variable using fixed point algorithm

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, argparse, yaml, sf, tigris, kableExtra)


parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- read_yaml(args$input)
# input_yaml <- read_yaml(here("input.yml"))

# load the data
ek <- fread(here("input", "temp", input_yaml$market_access$ek))[, estimate]


# load the cleaned data
data <- fread(here("input", "temp", input_yaml$tract_tract$main),
    colClasses = list(character = c("h_tract", "w_tract"))
)

# load the census tracts
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020)

full_data <- expand.grid(
    w_tract = tracts$GEOID,
    h_tract = tracts$GEOID
)



# Calculate all pairwise distances between tracts
distance_matrix <- st_distance(st_centroid(tracts), st_centroid(tracts))

# Convert to data.table for easier merging
tract_ids <- tracts$GEOID
distance_dt <- data.table(
    origin_tract = rep(tract_ids, each = length(tract_ids)),
    destination_tract = rep(tract_ids, length(tract_ids)),
    distance_meters = as.numeric(distance_matrix)
)

full_data <- merge(full_data, distance_dt, by.x = c("w_tract", "h_tract"), by.y = c("origin_tract", "destination_tract"), all.x = TRUE) |> as.data.table()

# Convert distance to kilometers
full_data[, distance_km := distance_meters / 1000]

# rename the all flow variable
setnames(data, "S000", "flow_all")

full_data <- merge(full_data, data, by.x = c("w_tract", "h_tract"), by.y = c("w_tract", "h_tract"), all.x = TRUE)

# set flow 0 if na
full_data[is.na(flow_all), flow_all := 0]

# N_Ri
nRi <- full_data[, .(nri = sum(flow_all, na.rm = TRUE)), by = h_tract]

# N_Wj
nWj <- full_data[, .(nwj = sum(flow_all, na.rm = TRUE)), by = w_tract]

# exp(-ekd)
ekd <- full_data[, .(w_tract, h_tract, exp_term = exp(ek * distance_km), distance_km)]

data_julia <- merge(ekd, nRi, by.x = "h_tract", by.y = "h_tract", all.x = TRUE)
data_julia <- merge(data_julia, nWj, by.x = "w_tract", by.y = "w_tract", all.x = TRUE)

fwrite(data_julia, here("input", "temp", "data_julia.csv"))
