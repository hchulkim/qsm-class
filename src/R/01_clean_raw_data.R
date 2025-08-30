# maintainer: Hyoungchul Kim
# date: 2025-08-29
# purpose: clean raw data

if (!require(pacman)) install.packages("pacman")
pacman::p_load(here, data.table, R.utils)

# set working directory
here::i_am("src/R/01_clean_raw_data.R")

# load data
data <- fread(here("input", "pa_od_main_JT00_2022.csv.gz"))

View(data |> head())
