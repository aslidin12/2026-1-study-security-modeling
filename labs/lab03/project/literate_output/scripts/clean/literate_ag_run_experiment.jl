using DrWatson
@quickactivate "project"

using Graphs
using JLD2
using Random
using DataFrames
using CSV
using Statistics

include(joinpath(projectdir(), "src", "attack_graph.jl"))
using .AttackGraph

edge_probs = [0.1, 0.12, 0.15, 0.17, 0.2]

n_nodes = 20
source = 1
target = n_nodes

cvss_scores = Dict(
    (1, 3)   => 0.9,
    (2, 5)   => 0.7,
    (3, 8)   => 0.8,
    (5, 20)  => 0.95,
    (8, 20)  => 0.6,
)

trust_relations = [(4, 6), (6, 10), (10, 15), (15, 20)]

Random.seed!(42)

all_results = []

println("="^60)
println("ИССЛЕДОВАНИЕ ДЛЯ РАЗНЫХ ПЛОТНОСТЕЙ РЁБЕР")
println("="^60)
println("Размер сети: $n_nodes узлов")
println("Источник: узел $source")
println("Цель: узел $target")
println("Исследуемые плотности: ", edge_probs)
println()

for p in edge_probs
    println("\n" * "-"^40)
    println("Плотность рёбер: $p")
    println("-"^40)

    g = AttackGraph.build_attack_graph(
        n_nodes, p,
        cvss_scores, trust_relations
    )
    println("  Граф: $(nv(g)) узлов, $(ne(g)) рёбер")

    paths = AttackGraph.find_all_paths(g, source, target)
    println("  Найдено путей: $(length(paths))")

    metrics = AttackGraph.compute_centrality_metrics(g)

    weights = AttackGraph.assign_edge_weights(g, cvss_scores)
    likely_path, probability = AttackGraph.most_likely_path(
        g, source, target, weights
    )

    if !isempty(likely_path)
        println("  Наиболее вероятный путь: $(join(likely_path, " → "))")
        println("  Вероятность успеха: $(round(probability * 100, digits=2))%")
    else
        println("  Путь не найден")
        probability = 0.0
    end

    push!(all_results, (
        edge_prob = p,
        num_paths = length(paths),
        probability = probability,
        likely_path = isempty(likely_path) ? "нет" : join(likely_path, "→"),
        num_edges = ne(g),
        max_indeg = maximum(metrics[:in_degree])
    ))
end

println("\n" * "="^60)
println("СВОДНАЯ ТАБЛИЦА РЕЗУЛЬТАТОВ")
println("="^60)

df = DataFrame(all_results)
println(df)

mkpath(datadir("parameter_study"))
CSV.write(datadir("parameter_study", "results.csv"), df)
println("\nРезультаты сохранены в: $(datadir("parameter_study", "results.csv"))")

using Plots

p1 = plot(
    df.edge_prob, df.num_paths,
    marker = :circle,
    xlabel = "Плотность рёбер",
    ylabel = "Количество путей",
    title = "Зависимость числа путей от плотности",
    legend = false,
    grid = true
)

p2 = plot(
    df.edge_prob, df.probability,
    marker = :square,
    xlabel = "Плотность рёбер",
    ylabel = "Вероятность успеха",
    title = "Зависимость вероятности от плотности",
    legend = false,
    grid = true
)

combined = plot(p1, p2, layout = (2, 1), size = (800, 600))

mkpath(plotsdir())
savefig(combined, plotsdir("parameter_study.png"))
println("График сохранён в: $(plotsdir("parameter_study.png"))")

println("\n" * "="^60)
println("ИССЛЕДОВАНИЕ ЗАВЕРШЕНО")
println("="^60)
println("\nВыводы:")
println("  - С увеличением плотности рёбер растёт количество путей атаки")
println("  - Вероятность успеха также увеличивается")
println("  - Наиболее вероятный путь зависит от структуры графа")
