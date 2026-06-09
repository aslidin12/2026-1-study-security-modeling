using LinearAlgebra
using DataFrames, CSV
using DrWatson

# Строит платёжные матрицы A (атакующий) и D (защитник)
# для n объектов с ценностями V, стоимостями атаки c_a и защиты c_d.
# i — узел атаки, j — узел защиты:
#   если i != j: атакующий получает V[i]-c_a, защитник теряет V[i]+c_d
#   если i == j: атака отражена, оба несут только затраты
function build_payoff_matrices(V::Vector{Float64}, c_a::Float64, c_d::Float64)
    n = length(V)
    A = zeros(n, n)
    D = zeros(n, n)
    for i = 1:n, j = 1:n
        if i != j
            A[i, j] = V[i] - c_a
            D[i, j] = -V[i] - c_d
        else
            A[i, j] = -c_a
            D[i, j] = -c_d
        end
    end
    return A, D
end

# Находит равновесие Нэша в игре 2×2.
# Сначала проверяет чистые стратегии (седловая точка),
# затем вычисляет смешанные через условие безразличия.
function mixed_nash_2x2(A::Matrix{Float64}, D::Matrix{Float64})
    for i = 1:2, j = 1:2
        if A[i, j] >= A[3-i, j] && D[i, j] >= D[i, 3-j]
            p = zeros(2); p[i] = 1.0
            q = zeros(2); q[j] = 1.0
            return (p = p, q = q, type = "pure")
        end
    end
    denomA = (A[1,1] - A[2,1]) - (A[1,2] - A[2,2])
    q1 = abs(denomA) > 1e-10 ? clamp((A[2,2] - A[1,2]) / denomA, 0.0, 1.0) : 0.5
    q = [q1, 1 - q1]
    denomD = (D[1,1] - D[1,2]) - (D[2,1] - D[2,2])
    p1 = abs(denomD) > 1e-10 ? clamp((D[2,2] - D[2,1]) / denomD, 0.0, 1.0) : 0.5
    p = [p1, 1 - p1]
    return (p = p, q = q, type = "mixed")
end

# Запускает один эксперимент для заданного набора параметров,
# возвращает словарь с результатами (стратегии, тип равновесия, выигрыши).
function run_simulation(params::Dict)
    V = params["V"]; c_a = params["c_a"]; c_d = params["c_d"]
    A, D = build_payoff_matrices(V, c_a, c_d)
    eq = mixed_nash_2x2(A, D)
    if eq.type == "pure"
        i = argmax(eq.p); j = argmax(eq.q)
        UA = A[i, j]; UD = D[i, j]
    else
        UA = eq.p' * A * eq.q; UD = eq.p' * D * eq.q
    end
    return Dict("p_1"=>eq.p[1], "p_2"=>eq.p[2], "q_1"=>eq.q[1], "q_2"=>eq.q[2],
                "type"=>eq.type, "UA"=>UA, "UD"=>UD, "V1"=>V[1], "V2"=>V[2],
                "c_a"=>c_a, "c_d"=>c_d)
end

# Генерирует сетку параметров: 3 значения V1, 3 значения V2,
# 3 значения c_a, 3 значения c_d → 81 комбинация.
function generate_params()
    dicts = []
    for v1 in [5.0, 10.0, 15.0], v2 in [5.0, 10.0, 15.0]
        for c_a in [0.0, 1.0, 3.0], c_d in [0.0, 1.0, 3.0]
            push!(dicts, Dict("V" => [v1, v2], "c_a" => c_a, "c_d" => c_d))
        end
    end
    return dicts
end

# Прогоняет все комбинации параметров, собирает результаты в DataFrame
# и сохраняет в data/sims/results.csv.
function main_simulations()
    params_list = generate_params()
    rows = [run_simulation(p) for p in params_list]
    results = DataFrame(rows)
    mkpath(datadir("sims"))
    CSV.write(datadir("sims", "results.csv"), results)
    return results
end

# Загружает сохранённые результаты из CSV.
function load_results()
    path = datadir("sims", "results.csv")
    isfile(path) ? CSV.read(path, DataFrame) : error("File not found. Run main_simulations() first.")
end

# Расширенная матрица 3×3: добавляет стратегии «не атаковать» и «не защищать».
function build_payoff_matrices_3x3(V::Vector{Float64}, c_a::Float64, c_d::Float64)
    A = zeros(3, 3)
    D = zeros(3, 3)
    for i = 1:2, j = 1:2
        if i != j
            A[i, j] = V[i] - c_a
            D[i, j] = -V[i] - c_d
        else
            A[i, j] = -c_a
            D[i, j] = -c_d
        end
    end
    for j = 1:3
        A[3, j] = 0.0
        D[3, j] = j <= 2 ? -c_d : 0.0
    end
    for i = 1:2
        A[i, 3] = V[i] - c_a
        D[i, 3] = -V[i]
    end
    return A, D
end
