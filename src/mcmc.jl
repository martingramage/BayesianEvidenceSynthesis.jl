# src/mcmc.jl
using Turing
using Distributions
using StatsFuns: logistic 

@model function binary_meta_analysis(r::Vector{Int}, n::Vector{Int}, tau_scale::Float64)
    mu ~ Normal(0.0, 2.0)
    tau ~ truncated(Normal(0.0, tau_scale), lower=0.0) 
    
    k = length(r)
    theta ~ filldist(Normal(mu, tau), k)
    
    for i in 1:k
        p_i = logistic(theta[i])
        r[i] ~ Binomial(n[i], p_i)
    end
end

function compute_mcmc_posterior(r::Vector{Int}, n::Vector{Int}; tau_scale::Float64=1.0, n_samples::Int=4000)
    model = binary_meta_analysis(r, n, tau_scale)
    println("Sampling via HMC (NUTS)...")
    chain = sample(model, NUTS(0.85), n_samples, progress=false)
    
    # Flatten outputs safely
    mu_samples = vec(chain[:mu])
    tau_samples = vec(chain[:tau])
    
    # Generate predictive distribution
    theta_predictive = rand.(Normal.(mu_samples, tau_samples))
    p_predictive = logistic.(theta_predictive)
    
    # Delegate the mathematical fitting to mixfit.jl
    mixture = automixfit(p_predictive, max_components=4, penalty=6.0) 
    
    return mixture
end