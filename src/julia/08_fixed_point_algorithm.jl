using DrWatson
@quickactivate
using DataFrames, CSV, LinearAlgebra, FixedPointAcceleration, Statistics

# Read data with specific column types
data = CSV.read(projectdir("input", "temp", "data_julia.csv"), DataFrame;
    types=Dict("w_tract" => String, "h_tract" => String))

# create a function to calculate the fixed point algorithm
function fixed_point_algorithm(df::DataFrame, r_id::Symbol=:h_tract, w_id::Symbol=:w_tract, exp_term::Symbol=:exp_term, nri::Symbol=:nri, nwj::Symbol=:nwj, tol=1e-10, maxit=10_000, m=6, damping=1.0)

    # Extract one Nr per residence and one Nw per workplace
    Rtab = combine(groupby(df, r_id), nri => first => :nri)
    Wtab = combine(groupby(df, w_id), nwj => first => :nwj)

    # get the unique residence and workplace ids
    r_ids = collect(Rtab[!, r_id])
    w_ids = collect(Wtab[!, w_id])
    r2i = Dict(r => i for (i, r) in enumerate(r_ids))
    w2j = Dict(w => j for (j, w) in enumerate(w_ids))
    NR = collect(Rtab.nri)
    NW = collect(Wtab.nwj)

    I, J = length(r_ids), length(w_ids)

    # set up matrix for exp_term
    A = Matrix{Float64}(undef, I, J)
    fill!(A, NaN)

    for row in eachrow(df)
        i, j = r2i[row[r_id]], w2j[row[w_id]]
        A[i, j] = row[exp_term]
    end

    @assert all(.!isnan.(A)) "Some exp_term values are NaN"

    # Define the fixed point map T
    function T(z)
        ϕR = max.(view(z, 1:I), eps()) # avoid division by zero
        ϕW = max.(view(z, I+1:I+J), eps())
        tR = A * (NW ./ ϕW)
        tW = A' * (NR ./ ϕR)
        vcat(tR, tW)
    end

    # Initialize with means of NR, NW
    z0 = vcat(fill(mean(NR), I), fill(mean(NW), J))

    Inputs = z0
    fp_anderson = fixed_point(T, Inputs; Algorithm=:Anderson)

    z = fp_anderson.FixedPoint_


    ΦR = copy(view(z, 1:I))
    ΦW = copy(view(z, I+1:I+J))

    ΦR_df = DataFrame(r_id=r_ids, ΦR=ΦR)
    ΦW_df = DataFrame(w_id=w_ids, ΦW=ΦW)

    return ΦR_df, ΦW_df
end

ΦR_df, ΦW_df = fixed_point_algorithm(data)

CSV.write(projectdir("input", "temp", "Residence_df.csv"), ΦR_df)
CSV.write(projectdir("input", "temp", "Workplace_df.csv"), ΦW_df)
