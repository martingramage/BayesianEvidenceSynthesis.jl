# src/mixfit.jl
using Optim
using Distributions
using ForwardDiff
using StatsFuns: loggamma

struct BetaMixture
    weights::Vector{Float64}
    alphas::Vector{Float64}
    betas::Vector{Float64}
end

"""
    fit_beta_mixture_em(p_samples, K)
Fits a Beta mixture of exactly K components using the Expectation-Maximization (EM) algorithm.
"""
function fit_beta_mixture_em(p_samples::Vector{Float64}, K::Int; max_iter=500, tol=1e-5)
    N = length(p_samples)
    p_safe = clamp.(p_samples, 1e-5, 1.0 - 1e-5)
    
    # Initialization
    weights = fill(1.0 / K, K)
    alphas = fill(2.0, K)
    betas = fill(2.0, K)
    
    if K > 1
        for k in 1:K
            mu = k / (K + 1)
            var = 0.05
            nu = max(mu * (1.0 - mu) / var - 1.0, 2.0)
            alphas[k] = mu * nu
            betas[k] = (1.0 - mu) * nu
        end
    end

    log_lik_old = -Inf
    resp = zeros(N, K)

    # EM Loop
    for iter in 1:max_iter
        # --- E-STEP ---
        for i in 1:N
            for k in 1:K
                resp[i, k] = weights[k] * pdf(Beta(alphas[k], betas[k]), p_safe[i])
            end
            row_sum = sum(resp[i, :])
            if row_sum > 0
                resp[i, :] ./= row_sum
            else
                resp[i, :] .= 1.0 / K 
            end
        end

        # --- M-STEP ---
        for k in 1:K
            W_k = sum(resp[:, k])
            weights[k] = W_k / N

            if W_k > 1e-5
                S1 = sum(resp[:, k] .* log.(p_safe)) / W_k
                S2 = sum(resp[:, k] .* log.(1.0 .- p_safe)) / W_k

                function m_step_obj(params)
                    a, b = exp(params[1]), exp(params[2])
                    return -(loggamma(a + b) - loggamma(a) - loggamma(b) + (a - 1.0) * S1 + (b - 1.0) * S2)
                end

                initial_x = [log(alphas[k]), log(betas[k])]
                
                # Manually define Exact Gradient and Hessian to bypass Optim's ADTypes dependency
                g! = (G, x) -> ForwardDiff.gradient!(G, m_step_obj, x)
                h! = (H, x) -> ForwardDiff.hessian!(H, m_step_obj, x)
                td = Optim.TwiceDifferentiable(m_step_obj, g!, h!, initial_x)

                # Run Newton-Raphson Optimization
                res = optimize(td, initial_x, Newton())
                
                alphas[k] = exp(Optim.minimizer(res)[1])
                betas[k] = exp(Optim.minimizer(res)[2])
            end
        end
        weights ./= sum(weights) 

        # Convergence Check
        log_lik_new = 0.0
        for i in 1:N
            dens = sum(weights[k] * pdf(Beta(alphas[k], betas[k]), p_safe[i]) for k in 1:K)
            log_lik_new += log(dens + 1e-10)
        end

        if abs(log_lik_new - log_lik_old) < tol
            break
        end
        log_lik_old = log_lik_new
    end

    nll = -log_lik_old
    return BetaMixture(weights, alphas, betas), nll
end

"""
    automixfit(p_samples; max_components=4, penalty=6.0)
Loops through multiple EM fits and selects the one with the lowest AIC.
"""
function automixfit(p_samples::Vector{Float64}; max_components::Int=4, penalty::Float64=6.0)
    best_aic = Inf
    best_mixture = nothing
    
    println("Running automixfit (EM + Newton-Raphson) up to $max_components components...")
    
    for k in 1:max_components
        mixture, nll = fit_beta_mixture_em(p_samples, k)
        num_params = 3 * k - 1
        aic = 2 * nll + penalty * num_params
        
        println("  -> K=$k | NLL: $(round(nll, digits=2)) | AIC: $(round(aic, digits=2))")
        
        if aic < best_aic
            best_aic = aic
            best_mixture = mixture
        end
    end
    
    selected_k = length(best_mixture.weights)
    println("Selected best model with $selected_k component(s) based on AIC.")
    return best_mixture
end