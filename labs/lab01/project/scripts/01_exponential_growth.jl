# # Экспоненциальный рост
# **Цель:** Исследовать решение уравнения 𝑑𝑢/𝑑𝑡 = 𝛼𝑢.
#
# ## Инициализация проекта и загрузка пакетов
using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
# ## Определение модели
# Уравнение экспоненциального роста:
# 𝑑𝑢/𝑑𝑡 = 𝛼𝑢, 𝑢(0) = 𝑢₀
function exponential_growth!(du, u, p, t)
    α = p
    du[1] = α * u[1]
end

# ## Первый запуск с параметрами по умолчанию
# Зададим начальные параметры:
u0 = [1.0] # начальная популяция
α = 0.3 # скорость роста
tspan = (0.0, 10.0) # временной интервал
prob = ODEProblem(exponential_growth!, u0, tspan, α)
sol = solve(prob, Tsit5(), saveat=0.1)

# ## Визуализация результатов
# Построим график решения:
plot(sol, label="u(t)", xlabel="Время t", ylabel="Популяция u",
title="Экспоненциальный рост (α = $α)", lw=2, legend=:topleft)

# Сохраним график в папку plots
savefig(plotsdir("exponential_growth_α=$α.png"))

# ## Анализ результатов
# Создадим таблицу с данными:
df = DataFrame(t=sol.t, u=first.(sol.u))
println("Первые 5 строк результатов:")
println(first(df, 5))

# Вычислим удвоение популяции:
u_final = last(sol.u)[1]
doubling_time = log(2) / α

# ## Сохранение всех результатов
println("\nАналитическое время удвоения: ", round(doubling_time; digits=2))