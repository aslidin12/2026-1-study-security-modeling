using DrWatson
@quickactivate "project"
using Distributions, Statistics, JLD2
include(srcdir("simulation.jl"))

params = Dict(
    :λ               => 5.0,
    :T               => 24.0,
    :num_hours_for_est => 10000
)

function run_simulation(p)
    @unpack λ, T, num_hours_for_est = p
    res           = simulate_attacks(λ, T)
    hourly_sample = rand(Poisson(λ), num_hours_for_est)
    emp_prob      = count(hourly_sample .> 10) / num_hours_for_est
    theor_prob    = 1 - cdf(Poisson(λ), 10)
    return Dict(
        :hourly_counts => res.hourly_counts,
        :intervals     => res.intervals,
        :attack_times  => res.attack_times,
        :emp_prob      => emp_prob,
        :theor_prob    => theor_prob
    )
end

# Генерируем имя файла на основе параметров (функция safename из DrWatson)
filename = datadir("attack_sim", savename(params, "jld2"))
mkpath(datadir("attack_sim"))

# Проверяем, существует ли уже файл
if isfile(filename)
    println("Загрузка из $filename")
    data = load(filename)["data"]
else
    println("Запуск симуляции...")
    data = run_simulation(params)
    @save filename data
    println("Сохранено в $filename")
end

println("Эмпирическая P(>10) = ", data[:emp_prob])
println("Теоретическая P(>10) = ", data[:theor_prob])