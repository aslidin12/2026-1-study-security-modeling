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