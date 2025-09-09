# maintainer: Hyoungchul Kim
# date: 2025-09-01
# purpose: estimate ppml model

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, tigris, sf, argparse, yaml, ggplot2, dplyr, tigris)

# set working directory
# here::i_am("src/R/04_est_ppml.R")

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

# do PPML
res <- fepois(flow_all ~ distance_km | w_tract + h_tract, data = full_data)

ek <- tidy(res)

fwrite(ek, here("input", "temp", "ek_estimate.csv"))

# download the regression table tex file
texreg(res,
    custom.model.names = c("PPML"),
    use.packages = FALSE,
    table = FALSE,
    include.ci = FALSE,
    include.rmse = FALSE,
    include.adjrs = FALSE,
    include.loglik = FALSE,
    include.deviance = FALSE,
    file = here("output", "tables", "q4_ppml.tex")
)

# get the fixed effects
fe <- fixef(res)

# create the data table for the fixed effects
dt <- rbindlist(
    lapply(names(fe), function(nm) {
        data.table(
            tract = names(fe[[nm]]), # use names as the join key
            var   = nm,
            value = as.numeric(fe[[nm]])
        )
    })
)

# also download the estimates table tex file for FEs
fwrite(dt, here("input", "q4_ppml_fes.csv"))

# plot the fes by map
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020) |>
    select(GEOID, geometry) |>
    mutate(tract = as.character(GEOID))


res_market_access <- dt |>
    filter(var == "h_tract") |>
    select(tract, value) |>
    mutate(tract = as.character(tract)) |>
    rename(h_tract = tract, res_ma = value)

work_market_access <- dt |>
    filter(var == "w_tract") |>
    select(tract, value) |>
    mutate(tract = as.character(tract)) |>
    rename(w_tract = tract, work_ma = value)

# map the market access onto the map of philadelphia county
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
    labs(fill = "fixed effect parameter") +
    theme_void()
ggsave(here("output", "figures", "residential_fe_ppml.png"), width = 10, height = 10)

ggplot(work_map) +
    geom_sf(aes(fill = work_ma)) +
    scale_fill_viridis_c() +
    labs(fill = "fixed effect parameter") +
    theme_void()
ggsave(here("output", "figures", "workplace_fe_ppml.png"), width = 10, height = 10)
