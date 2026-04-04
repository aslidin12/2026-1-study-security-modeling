using DrWatson
@quickactivate "project"
using Literate

mkpath(joinpath(@__DIR__, "..", "notebooks"))
mkpath(joinpath(@__DIR__, "..", "markdown"))

script1 = joinpath(@__DIR__, "01_poisson_attacks.jl")
script2 = joinpath(@__DIR__, "02_poisson_attacks.jl")

for (script, name) in [(script1, "01_poisson_attacks"),
                        (script2, "02_poisson_attacks")]
    Literate.script(  script, @__DIR__;
        name = name * "_clean")
    Literate.notebook(script, joinpath(@__DIR__, "..", "notebooks");
        name = name, execute = false)
    Literate.markdown(script, joinpath(@__DIR__, "..", "markdown");
        name = name, flavor = Literate.QuartoFlavor())
end

println("Готово.")