# # Визуализация результатов

using DrWatson
@quickactivate "project"

using Plots, DataFrames, Statistics

include(srcdir("simulation.jl"))

# ## Загрузка данных

results = load_results()

# ## Фильтрация: c_a = 1, c_d = 1

filtered = results[(results.c_a .== 1.0) .& (results.c_d .== 1.0), :]
ratio = filtered.V1 ./ filtered.V2
scatter( ratio,
    filtered.p_1,
    group = filtered.type,
    xlabel = "V1 / V2",
    ylabel = "p1 (вероятность атаки на актив 1)",
    title = "Стратегия Нападающего (c_a=1, c_d=1)",
    legend = :topright,
)
savefig(plotsdir("p1_vs_ratio.png"))

# Тепловая карта выигрыша Нападающего
grp = groupby(filtered, [:V1, :V2])
summ = combine(grp, :UA => mean => :UA_mean)
heatmap(
    sort(unique(summ.V1)),
    sort(unique(summ.V2)),
    (x, y) -> summ[(summ.V1 .== x) .& (summ.V2 .== y), :UA_mean][1],
    xlabel = "V1",
    ylabel = "V2",
    title = "Средний выигрыш Нападающего",
)
savefig(plotsdir("heatmap_UA.png"))
