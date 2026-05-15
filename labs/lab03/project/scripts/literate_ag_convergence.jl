# # Исследование масштабируемости графа атак
# 
# ## Цель
# 
# Изучить, как размер сети (количество узлов) влияет на:
# - время поиска всех путей атаки
# - количество найденных путей
# 
# ## Подготовка окружения

using DrWatson
@quickactivate "project"

using Graphs
using Plots
using JLD2
using Random
using BenchmarkTools

# Подключаем локальный модуль AttackGraph
include(joinpath(projectdir(), "src", "attack_graph.jl"))
using .AttackGraph

# ## Параметры исследования

sizes = [10, 15, 20, 21, 22, 23, 24, 25]
Random.seed!(123)

time_vals = Float64[]
path_counts = Int[]

println("="^60)
println("ИССЛЕДОВАНИЕ МАСШТАБИРУЕМОСТИ")
println("="^60)

# ## Запуск экспериментов

for n in sizes
    println("\nРазмер сети: $n узлов")
    
    g = AttackGraph.build_attack_graph(n, 0.2, Dict(), [])
    println("  Рёбер: $(ne(g))")
    
    elapsed_time = @elapsed paths = AttackGraph.find_all_paths(g, 1, n)
    
    push!(time_vals, elapsed_time)
    push!(path_counts, length(paths))
    
    println("  Время: $(round(elapsed_time, digits=3)) секунд")
    println("  Путей: $(length(paths))")
end

# ## Визуализация результатов

p1 = plot(
    sizes, time_vals,
    marker = :circle,
    xlabel = "Число узлов в сети",
    ylabel = "Время выполнения (секунды)",
    title = "Зависимость времени поиска путей от размера сети",
    legend = false,
    grid = true,
)

p2 = plot(
    sizes, path_counts,
    marker = :square,
    xlabel = "Число узлов в сети",
    ylabel = "Количество найденных путей",
    title = "Зависимость числа путей атаки от размера сети",
    legend = false,
    grid = true,
)

combined = plot(p1, p2, layout = (2, 1), size = (800, 600))

mkpath(plotsdir())
savefig(combined, plotsdir("convergence.png"))
println("\nГрафик сохранён в: $(plotsdir("convergence.png"))")

# ## Сохранение данных

mkpath(datadir("convergence"))
@save datadir("convergence", "convergence_data.jld2") sizes time_vals path_counts
println("Данные сохранены в: $(datadir("convergence", "convergence_data.jld2"))")

# ## Выводы

println("\n" * "="^60)
println("ИССЛЕДОВАНИЕ ЗАВЕРШЕНО")
println("="^60)