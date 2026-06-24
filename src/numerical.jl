# src/numerical.jl
using QuadGK

# Define a struct to hold the resulting parametric distribution
struct NormalMixture
    weights::Vector{Float64}
    mus::Vector{Float64}
    sigmas::Vector{Float64}
end

"""
    conditional_moments(tau, y, s)
Calculates the conditional posterior mean μ̂(τ) and standard deviation σ̂(τ).
"""
function conditional_moments(tau::Float64, y::Vector{Float64}, s::Vector{Float64})
    vars = s.^2 .+ tau^2
    precisions = 1.0 ./ vars
    sum_prec = sum(precisions)
    
    mu_hat = sum(y .* precisions) / sum_prec
    sigma_hat = sqrt(1.0 / sum_prec)
    
    return mu_hat, sigma_hat
end

"""
    marginal_likelihood(tau, y, s)
Computes p(y | τ, σ). Works on the log-scale internally for numerical stability, 
then exponentiates, preventing underflow issues with small variances.
"""
function marginal_likelihood(tau::Float64, y::Vector{Float64}, s::Vector{Float64})
    mu_hat, sigma_hat = conditional_moments(tau, y, s)
    k = length(y)
    
    vars = s.^2 .+ tau^2
    
    # Log-scale calculation of the formula to prevent underflow
    log_term1 = sum(-0.5 .* log.(vars))
    log_term2 = -0.5 * sum(((y .- mu_hat).^2) ./ vars)
    log_term3 = log(sigma_hat) # Equivalent to -0.5 * log(sum(1/vars))
    
    # We drop the (2π)^(-k/2) constant as it cancels out during normalization later
    return exp(log_term1 + log_term2 + log_term3)
end

"""
    half_normal_prior(tau, scale)
The default conservative prior for the heterogeneity parameter τ.
"""
function half_normal_prior(tau::Float64, scale::Float64)
    if tau < 0 
        return 0.0 
    end
    return sqrt(2 / (pi * scale^2)) * exp(-tau^2 / (2 * scale^2))
end

"""
    compute_numerical_posterior(y, s; tau_scale=1.0, grid_points=100)
Orchestrates the numerical integration using QuadGK and returns a NormalMixture.
"""
function compute_numerical_posterior(y::Vector{Float64}, s::Vector{Float64}; tau_scale::Float64=1.0, grid_points::Int=100)
    # 1. Define the unnormalized posterior function for τ
    unnormalized_posterior(tau) = marginal_likelihood(tau, y, s) * half_normal_prior(tau, tau_scale)
    
    # 2. Integrate over τ to find the normalizing constant using QuadGK
    # QuadGK uses adaptive Gauss-Kronrod quadrature, making it highly precise
    normalizing_constant, _ = quadgk(unnormalized_posterior, 0.0, Inf, rtol=1e-8)
    
    # 3. Create a discrete grid to approximate the continuous mixture
    # We calculate an effective upper bound where the posterior density drops to near zero
    upper_bound = 5.0 * tau_scale # A heuristic bound, can be optimized
    tau_grid = range(0.001, stop=upper_bound, length=grid_points)
    
    weights = zeros(grid_points)
    mus = zeros(grid_points)
    sigmas = zeros(grid_points)
    
    # 4. Populate the mixture components
    for (i, tau) in enumerate(tau_grid)
        density = unnormalized_posterior(tau) / normalizing_constant
        
        mu_hat, sigma_hat = conditional_moments(tau, y, s)
        
        # Weight is density * step_size (Trapezoidal approximation for the grid)
        step_size = tau_grid[2] - tau_grid[1]
        weights[i] = density * step_size
        mus[i] = mu_hat
        sigmas[i] = sigma_hat
    end
    
    # Ensure weights sum exactly to 1.0 due to grid discretization
    weights ./= sum(weights)
    
    return NormalMixture(weights, mus, sigmas)
end