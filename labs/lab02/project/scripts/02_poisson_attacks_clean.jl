using DrWatson
@quickactivate "project"
using Distributions, Statistics, Plots, StatsPlots, JLD2, Random,
    CSV, DataFrames

include(srcdir("simulation.jl"))

gr(fmt = :png)

base_params = Dict(
    :T => 24.0,
    :num_hours_for_est => 10000
)

λ_values = [2.0, 5.0, 8.0, 12.0, 15.0]

Random.seed!(42)

parametric_plots_dir = plotsdir("parameter_sweep")
mkpath(parametric_plots_dir)

summary = Dict{Float64, Dict}()
println("Запуск параметрического исследования...")
for λ in λ_values
    # Формируем полный словарь параметров
    params = merge(base_params, Dict(:λ => λ))
    # Генерируем имя файла на основе параметров
    filename = datadir("attack_sim", savename(params, "jld2"))
    # Проверяем, существует ли уже файл с результатами
    if isfile(filename)
        println("Загрузка существующих данных для λ = $λ из
            $filename")
        @load filename data
    else
        println("Выполнение симуляции для λ = $λ")
        # Запускаем симуляцию (аналогично run_experiment.jl)
        res = simulate_attacks(λ, params[:T])
        hourly_sample = rand(Poisson(λ), params[:num_hours_for_est])
        emp_prob = count(hourly_sample .> 10) /
            params[:num_hours_for_est]
        theor_prob = 1 - cdf(Poisson(λ), 10)
        data = Dict(
            :hourly_counts => res.hourly_counts,
            :intervals => res.intervals,
            :attack_times => res.attack_times,
            :emp_prob => emp_prob,
            :theor_prob => theor_prob
        )
        # Сохраняем результаты
        @save filename data params
        println("Результаты сохранены в $filename")
    end
    # --- Построение детальных графиков для текущего λ ---
    hourly_counts = data[:hourly_counts]
    intervals = data[:intervals]
    attack_times = data[:attack_times]
    # 1. Гистограмма числа атак за час
    p1 = histogram(hourly_counts, bins = 0:maximum(hourly_counts),
        normalize = :probability,
        label = "Эмпирическая частота", xlabel = "Число
        атак за час", ylabel = "Вероятность")
    x_vals = 0:maximum(hourly_counts)
    theor_probs = pdf.(Poisson(λ), x_vals)
    plot!(p1, x_vals, theor_probs, line = :stem, marker = :circle,
        label = "Теоретическое Пуассона(λ=$λ)", lw=2)
    title!(p1, "Распределение числа атак за час (λ=$λ)")
    # 2. Накопленное число атак
    p2 = plot(attack_times, 1:length(attack_times), label =
        "Реализация", xlabel = "Время (ч)", ylabel = "Накопленное
        число атак")
    plot!(p2, 0:0.1:params[:T], λ*(0:0.1:params[:T]), label =
        "Среднее λ·t", ls = :dash)
    title!(p2, "Накопленное число атак в течение $(params[:T]) ч
        (λ=$λ)")
    # 3. Гистограмма интервалов
    p3 = histogram(intervals, bins = 30, normalize = :pdf, label =
        "Эмпирическая плотность",
        xlabel = "Интервал (ч)", ylabel = "Плотность")
    x_dens = range(0, maximum(intervals), length=100)
    theor_dens = pdf.(Exponential(1/λ), x_dens)
    plot!(p3, x_dens, theor_dens, label = "Экспоненциальная
        плотность", lw=2)
    title!(p3, "Распределение интервалов между атаками (λ=$λ)")
    # 4. QQ-plot интервалов против экспоненциального распределения
    p4 = qqplot(Exponential(1/λ), intervals, qqline = :identity,
        xlabel = "Теоретические квантили", ylabel =
        "Эмпирические квантили",
        title = "QQ-plot интервалов (λ=$λ)")
    # Объединяем графики
    combined = plot(p1, p2, p3, p4, layout = (2,2), size = (1000,
        800))
    # Сохраняем в папку parameter_sweep с именем, содержащим λ
    plot_filename = joinpath(parametric_plots_dir,
        "attack_sim_λ=$(λ).png")
    savefig(combined, plot_filename)
    display(combined)
    println("Детальные графики для λ=$λ сохранены в $plot_filename")
    # Сохраняем сводные данные для этого λ
    summary[λ] = Dict(
        :emp_prob => data[:emp_prob],
        :theor_prob => data[:theor_prob],
        :filename => filename
    )
    println("λ = $λ: теоретическая вероятность =
        $(data[:theor_prob]), эмпирическая = $(data[:emp_prob])")
end

summary_filename = datadir("parameter_sweep",
    "summary_λ_values.jld2")
@save summary_filename λ_values summary
println("Сводные данные сохранены в $summary_filename")

λs = [λ for λ in λ_values]
theor_probs = [summary[λ][:theor_prob] for λ in λs]
emp_probs = [summary[λ][:emp_prob] for λ in λs]
p = plot(λs, [theor_probs emp_probs],
    label = ["Теоретическая P(>10)" "Эмпирическая P(>10)"],
    marker = :circle,
    xlabel = "Интенсивность λ (атак/час)",
    ylabel = "Вероятность P(>10)",
    title = "Зависимость вероятности от интенсивности атак")
global_plot_path = plotsdir("parameter_sweep.png")
savefig(p, global_plot_path)
display(p)
println("Общий график зависимости сохранён в $global_plot_path")

df = DataFrame(λ = λs, theoretical = theor_probs, empirical =
    emp_probs)
CSV.write(datadir("parameter_sweep", "summary.csv"), df)
println("Таблица сохранена в ", datadir("parameter_sweep",
    "summary.csv"))

using DrWatson
@quickactivate "project"
using Distributions, Plots, Random

Random.seed!(42)

# Нестационарный поток: интенсивность меняется в течение суток.
# Минимум ночью (~0 и ~24 ч), максимум днём (~12 ч).
λ_func(t) = 2.0 + 5.0 * sin(π * t / 12.0)
λ_max = 7.0  # максимальное значение λ(t) на [0, 24]
T = 24.0

# Метод прореживания (thinning):
# 1. Генерируем однородный поток с λ_max (верхняя граница).
# 2. Каждое событие в момент t принимаем с вероятностью λ(t)/λ_max.
# 3. Отвергнутые события просто удаляются.
# Результат — нестационарный поток с интенсивностью λ(t).
function simulate_nonstationary(λ_func, λ_max, T)
    attack_times = Float64[]
    t = 0.0
    while t < T
        τ = rand(Exponential(1 / λ_max))
        t += τ
        t > T && break
        # Принимаем событие с вероятностью λ(t)/λ_max
        if rand() < λ_func(t) / λ_max
            push!(attack_times, t)
        end
    end
    return attack_times
end

attack_times = simulate_nonstationary(λ_func, λ_max, T)

println("Всего атак за 24 ч: ", length(attack_times))

t_grid = 0:0.1:T
p1 = plot(t_grid, λ_func.(t_grid),
    label  = "λ(t) = 2 + 5·sin(πt/12)",
    xlabel = "Время (ч)", ylabel = "Интенсивность",
    lw = 2, title = "Нестационарный поток: интенсивность")
# Вертикальные линии показывают моменты атак
vline!(p1, attack_times, label = "Моменты атак", alpha = 0.4, color = :red)

p2 = plot(attack_times, 1:length(attack_times),
    label  = "Реализация",
    xlabel = "Время (ч)", ylabel = "Накопленное число атак",
    title  = "Нестационарный поток: накопленное число атак")

combined = plot(p1, p2, layout = (2, 1), size = (900, 700))
display(combined)
savefig(plotsdir("nonstationary_flow.png"))
println("График сохранён в ", plotsdir("nonstationary_flow.png"))

using DrWatson
@quickactivate "project"
using Distributions, Plots, StatsPlots

λ = 5.0    # атак/час
N = 100_000  # объём выборки для эмпирической оценки

# --- P(0 атак за смену 8 часов) ---
# За 8 ч число атак ~ Poisson(λ * 8)
# P(N = 0) = e^(-λ*8)
p_zero_theor = pdf(Poisson(λ * 8.0), 0)
samples_8h   = rand(Poisson(λ * 8.0), N)
p_zero_emp   = count(samples_8h .== 0) / N

println("P(0 атак за 8 ч):")
println("  Теоретическая = ", p_zero_theor)
println("  Эмпирическая  = ", p_zero_emp)

# --- P(≥3 атак за 30 минут) ---
# За 0.5 ч число атак ~ Poisson(λ * 0.5)
# P(N ≥ 3) = 1 - P(N ≤ 2)
p_three_theor = 1 - cdf(Poisson(λ * 0.5), 2)
samples_30m   = rand(Poisson(λ * 0.5), N)
p_three_emp   = count(samples_30m .>= 3) / N

println("P(≥3 атак за 30 мин):")
println("  Теоретическая = ", p_three_theor)
println("  Эмпирическая  = ", p_three_emp)

# Сравнение на графике
events    = ["P(0 за 8 ч)", "P(≥3 за 30 мин)"]
theor_val = [p_zero_theor, p_three_theor]
emp_val   = [p_zero_emp,   p_three_emp]

p_rare = groupedbar(
    [theor_val emp_val],
    xticks    = (1:2, events),
    label     = ["Теоретическая" "Эмпирическая"],
    ylabel    = "Вероятность",
    title     = "Вероятности редких событий (λ=$λ)",
    bar_width = 0.6)
display(p_rare)
savefig(plotsdir("rare_events.png"))
println("График сохранён в ", plotsdir("rare_events.png"))

using DrWatson
@quickactivate "project"
using Distributions, Plots, Statistics, Random

Random.seed!(42)

λ         = 5.0
threshold = 10
N         = 1000
B         = 10_000

sample   = rand(Poisson(λ), N)
emp_prob = count(sample .> threshold) / N
theor    = 1 - cdf(Poisson(λ), threshold)

boot_estimates = Float64[]
for _ in 1:B
    boot_sample = sample[rand(1:N, N)]
    push!(boot_estimates, count(boot_sample .> threshold) / N)
end

ci_low  = quantile(boot_estimates, 0.025)
ci_high = quantile(boot_estimates, 0.975)

println("Эмпирическая оценка:    ", emp_prob)
println("Теоретическое значение: ", theor)
println("95% ДИ (бутстреп):      [$ci_low, $ci_high]")

p = histogram(boot_estimates,
    bins      = 50,
    normalize = :pdf,
    label     = "Бутстреп-оценки",
    xlabel    = "Оценка P(>$threshold)",
    ylabel    = "Плотность",
    title     = "Бутстреп-распределение оценки P(>$threshold)")
vline!(p, [theor],
    label = "Теоретическое значение",
    lw = 2, color = :red, ls = :dash)
vline!(p, [ci_low, ci_high],
    label = "Границы 95% ДИ",
    lw = 2, color = :green, ls = :dot)

display(p)
savefig(p, plotsdir("bootstrap_ci.png"))
println("График сохранён в ", plotsdir("bootstrap_ci.png"))

using DrWatson
@quickactivate "project"
using Distributions, Plots, Random

Random.seed!(42)

λ = 5.0
p = 0.3
T = 24.0

λ_success = λ * p

println("λ исходный:  ", λ)
println("p успеха:    ", p)
println("λ успешных:  ", λ_success)

function simulate_thinned(λ, p, T)
    all_times     = Float64[]
    success_times = Float64[]
    t = 0.0
    while t < T
        τ = rand(Exponential(1 / λ))
        t += τ
        t > T && break
        push!(all_times, t)
        if rand() < p
            push!(success_times, t)
        end
    end
    return all_times, success_times
end

all_times, success_times = simulate_thinned(λ, p, T)

println("Всего атак:    ", length(all_times))
println("Успешных атак: ", length(success_times))

threshold = 5
p_theor   = 1 - cdf(Poisson(λ_success), threshold)
p_emp     = count(rand(Poisson(λ_success), 10_000) .> threshold) / 10_000
println("P(>$threshold успешных/час): теор=", p_theor, ", эмпир=", p_emp)

p1 = plot(all_times, 1:length(all_times),
    label  = "Все атаки (λ=$λ)",
    xlabel = "Время (ч)", ylabel = "Накопленное число атак",
    title  = "Все атаки и успешные (p=$p)")
plot!(p1, success_times, 1:length(success_times),
    label = "Успешные (λ·p=$λ_success)", lw = 2)

hourly_success = rand(Poisson(λ_success), 1000)
p2 = histogram(hourly_success,
    bins      = 0:maximum(hourly_success),
    normalize = :probability,
    label     = "Успешных атак за час",
    xlabel    = "Число атак", ylabel = "Вероятность",
    title     = "Распределение успешных атак (Пуассон(λ·p=$λ_success))")
x_vals = 0:maximum(hourly_success)
plot!(p2, x_vals, pdf.(Poisson(λ_success), x_vals),
    line   = :stem,
    marker = :circle,
    label  = "Теоретическое Пуассона(λ·p=$λ_success)",
    lw     = 2)

combined = plot(p1, p2, layout = (2, 1), size = (900, 700))
display(combined)
savefig(plotsdir("thinned_flow.png"))
println("График сохранён в ", plotsdir("thinned_flow.png"))

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
