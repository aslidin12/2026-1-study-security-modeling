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

function build_attack_graph(n, edge_prob, vulnerabilities, trust_relations)
    g = SimpleDiGraph(n)
    for i = 1:n, j = 1:n
        if i != j && rand() < edge_prob
            add_edge!(g, i, j)
        end
    end
    for (u, v) in trust_relations
        add_edge!(g, u, v)
    end
    return g
end

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