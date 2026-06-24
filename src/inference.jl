# src/inference.jl

function run_inference_pipeline(input_path::String)
    input = parse_input_file(input_path)
    
    # 1. Compute Posterior
    posterior = compute_posterior(input)
    
    # 2. Calculate Effective Sample Size (ESS)
    ess = ess_elir(posterior)
    
    # 3. Robustify to mitigate prior-data conflict
    robustified = robustify(posterior)
    
    # Output the required triad
    return (posterior = posterior, ess = ess, robustified_posterior = robustified)
end

function compute_posterior(input::ClinicalStudyInput)
    if input.endpoint_type == :binary
        println("Running Exact MCMC Inference (Turing.jl) for binary endpoint...")
        r = input.data.r
        n = input.data.n
        mixture = compute_mcmc_posterior(r, n, tau_scale=1.0, n_samples=2000)
        println("Successfully generated Beta Mixture via MCMC: Weights $(round.(mixture.weights, digits=3))")
        return mixture
        
    elseif input.endpoint_type == :normal
        println("Running Numerical Integration Strategy for normal endpoint...")
        y = input.data.mean
        s = input.data.sd
        mixture = compute_numerical_posterior(y, s, tau_scale=1.0, grid_points=100)
        println("Successfully generated Normal Mixture via Numerical Integration")
        return mixture
        
    else
        error("Unsupported endpoint type: $(input.endpoint_type)")
    end
end