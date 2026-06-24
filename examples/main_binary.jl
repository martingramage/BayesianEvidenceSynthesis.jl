# examples/main_binary.jl
using BayesianEvidenceSynthesis

# Define path to binary study data
data_path = joinpath(@__DIR__, "study_data_binary.txt")

println("--- Starting Inference Pipeline (Binary Endpoint) ---")
println("Using data: $data_path")

# Execute inference pipeline
results = run_inference_pipeline(data_path)

# Display pipeline outputs
println("\n=== FINAL PIPELINE OUTPUTS ===")

# Posterior details
println("\n1. MAP Posterior (Beta Mixture Components):")
for i in 1:length(results.posterior.weights)
    println("   Comp $i: w=$(round(results.posterior.weights[i], digits=3)) | " *
            "α=$(round(results.posterior.alphas[i], digits=2)) | " *
            "β=$(round(results.posterior.betas[i], digits=2))")
end

# ESS Analytics
println("\n2. Effective Sample Size (ESS):")
println("   ELIR    : ", round(ess_elir(results.posterior), digits=2))
println("   Moments : ", round(ess_moment(results.posterior), digits=2))
println("   Morita  : ", round(ess_morita(results.posterior), digits=2))

# Robustification check
println("\n3. Robustified Posterior (Final Component 'robust'):")
weights = round.(results.robustified_posterior.weights, digits=3)
println("   Weights: ", weights)