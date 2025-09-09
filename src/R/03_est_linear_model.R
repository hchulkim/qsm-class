# maintainer: Hyoungchul Kim
# date: 2025-09-01
# purpose: estimate linear model

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, argparse, yaml, ggplot2, sf, tigris, dplyr)

# set working directory
# here::i_am("src/R/03_est_linear_model.R")

parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- yaml.load_file(args$input)

# load the data
data <- fread(here("input", "temp", input_yaml$distance$original),
    colClasses = list(character = c("h_tract", "w_tract", "w_county", "h_county"))
)

# rename the all flow variable
setnames(data, "S000", "flow_all")

# run the linear model
res <- feols(log(flow_all) ~ distance_km | w_tract + h_tract, data = data)

# get the estimates
estimate <- tidy(res)

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

# download the regression table tex file
texreg(res,
    custom.model.names = c("Log of commuting flow"),
    use.packages = FALSE,
    table = FALSE,
    include.ci = FALSE,
    include.rmse = FALSE,
    include.adjrs = FALSE,
    file = here("output", "tables", "q3_linear_model.tex")
)

# also download the estimates table tex file for FEs
fwrite(dt, here("input", "q3_linear_model_fes.csv"))

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
ggsave(here("output", "figures", "residential_fe.png"), width = 10, height = 10)

ggplot(work_map) +
    geom_sf(aes(fill = work_ma)) +
    scale_fill_viridis_c() +
    labs(fill = "fixed effect parameter") +
    theme_void()
ggsave(here("output", "figures", "workplace_fe.png"), width = 10, height = 10)
