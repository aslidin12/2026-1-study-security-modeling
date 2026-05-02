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