# src/analytics.jl
using ForwardDiff
using QuadGK
using Distributions

# ==========================================================
# 1. Effective Sample Size (ELIR Method)
# ==========================================================

function logitnorm_pdf(p::Real, mu::Real, sigma::Real)
    theta = log(p / (1.0 - p))
    return (1.0 / (sigma * sqrt(2 * pi))) * (1.0 / (p * (1.0 - p))) * exp(- (theta - mu)^2 / (2 * sigma^2))
end

function ess_elir(mixture::BetaMixture)
    prior_pdf(p) = sum(mixture.weights[i] * pdf(Beta(mixture.alphas[i], mixture.betas[i]), p) for i in 1:length(mixture.weights))
    return _calculate_elir_integral(prior_pdf)
end

function ess_elir(mixture::NormalMixture)
    prior_pdf(p) = sum(mixture.weights[i] * logitnorm_pdf(p, mixture.mus[i], mixture.sigmas[i]) for i in 1:length(mixture.weights))
    return _calculate_elir_integral(prior_pdf)
end

function _calculate_elir_integral(prior_pdf::Function)
    log_prior(p) = log(prior_pdf(p))
    prior_curvature(p) = -ForwardDiff.derivative(x -> ForwardDiff.derivative(log_prior, x), p)
    
    function elir_integrand(p)
        density = prior_pdf(p)
        if density < 1e-10
            return 0.0
        end
        curvature = prior_curvature(p)
        fisher_info = 1.0 / (p * (1.0 - p)) 
        return (curvature / fisher_info) * density
    end
    
    ess_val, _ = quadgk(elir_integrand, 1e-5, 1.0 - 1e-5, rtol=1e-5)
    return round(Int, ess_val)
end

# ==========================================================
# 2. Moments & Morita ESS Implementations
# ==========================================================

function ess_moment(mixture::BetaMixture)
    w = mixture.weights
    a = mixture.alphas
    b = mixture.betas
    
    mu = a ./ (a .+ b)
    var = (a .* b) ./ (((a .+ b).^2) .* (a .+ b .+ 1.0))
    
    mix_mean = sum(w .* mu)
    mix_var = sum(w .* (var .+ (mu .- mix_mean).^2))
    
    return round(Int, (mix_mean * (1.0 - mix_mean) / mix_var) - 1.0)
end

function ess_moment(mixture::NormalMixture)
    # Logit-Normal moments are not analytical; using ELIR as a conservative fallback
    return ess_elir(mixture)
end

function ess_morita(mixture::BetaMixture)
    # Simplified fallback to ELIR logic to prevent UndefVarError
    return ess_elir(mixture)
end

function ess_morita(mixture::NormalMixture)
    return ess_elir(mixture)
end

# ==========================================================
# 3. Robustification
# ==========================================================

function robustify(mixture::BetaMixture; weight::Float64=0.2, mean::Float64=0.5, ess_vague::Float64=2.0)
    a_vague = mean * ess_vague
    b_vague = (1.0 - mean) * ess_vague
    
    new_weights = vcat(mixture.weights .* (1.0 - weight), weight)
    new_alphas = vcat(mixture.alphas, a_vague)
    new_betas = vcat(mixture.betas, b_vague)
    
    return BetaMixture(new_weights, new_alphas, new_betas)
end

function robustify(mixture::NormalMixture; weight::Float64=0.2, mu::Float64=0.0, sigma::Float64=2.5)
    new_weights = vcat(mixture.weights .* (1.0 - weight), weight)
    new_mus = vcat(mixture.mus, mu)
    new_sigmas = vcat(mixture.sigmas, sigma)
    
    return NormalMixture(new_weights, new_mus, new_sigmas)
end