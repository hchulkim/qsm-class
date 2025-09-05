# maintainer: Hyoungchul Kim
# date: 2025-09-04
# purpose: estimate linear model and ppml

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, fixest, broom, texreg, tidyfast, argparse, yaml)


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
