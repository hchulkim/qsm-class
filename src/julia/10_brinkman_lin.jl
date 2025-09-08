using DrWatson
@quickactivate
using DataFrames, CSV, LinearAlgebra, Statistics

# Calibrate certain parameters
epsilon = 3.2

ek = CSV.read(projectdir("input", "temp", "ek_estimate.csv"), DataFrame)
ek = ek.estimate
kappa = ek / 3.2

alpha = 0.9
beta = 0.9


# Read data for N_Ri and N_Wj
data = CSV.read(projectdir("input", "temp", "data_julia.csv"), DataFrame;
    types=Dict("w_tract" => String, "h_tract" => String))

# We will assume land area is same for all tracts
