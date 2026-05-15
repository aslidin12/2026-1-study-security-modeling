using Pkg
Pkg.activate(".")
Pkg.add([
    "DrWatson", "Distributions", "Statistics",
    "Plots", "StatsPlots", "JLD2", "Random",
    "CSV", "DataFrames", "Literate", "IJulia"
])