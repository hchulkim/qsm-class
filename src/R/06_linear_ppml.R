# maintainer: Hyoungchul Kim
# date: 2025-09-04
# purpose: estimate linear model and ppml

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, argparse, yaml, glue)


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

# load the census tracts
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020)

full_data <- expand.grid(
    w_tract = tracts$GEOID,
    h_tract = tracts$GEOID
)



# # Calculate all pairwise distances between tracts
# distance_matrix <- st_distance(st_centroid(tracts), st_centroid(tracts))

# # Convert to data.table for easier merging
# tract_ids <- tracts$GEOID
# distance_dt <- data.table(
#     origin_tract = rep(tract_ids, each = length(tract_ids)),
#     destination_tract = rep(tract_ids, length(tract_ids)),
#     distance_meters = as.numeric(distance_matrix)
# )

# full_data <- merge(full_data, distance_dt, by.x = c("w_tract", "h_tract"), by.y = c("origin_tract", "destination_tract"), all.x = TRUE) |> as.data.table()

# # Convert distance to kilometers
# full_data[, distance_km := distance_meters / 1000]

# # rename the all flow variable
# setnames(data, "S000", "flow_all")

# full_data <- merge(full_data, data, by.x = c("w_tract", "h_tract"), by.y = c("w_tract", "h_tract"), all.x = TRUE)

# # set flow 0 if na
# full_data[is.na(flow_all), flow_all := 0]

# # do PPML
# res <- fepois(flow_all ~ distance_km | w_tract + h_tract, data = full_data)


# # download the regression table tex file
# texreg(res,
#     custom.model.names = c("PPML"),
#     use.packages = FALSE,
#     table = FALSE,
#     include.ci = FALSE,
#     include.rmse = FALSE,
#     include.adjrs = FALSE,
#     include.loglik = FALSE,
#     include.deviance = FALSE,
#     file = here("output", "tables", "q4_ppml.tex")
# )

# # get the fixed effects
# fe <- fixef(res)

# # create the data table for the fixed effects
# dt <- rbindlist(
#     lapply(names(fe), function(nm) {
#         data.table(
#             tract = names(fe[[nm]]), # use names as the join key
#             var   = nm,
#             value = as.numeric(fe[[nm]])
#         )
#     })
# )

# # also download the estimates table tex file for FEs
# fwrite(dt, here("input", "q4_ppml_fes.csv"))
