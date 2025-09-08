# maintainer: Hyoungchul Kim
# date: 2025-09-08
# purpose: map the market access variable

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, argparse, yaml, sf, tigris, ggplot2, dplyr)


parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- read_yaml(args$input)

# load the cleaned data
residence <- fread(here("input", "temp", input_yaml$fixed_point$residence), colClasses = list(character = "r_id"))
workplace <- fread(here("input", "temp", input_yaml$fixed_point$workplace), colClasses = list(character = "w_id"))


# load the census tracts
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020)

# map the market access onto the map of philadelphia county
tracts <- tracts |>
    select(GEOID, geometry) |>
    mutate(tract = as.character(GEOID))

res_map <- tracts |>
    left_join(residence, by = c("tract" = "r_id")) |>
    mutate(ΦR = as.numeric(scale(ΦR)))

work_map <- tracts |>
    left_join(workplace, by = c("tract" = "w_id")) |>
    mutate(ΦW = as.numeric(scale(ΦW)))

# plot the map
ggplot(res_map) +
    geom_sf(aes(fill = ΦR)) +
    scale_fill_viridis_c() +
    labs(fill = "Residential market access", title = "Residential market access") +
    theme_void()
ggsave(here("output", "figures", "residential_market_access_fixed_point.png"), width = 10, height = 10)

ggplot(work_map) +
    geom_sf(aes(fill = ΦW)) +
    scale_fill_viridis_c() +
    labs(fill = "Workplace market access", title = "Workplace market access") +
    theme_void()
ggsave(here("output", "figures", "workplace_market_access_fixed_point.png"), width = 10, height = 10)
