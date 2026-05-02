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