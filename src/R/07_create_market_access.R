# maintainer: Hyoungchul Kim
# date: 2025-09-06
# purpose: create market access variable

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, argparse, yaml, sf, tigris, stringr, kableExtra, ggplot2, dplyr)


parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- read_yaml(args$input)

# load the data
ek <- fread(here("input", "temp", input_yaml$market_access$ek))[, estimate]
fixef <- fread(here("input", input_yaml$market_access$fixef), colClasses = list(character = "tract"))

# theta_i
theta <- fixef[var == "h_tract", ][, .(tract, theta_i = exp(value))]

# lambda_i
lambda <- fixef[var == "w_tract", ][, .(tract, lambda_j = exp(value))]


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

# add theta
full_data <- merge(full_data, theta, by.x = "h_tract", by.y = "tract", all.x = TRUE)

# add lambda
full_data <- merge(full_data, lambda, by.x = "w_tract", by.y = "tract", all.x = TRUE)

# add 0 for missing values
full_data[is.na(theta_i), theta_i := 0]
full_data[is.na(lambda_j), lambda_j := 0]

# make exp(-ek * distance_km) term
full_data[, exp_term := exp(ek * distance_km)]

# create market access variable

## residential market access
res_market_access <- full_data[, .(w_tract, h_tract, sum_term = lambda_j * exp_term)][, .(res_ma = sum(sum_term)), by = h_tract]

# workplace market access
work_market_access <- full_data[, .(w_tract, h_tract, sum_term = theta_i * exp_term)][, .(work_ma = sum(sum_term)), by = w_tract]

res_market_access |>
    kbl(format = "latex", booktabs = TRUE, longtable = TRUE, caption = "Residential market access", col.names = c("Tract", "Residential market access"), linesep = "") |>
    kable_styling(latex_options = c("repeat_header")) |>
    save_kable(here("output", "tables", "residential_market_access.tex"))

work_market_access |>
    kbl(format = "latex", booktabs = TRUE, longtable = TRUE, caption = "Workplace market access", col.names = c("Tract", "Workplace market access"), linesep = "") |>
    kable_styling(latex_options = c("repeat_header")) |>
    save_kable(here("output", "tables", "workplace_market_access.tex"))

# save the data
fwrite(res_market_access, here("input", "temp", "residential_market_access.csv.gz"))
fwrite(work_market_access, here("input", "temp", "workplace_market_access.csv.gz"))

# map the market access onto the map of philadelphia county
tracts <- tracts |>
    select(GEOID, geometry) |>
    mutate(tract = as.character(GEOID))

res_map <- tracts |>
    left_join(res_market_access, by = c("tract" = "h_tract")) |>
    mutate(res_ma = as.numeric(scale(res_ma)))

work_map <- tracts |>
    left_join(work_market_access, by = c("tract" = "w_tract")) |>
    mutate(work_ma = as.numeric(scale(work_ma)))

# plot the map
ggplot(res_map) +
    geom_sf(aes(fill = res_ma)) +
    scale_fill_viridis_c() +
    labs(fill = "Residential market access", title = "Residential market access") +
    theme_void()
ggsave(here("output", "figures", "residential_market_access.png"), width = 10, height = 10)

ggplot(work_map) +
    geom_sf(aes(fill = work_ma)) +
    scale_fill_viridis_c() +
    labs(fill = "Workplace market access", title = "Workplace market access") +
    theme_void()
ggsave(here("output", "figures", "workplace_market_access.png"), width = 10, height = 10)
