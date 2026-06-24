# src/mcmc.jl
using Turing
using Distributions
using StatsFuns: logistic 

@model function binary_meta_analysis(r::Vector{Int}, n::Vector{Int}, tau_scale::Float64)
    mu ~ Normal(0.0, 2.0)
    tau ~ truncated(Normal(0.0, tau_scale), lower=0.0) 
    
    k = length(r)
    
    # Non-centered parameterization for stable HMC sampling
    theta_offset ~ filldist(Normal(0.0, 1.0), k)
    theta = mu .+ theta_offset .* tau
    
    for i in 1:k
        p_i = logistic(theta[i])
        r[i] ~ Binomial(n[i], p_i)
    end
end

"""
    compute_mcmc_posterior(r, n; tau_scale=1.0, n_samples=4000)

Performs Bayesian hierarchical inference via NUTS, utilizing a non-centered 
parameterization for numerical stability and Stan-equivalent adaptation.
"""
function compute_mcmc_posterior(r::Vector{Int}, n::Vector{Int}; tau_scale::Float64=1.0, n_samples::Int=4000)
    model = binary_meta_analysis(r, n, tau_scale)
    
    # Stan-equivalent configuration: adapt_delta=0.99, max_depth=12
    sampler = NUTS(0.99; max_depth=12)
    chain = sample(model, sampler, n_samples, progress=false)
    
    mu_samples = vec(chain[:mu])
    tau_samples = vec(chain[:tau])
    
    # Posterior predictive simulation
    theta_predictive = mu_samples .+ randn(length(mu_samples)) .* tau_samples
    p_predictive = logistic.(theta_predictive)
    
    return automixfit(p_predictive, max_components=4, penalty=6.0)
end