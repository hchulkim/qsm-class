# maintainer: Hyoungchul Kim
# date: 2025-09-01
# purpose: estimate ppml model

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, tigris, sf, argparse, yaml)

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
