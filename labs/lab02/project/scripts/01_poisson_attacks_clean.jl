using DrWatson
@quickactivate "project"
using Distributions
using Statistics
using Plots
using StatsPlots
using JLD2
using Random

gr(fmt = :png)

params = Dict(
    :λ => 5.0,
    :T => 24.0,
    :num_hours_for_est => 10000
)

using Distributions
using Statistics
function simulate_attacks(λ::Float64, T::Float64)
    hourly_counts = rand(Poisson(λ), floor(Int, T)) # Моделирование числа атак по часам (целые часы)
    intervals = Float64[] # Моделирование интервалов между атаками (точные моменты)
    total_time = 0.0
    while total_time < T
        τ = rand(Exponential(1/λ))
        push!(intervals, τ)
        total_time += τ
    end
    # Удаляем последнее событие, если оно вышло за пределы T
    if total_time > T
        pop!(intervals)
    end
    attack_times = cumsum(intervals)
    return (hourly_counts = hourly_counts, intervals = intervals,
        attack_times = attack_times)
end

function simulate_attacks(p::Dict)
    return simulate_attacks(p[:λ], p[:T])
end

function run_simulation(p)
    @unpack λ, T, num_hours_for_est = p
    res = simulate_attacks(λ, T)
    hourly_sample = rand(Poisson(λ), num_hours_for_est)
    emp_prob = count(hourly_sample .> 10) / num_hours_for_est
    theor_prob = 1 - cdf(Poisson(λ), 10)
    return Dict(
        :hourly_counts => res.hourly_counts,
        :intervals => res.intervals,
        :attack_times => res.attack_times,
        :emp_prob => emp_prob,
        :theor_prob => theor_prob
    )
end

filename = datadir("attack_sim", savename(params, "jld2"))
mkpath(datadir("attack_sim"))

if isfile(filename)
    println("Загрузка существующих данных из $filename")
    data = load(filename)["data"]
else
    println("Запуск симуляции...")
    data = run_simulation(params)
    println("Сохраняем в файл...")
    @save filename data
    println("Результаты сохранены в $filename")
end
println("Эмпирическая вероятность P(>10) = ", data[:emp_prob])
println("Теоретическая вероятность = ", data[:theor_prob])

@load filename data

hourly_counts = data[:hourly_counts]
intervals = data[:intervals]
attack_times = data[:attack_times]
λ = params[:λ]
T = params[:T]
emp_prob = data[:emp_prob]
theor_prob = data[:theor_prob]

println("Эмпирическая вероятность P(>10) = ", emp_prob)
println("Теоретическая вероятность = ", theor_prob)

p1 = histogram(hourly_counts, bins = 0:maximum(hourly_counts),
    normalize = :probability,
    label = "Эмпирическая частота", xlabel = "Число атак
    за час", ylabel = "Вероятность")
x_vals = 0:maximum(hourly_counts)
theor_probs = pdf.(Poisson(λ), x_vals)
plot!(p1, x_vals, theor_probs, line = :stem, marker = :circle, label =
    "Теоретическое Пуассона(λ=$λ)", lw=2)
title!(p1, "Распределение числа атак за час")

p2 = plot(attack_times, 1:length(attack_times), label =
    "Реализация", xlabel = "Время (ч)", ylabel = "Накопленное число атак")
plot!(p2, 0:0.1:T, λ*(0:0.1:T), label = "Среднее λ·t", ls = :dash)
title!(p2, "Накопленное число атак в течение $(T) ч")

p3 = histogram(intervals, bins = 30, normalize = :pdf, label =
    "Эмпирическая плотность",
    xlabel = "Интервал (ч)", ylabel = "Плотность")
x_dens = range(0, maximum(intervals), length=100)
theor_dens = pdf.(Exponential(1/λ), x_dens)
plot!(p3, x_dens, theor_dens, label = "Экспоненциальная плотность",
    lw=2)
title!(p3, "Распределение интервалов между атаками")

p4 = qqplot(Exponential(1/λ), intervals, qqline = :identity,
    xlabel = "Теоретические квантили", ylabel = "Эмпирические
    квантили",
    title = "QQ-plot интервалов")

plot(p1, p2, p3, p4, layout = (2,2), size = (1000, 800))

savefig(plotsdir("attack_sim_plots.png"))
println("Графики сохранены в ", plotsdir("attack_sim_plots.png"))

λ = 5.0
theor_prob = 1 - cdf(Poisson(λ), 10)

sample_sizes = [10, 50, 100, 500, 1000, 5000, 10000, 50000, 100000]

Random.seed!(123)

estimates = Float64[]
println("Вычисление оценок вероятности...")
for n in sample_sizes
    hourly_sample = rand(Poisson(λ), n)
    emp_prob = count(hourly_sample .> 10) / n
    push!(estimates, emp_prob)
    println("n = $n: оценка = $emp_prob")
end

p = plot(sample_sizes, estimates,
    xscale = :log10,
    marker = :circle,
    label = "Эмпирическая оценка",
    xlabel = "Объём выборки (часы)",
    ylabel = "Оценка вероятности P(>10)",
    legend = :bottomright)
hline!(p, [theor_prob],
    label = "Теоретическое значение",
    ls = :dash,
    lw = 2,
    color = :red)
title!(p, "Сходимость оценки вероятности P(>10) при λ=$λ")

plot_path = plotsdir("convergence.png")
savefig(p, plot_path)
println("График сохранён в $plot_path")

data_path = datadir("convergence", "convergence_data_λ=$(λ).jld2")
mkpath(datadir("convergence"))
@save data_path sample_sizes estimates λ theor_prob
println("Данные сходимости сохранены в $data_path")

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
