# maintainer: Hyoungchul Kim
# date: 2025-09-01
# purpose: estimate linear model

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast)

# set working directory
here::i_am("src/R/03_est_linear_model.R")

# load the data
data <- fread(here("input", "temp", "philly_od_tract_tract_2022_with_distance.csv.gz"),
    colClasses = list(character = c("h_tract", "w_tract", "w_county", "h_county"))
)

setnames(data, "S000", "flow_all")

res <- feols(log(flow_all) ~ distance_km | w_tract + h_tract, data = data)

estimate <- tidy(res)

fe <- fixef(res)

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
