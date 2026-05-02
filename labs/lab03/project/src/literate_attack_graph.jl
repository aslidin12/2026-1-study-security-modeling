```julia
# # Модуль моделирования графов атак
# 
# ## Назначение модуля
# 
# Данный модуль содержит все основные функции для работы с графами атак:
# - построение графа атак
# - поиск всех возможных путей атаки
# - вычисление метрик центральности (PageRank, in-degree и др.)
# - оценка вероятности успешной атаки
# 
# ## Математическая модель
# 
# Граф атак — это ориентированный граф G = (V, E), где:
# - V = {v1, v2, ..., vn} — множество узлов сети
# - E ⊆ V × V — множество возможных атак
# 
# Ребро (u, v) ∈ E означает, что атакующий, получив доступ к узлу u,
# может атаковать узел v.

module AttackGraph

using Graphs
using LinearAlgebra
using Random

export build_attack_graph,
       find_all_paths,
       compute_centrality_metrics,
       assign_edge_weights,
       most_likely_path,
       simple_pagerank
# ## 1. Построение графа атак
# 
# ### Функция build_attack_graph
# 
# Создаёт ориентированный граф атак с заданными параметрами.
# 
# Аргументы:
# - n: количество узлов в сети
# - edge_prob: вероятность существования ребра между двумя узлами
# - vulnerabilities: словарь уязвимостей (задел на будущее)
# - trust_relations: список доверительных отношений в виде кортежей (u, v)

function build_attack_graph(n, edge_prob, vulnerabilities, trust_relations)
    g = SimpleDiGraph(n)
    
    for i = 1:n
        for j = 1:n
            if i != j && rand() < edge_prob
                add_edge!(g, i, j)
            end
        end
    end
    
    for (u, v) in trust_relations
        add_edge!(g, u, v)
    end
    
    return g
end

# ## 2. Поиск всех путей атаки
# 
# ### Функция find_all_paths
# 
# Находит все простые пути от источника к цели.
# Используется рекурсивный поиск в глубину (DFS).

function find_all_paths(g, source, target)
    paths = []
    
    function dfs(current, path)
        if current == target
            push!(paths, copy(path))
            return
        end
        
        for neighbor in outneighbors(g, current)
            if !(neighbor in path)
                push!(path, neighbor)
                dfs(neighbor, path)
                pop!(path)
            end
        end
    end
    
    dfs(source, [source])
    return paths
end

# ## 3. Метрики центральности
# 
# ### Функция compute_centrality_metrics
# 
# Вычисляет основные метрики важности узлов:
# - in_degree: количество входящих рёбер (сколько атак ведёт к узлу)
# - out_degree: количество исходящих рёбер (сколько атак исходит из узла)
# - betweenness: доля кратчайших путей, проходящих через узел
# - closeness: обратное среднее расстояние до всех других узлов
# - pagerank: важность узла с учётом важности ссылающихся узлов

function compute_centrality_metrics(g)
    indeg = indegree(g)
    outdeg = outdegree(g)
    betweenness = betweenness_centrality(g)
    closeness = closeness_centrality(g)
    pagerank = simple_pagerank(g)
    
    return Dict(
        :in_degree => indeg,
        :out_degree => outdeg,
        :betweenness => betweenness,
        :closeness => closeness,
        :pagerank => pagerank,
    )
end

# ### Функция simple_pagerank
# 
# Простая реализация алгоритма PageRank.
# 
# Формула:
# PR(v) = (1-d)/N + d * sum(PR(u) / L(u))
# 
# где:
# - d = 0.85 — фактор затухания
# - N — количество узлов
# - L(u) — количество исходящих ссылок из u

function simple_pagerank(g; α=0.85, max_iter=100, tol=1e-6)
    n = nv(g)
    n == 0 && return Float64[]
    
    pr = fill(1.0 / n, n)
    
    for _ in 1:max_iter
        pr_new = fill((1 - α) / n, n)
        
        for i in 1:n
            outdeg = outdegree(g, i)
            if outdeg > 0
                for j in outneighbors(g, i)
                    pr_new[j] += α * pr[i] / outdeg
                end
            else
                for j in 1:n
                    pr_new[j] += α * pr[i] / n
                end
            end
        end
        
        diff = maximum(abs.(pr_new - pr))
        pr = pr_new
        if diff < tol
            break
        end
    end
    
    return pr
end

# ## 4. Оценка вероятностей атак
# 
# ### Функция assign_edge_weights
# 
# Присваивает каждому ребру вес (вероятность успешной атаки).

function assign_edge_weights(g, cvss_scores)
    weights = Dict{Graphs.Edge, Float64}()
    
    for e in edges(g)
        u, v = src(e), dst(e)
        key = (u, v)
        weight = get(cvss_scores, key, 0.5)
        weights[e] = weight
    end
    
    return weights
end

# ### Функция most_likely_path
# 
# Находит путь с максимальной вероятностью успеха.
# 
# Вероятность успеха по пути:
# P = prod(p_uv) для всех рёбер (u,v) в пути
# 
# Для поиска используется алгоритм Дейкстры с весом w = -ln(p_uv).

function most_likely_path(g, source, target, weights)
    n = nv(g)
    
    distmx = fill(Inf, n, n)
    for e in edges(g)
        u, v = src(e), dst(e)
        w = weights[e]
        w = max(w, 1e-10)
        distmx[u, v] = -log(w)
    end
    
    state = dijkstra_shortest_paths(g, source, distmx)
    
    if state.dists[target] == Inf
        return [], 0.0
    end
    
    path = Int[]
    current = target
    while current != source
        push!(path, current)
        current = state.parents[current]
    end
    push!(path, source)
    reverse!(path)
    
    probability = exp(-state.dists[target])
    
    return path, probability
end

end
```