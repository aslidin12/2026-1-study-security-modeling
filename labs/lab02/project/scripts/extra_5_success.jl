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