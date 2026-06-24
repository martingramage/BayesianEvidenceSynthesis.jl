#src/numerical.jl
using QuadGK

struct NormalMixture
    weights::Vector{Float64}
    mus::Vector{Float64}
    sigmas::Vector{Float64}
end

"""
    prune_mixture(mix::NormalMixture; max_comp=10, weight_threshold=0.01)
Summarizes the mixture by removing negligible components and capping total count.
"""
function prune_mixture(mix::NormalMixture; max_comp::Int=10, weight_threshold::Float64=0.01)
    # Filter out components with negligible weights
    keep = findall(mix.weights .> weight_threshold)
    weights, mus, sigmas = mix.weights[keep], mix.mus[keep], mix.sigmas[keep]
    
    # Cap total components by selecting those with the highest weight
    if length(weights) > max_comp
        idx = sortperm(weights, rev=true)[1:max_comp]
        weights, mus, sigmas = weights[idx], mus[idx], sigmas[idx]
        weights ./= sum(weights) # Re-normalize
    end
    
    return NormalMixture(weights, mus, sigmas)
end

"""
    conditional_moments(tau, y, s)
Calculates the conditional posterior mean μ̂(τ) and standard deviation σ̂(τ).
"""
function conditional_moments(tau::Float64, y::Vector{Float64}, s::Vector{Float64})
    vars = s.^2 .+ tau^2
    prec = 1.0 ./ vars
    sum_prec = sum(prec)
    
    mu_hat = sum(y .* prec) / sum_prec
    sigma_hat = sqrt(1.0 / sum_prec)
    
    return mu_hat, sigma_hat
end

"""
    marginal_likelihood(tau, y, s)
Computes p(y | τ, σ) using log-scale for numerical stability.
"""
function marginal_likelihood(tau::Float64, y::Vector{Float64}, s::Vector{Float64})
    mu_hat, sigma_hat = conditional_moments(tau, y, s)
    vars = s.^2 .+ tau^2
    
    log_p = sum(-0.5 .* log.(vars)) - 0.5 * sum(((y .- mu_hat).^2) ./ vars) + log(sigma_hat)
    return exp(log_p)
end

"""
    half_normal_prior(tau, scale)
Conservative prior for the heterogeneity parameter τ.
"""
function half_normal_prior(tau::Float64, scale::Float64)
    tau < 0 && return 0.0
    return sqrt(2 / (pi * scale^2)) * exp(-tau^2 / (2 * scale^2))
end

"""
    compute_numerical_posterior(y, s; tau_scale=1.0, grid_points=100)
Orchestrates numerical integration and returns a pruned NormalMixture.
"""
function compute_numerical_posterior(y::Vector{Float64}, s::Vector{Float64}; tau_scale::Float64=1.0, grid_points::Int=100)
    unnormalized_posterior(tau) = marginal_likelihood(tau, y, s) * half_normal_prior(tau, tau_scale)
    
    # Integrate to normalize
    const_norm, _ = quadgk(unnormalized_posterior, 0.0, Inf, rtol=1e-8)
    
    # Discretize grid
    tau_grid = range(0.001, stop=5.0 * tau_scale, length=grid_points)
    step = tau_grid[2] - tau_grid[1]
    
    weights, mus, sigmas = zeros(grid_points), zeros(grid_points), zeros(grid_points)
    
    for (i, tau) in enumerate(tau_grid)
        density = unnormalized_posterior(tau) / const_norm
        mu_hat, sigma_hat = conditional_moments(tau, y, s)
        
        weights[i] = density * step
        mus[i] = mu_hat
        sigmas[i] = sigma_hat
    end
    
    weights ./= sum(weights)
    
    # Return pruned mixture to ensure concise PDF reporting
    return prune_mixture(NormalMixture(weights, mus, sigmas))
end