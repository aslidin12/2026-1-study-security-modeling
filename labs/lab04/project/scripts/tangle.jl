using DrWatson
@quickactivate "project"
using Literate

scripts = [
    "run_sims.jl",
    "plot_results.jl",
    "extra_tasks.jl",
]

mkpath(joinpath(@__DIR__, "../markdown"))
mkpath(joinpath(@__DIR__, "../notebooks"))

for s in scripts
    input = joinpath(@__DIR__, s)
    Literate.markdown(input, joinpath(@__DIR__, "../markdown"); flavor = Literate.QuartoFlavor())
    Literate.notebook(input, joinpath(@__DIR__, "../notebooks"); execute = false)
end
