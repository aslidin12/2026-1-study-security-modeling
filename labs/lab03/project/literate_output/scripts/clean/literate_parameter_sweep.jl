using DrWatson
@quickactivate "project"

using Graphs
using CSV
using DataFrames
using Plots
using Random
using Statistics

include(joinpath(projectdir(), "src", "attack_graph.jl"))
using .AttackGraph

edge_probs = 0.1:0.1:0.9
n_nodes = 13
source = 1
target = n_nodes

Random.seed!(123)

results = []

println("="^60)
println("ПАРАМЕТРИЧЕСКОЕ ИССЛЕДОВАНИЕ")
println("="^60)
println("Размер сети: $n_nodes узлов")
println("Источник: узел $source")
println("Цель: узел $target")
println("Диапазон плотностей: 0.1 → 0.9")
println()

for p in edge_probs
    println("Плотность рёбер: $p")

    g = AttackGraph.build_attack_graph(n_nodes, p, Dict(), [])
    paths = AttackGraph.find_all_paths(g, source, target)
    metrics = AttackGraph.compute_centrality_metrics(g)

    avg_path_len = isempty(paths) ? 0.0 : mean(length.(paths))

    push!(results, (
        edge_prob = p,
        num_paths = length(paths),
        max_indeg = maximum(metrics[:in_degree]),
        avg_path_len = avg_path_len
    ))

    println("  Путей: $(length(paths))")
    println("  Средняя длина: $(round(avg_path_len, digits=2))")
    println()
end

df = DataFrame(results)
mkpath(datadir("parameter_sweep"))
CSV.write(datadir("parameter_sweep", "results.csv"), df)
println("CSV сохранён в: $(datadir("parameter_sweep", "results.csv"))")

p1 = plot(
    [r.edge_prob for r in results],
    [r.num_paths for r in results],
    marker = :circle,
    xlabel = "Плотность рёбер (вероятность)",
    ylabel = "Количество путей атаки",
    title = "Зависимость числа путей от связности сети",
    legend = false,
    grid = true,
)

p2 = plot(
    [r.edge_prob for r in results],
    [r.avg_path_len for r in results],
    marker = :square,
    xlabel = "Плотность рёбер (вероятность)",
    ylabel = "Средняя длина пути",
    title = "Зависимость длины путей от связности сети",
    legend = false,
    grid = true,
)

combined = plot(p1, p2, layout = (2, 1), size = (800, 600))

mkpath(plotsdir())
savefig(combined, plotsdir("parameter_sweep.png"))
println("График сохранён в: $(plotsdir("parameter_sweep.png"))")

println("\n" * "="^60)
println("ИССЛЕДОВАНИЕ ЗАВЕРШЕНО")
println("="^60)
