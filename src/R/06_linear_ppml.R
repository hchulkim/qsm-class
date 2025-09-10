# maintainer: Hyoungchul Kim
# date: 2025-09-04
# purpose: estimate linear model and ppml

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, argparse, yaml, glue, tigris, dplyr, ggplot2, sf)


parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- read_yaml(args$input)

# load the data
data1 <- fread(here("input", "temp", input_yaml$distance$solution1),
    colClasses = list(character = c("h_tract", "w_tract", "w_county", "h_county"))
)

data2 <- fread(here("input", "temp", input_yaml$distance$solution2),
    colClasses = list(character = c("h_tract", "w_tract", "w_county", "h_county"))
)


linear_model <- function(dt, label) {
    data <- copy(dt)

    # rename the all flow variable
    setnames(data, "S000", "flow_all")

    # run the linear model
    res <- fixest::feols(log(flow_all) ~ distance_km | w_tract + h_tract, data = data)

    # get the estimates (kept if you need them)
    estimate <- broom::tidy(res)

    # get the fixed effects and build a tidy table
    fe <- fixest::fixef(res)
    dt_fe <- rbindlist(
        lapply(names(fe), function(nm) {
            data.table(
                tract = names(fe[[nm]]),
                var   = nm,
                value = as.numeric(fe[[nm]])
            )
        })
    )

    # 4) Write outputs using the short label (NOT the whole data.table)
    texreg::texreg(
        res,
        custom.model.names = c("Log of commuting flow"),
        use.packages = FALSE,
        table = FALSE,
        include.ci = FALSE,
        include.rmse = FALSE,
        include.adjrs = FALSE,
        file = here("output", "tables", glue("q5_linear_model_{label}.tex"))
    )

    fwrite(dt_fe, here("input", "temp", glue("q5_linear_model_fes_{label}.csv")))
}

# 5) Run with concise labels
linear_model(data1, "solution1")
linear_model(data2, "solution2")


# ppml estimation

# solution 1

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
    distance_meters = as.numeric(distance_ii) / 1000
)

full_data <- merge(full_data, distance_dt_ii, by.x = c("w_tract", "h_tract"), by.y = c("origin_tract", "destination_tract"), all.x = TRUE)

full_data[w_tract == h_tract, distance_km := distance_meters.y]

# run the ppml model
res <- fixest::fepois(flow_all ~ distance_km | w_tract + h_tract, data = full_data)

# get the estimates (kept if you need them)
estimate <- broom::tidy(res)

# get the fixed effects and build a tidy table
fe <- fixest::fixef(res)
dt_fe <- rbindlist(
    lapply(names(fe), function(nm) {
        data.table(
            tract = names(fe[[nm]]),
            var   = nm,
            value = as.numeric(fe[[nm]])
        )
    })
)

texreg::texreg(
    res,
    custom.model.names = c("PPML"),
    use.packages = FALSE,
    table = FALSE,
    include.ci = FALSE,
    include.rmse = FALSE,
    include.adjrs = FALSE,
    include.loglik = FALSE,
    include.deviance = FALSE,
    file = here("output", "tables", glue("q5_ppml_model_solution1.tex"))
)

fwrite(dt_fe, here("input", "temp", glue("q5_ppml_fes_solution1.csv")))




# solution 2

# load the cleaned data
data <- fread(here("input", "temp", input_yaml$tract_tract$main),
    colClasses = list(character = c("h_tract", "w_tract"))
)

# load the census blocks
blocks <- tigris::blocks(state = "PA", county = "Philadelphia", year = 2020)

# Calculate all pairwise distances between tracts (centroid to centroid)
distance_matrix <- st_distance(st_centroid(blocks), st_centroid(blocks))

# Convert to data.table for easier merging
blocks_ids <- blocks$GEOID20
distance_dt <- data.table(
    origin_block = rep(blocks_ids, each = length(blocks_ids)),
    destination_block = rep(blocks_ids, length(blocks_ids)),
    distance_meters = as.numeric(distance_matrix)
)

distance_dt[, `:=`(origin_tract = substr(origin_block, 1, 11), destination_tract = substr(destination_block, 1, 11))]

distance_dt <- distance_dt[, .(distance_meters = mean(distance_meters, na.rm = TRUE)), by = .(origin_tract, destination_tract)]

# Merge with your bilateral data
data_with_distance <- merge(
    distance_dt,
    data,
    by.x = c("origin_tract", "destination_tract"),
    by.y = c("h_tract", "w_tract"),
    all.x = TRUE
)

setnames(data_with_distance, c("origin_tract", "destination_tract"), c("h_tract", "w_tract"))


# rename the all flow variable
setnames(data_with_distance, "S000", "flow_all")

data_with_distance[is.na(flow_all), flow_all := 0]


# Convert distance to kilometers
data_with_distance[, distance_km := distance_meters / 1000]

# run the ppml model
res <- fixest::fepois(flow_all ~ distance_km | w_tract + h_tract, data = data_with_distance)

# get the estimates (kept if you need them)
estimate <- broom::tidy(res)

# get the fixed effects and build a tidy table
fe <- fixest::fixef(res)
dt_fe <- rbindlist(
    lapply(names(fe), function(nm) {
        data.table(
            tract = names(fe[[nm]]),
            var   = nm,
            value = as.numeric(fe[[nm]])
        )
    })
)

texreg::texreg(
    res,
    custom.model.names = c("PPML"),
    use.packages = FALSE,
    table = FALSE,
    include.ci = FALSE,
    include.rmse = FALSE,
    include.adjrs = FALSE,
    include.loglik = FALSE,
    include.deviance = FALSE,
    file = here("output", "tables", glue("q5_ppml_model_solution2.tex"))
)

fwrite(dt_fe, here("input", "temp", glue("q5_ppml_fes_solution2.csv")))
