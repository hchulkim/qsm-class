# maintainer: Hyoungchul Kim
# date: 2025-09-08
# purpose: recover the fundamentals using the wage variable

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils, argparse, yaml, sf, tigris, ggplot2, dplyr)


parser <- ArgumentParser()
parser$add_argument("--input", type = "character")
args <- parser$parse_args()

# read yaml
input_yaml <- read_yaml(args$input)

# Calibrate certain parameters
epsilon <- 3.2

ek <- fread(here("input", "temp", input_yaml$market_access$ek), colClasses = list(character = "estimate"))
ek <- ek$estimate
kappa <- as.numeric(ek) / epsilon

alpha <- 0.9
beta <- 0.9

# load the cleaned data
wage_data <- fread(here("input", "temp", input_yaml$brinkman$wage), colClasses = list(character = c("w_tract", "h_tract")))

# load the flow data
flow_data <- fread(here("input", "temp", input_yaml$tract_tract$main), colClasses = list(character = c("h_tract", "w_tract")))

# merge the wage and flow data
data <- merge(wage_data, flow_data, by = c("h_tract", "w_tract"), all.x = TRUE)


setnames(data, "S000", "flow_all")

# set the flow to 0 if it is NA
data[is.na(flow_all), flow_all := 0]


wage_data <- unique(wage_data[, .(w_tract, h_tract, wage, nri, nwj)])

# recover land rents
data[, prob := flow_all / sum(flow_all, na.rm = TRUE), by = .(h_tract)]

data[, prob := prob * (wage / exponent)]

data <- data[, .(second_term = (sum(prob, na.rm = TRUE))), by = .(h_tract)]

h_nri <- unique(wage_data[, .(h_tract, nri)])

data <- merge(data, h_nri, by = "h_tract", all.x = TRUE)

data <- data[, .(h_tract, second_term = second_term * nri * (1 - beta))]

wage_data <- unique(wage_data[, .(w_tract, wage, nwj)])

wage_data[, first_term := nwj * ((1 - alpha) / alpha) * wage]

data <- merge(data, wage_data, by.x = "h_tract", by.y = "w_tract", all.x = TRUE)

data[, land_rent := first_term + second_term]


# plot the land rent on the map
tracts <- tigris::tracts(state = "PA", county = "Philadelphia", year = 2020) |>
    select(GEOID, geometry) |>
    mutate(tract = as.character(GEOID))


land <- data |>
    as_tibble() |>
    select(h_tract, land_rent) |>
    mutate(h_tract = as.character(h_tract))


# map the land rent onto the map of philadelphia county
land_map <- tracts |>
    left_join(land, by = c("tract" = "h_tract")) |>
    mutate(land_rent = as.numeric(scale(land_rent)))


# plot the map
ggplot(land_map) +
    geom_sf(aes(fill = land_rent)) +
    scale_fill_viridis_c() +
    labs(fill = "land rent") +
    theme_void()
ggsave(here("output", "figures", "land_rent.png"), width = 10, height = 10)


# recover productivity

productivity <- data[, .(h_tract, prod = ((wage / alpha)^alpha) * (land_rent / (1 - alpha))^(1 - alpha))]

productivity[, .(tract = h_tract, prod = prod)] |>
    fwrite(here("output", "tables", "productivity.csv"))


# recover amenity

# load the cleaned data
wage_data <- fread(here("input", "temp", input_yaml$brinkman$wage), colClasses = list(character = c("w_tract", "h_tract")))

# load the flow data
flow_data <- fread(here("input", "temp", input_yaml$tract_tract$main), colClasses = list(character = c("h_tract", "w_tract")))

# merge the wage and flow data
data <- merge(wage_data, flow_data, by = c("h_tract", "w_tract"), all.x = TRUE)


setnames(data, "S000", "flow_all")

# set the flow to 0 if it is NA
data[is.na(flow_all), flow_all := 0]


wage_data <- unique(wage_data[, .(w_tract, h_tract, wage, nri, nwj)])

wage_only <- unique(wage_data[, .(w_tract, wage)])

sum_term <- data[, .(sum_terms = sum((wage / exponent)^epsilon, na.rm = TRUE)), by = .(h_tract)]
sum_term[, sum_terms := (sum_terms)^(-1 / epsilon)]

sum_term <- merge(sum_term, wage_only, by.x = "h_tract", by.y = "w_tract", all.x = TRUE)

sum_term[, wage := wage^(1 - beta)]

sum_term[, sum_terms := sum_terms * wage]

sum_term[, sum_terms := sum_terms * (1 / gamma((epsilon - 1) / epsilon)) * (1600000)^(-1 / epsilon)]

sum_term <- merge(sum_term, unique(wage_data[, .(h_tract, nri)]), by = "h_tract", all.x = TRUE)

sum_term[, sum_terms := sum_terms * (nri)^(1 / epsilon)]

fwrite(sum_term[, .(tract = h_tract, amenity = sum_terms)], here("output", "tables", "amenity.csv"))
