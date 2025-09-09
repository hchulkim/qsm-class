using DrWatson
@quickactivate
using DataFrames, CSV, LinearAlgebra, Statistics, FixedPointAcceleration

# Calibrate certain parameters
epsilon = 3.2

ek = CSV.read(projectdir("input", "temp", "ek_estimate.csv"), DataFrame)
ek = ek.estimate
kappa = ek / 3.2

alpha = 0.9
beta = 0.9


# Read data for N_Ri and N_Wj
df = CSV.read(projectdir("input", "temp", "data_julia.csv"), DataFrame;
    types=Dict("w_tract" => String, "h_tract" => String))

# filter out nwj=0
df = df[df.nwj.!=0, :]

# We will assume land area is same for all tracts

exponent(distance_km) = exp.(kappa .* distance_km)
df = transform(df, :distance_km => exponent => :exponent)

# create a function to calculate the fixed point for wage
function fixed_point_algorithm(df::DataFrame, h_tract::Symbol=:h_tract, w_tract::Symbol=:w_tract, exponent::Symbol=:exponent, nri::Symbol=:nri, nwj::Symbol=:nwj)


    # Extract one Nr per residence and one Nw per workplace
    Rtab = combine(groupby(df, h_tract), nri => first => :nri)
    Wtab = combine(groupby(df, w_tract), nwj => first => :nwj)

    # get the unique residence and workplace ids
    r_ids = collect(Rtab[!, h_tract])
    w_ids = collect(Wtab[!, w_tract])
    r2i = Dict(r => i for (i, r) in enumerate(r_ids))
    w2j = Dict(w => j for (j, w) in enumerate(w_ids))
    NR = collect(Rtab.nri)
    NW = collect(Wtab.nwj)

    I, J = length(r_ids), length(w_ids)

    # set up I x J matrix for distance
    A = Matrix{Float64}(undef, I, J)
    fill!(A, NaN)

    for row in eachrow(df)
        i, j = r2i[row[h_tract]], w2j[row[w_tract]]
        A[i, j] = row[exponent]
    end
    A = A .^ (-epsilon)

    @assert all(.!isnan.(A)) "Some exp_term values are NaN"

    # set up matrix for J x I
    B = Matrix{Float64}(undef, J, I)
    fill!(B, NaN)

    for row in eachrow(df)
        i, j = r2i[row[h_tract]], w2j[row[w_tract]]
        B[j, i] = (1 / (row[nwj])) * row[nri] * (row[exponent]^(-epsilon))
    end

    # # filter out nan
    # B = B[.!isnan.(B)]
    # # replace!(B, NaN => 0)  # Fill NaN values with 0

    @assert all(.!isnan.(B)) "Some exp_term values are NaN"




    # Define the fixed point map T
    function T(z)
        omega = max.(view(z, 1:J), eps()) # avoid division by zero
        tW = (B * ((A * (omega .^ epsilon)) .^ (-1))) .^ (-(1 / epsilon))
    end

    # Initialize with means of NR, NW
    z0 = fill(1, J)


    Inputs = z0
    fp_anderson = fixed_point(T, Inputs; Algorithm=:Anderson)

    z = fp_anderson.FixedPoint_



    wage = DataFrame(w_tract=w_ids, wage=z)

    return wage
end

# calculate the fixed point
wage = fixed_point_algorithm(df)

df = leftjoin(df, wage, on=:w_tract)

# download the df to csv
CSV.write(projectdir("input", "temp", "df_brinkman_lin.csv"), df)
