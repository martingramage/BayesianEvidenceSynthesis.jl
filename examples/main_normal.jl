# examples/main_normal.jl
using BayesianEvidenceSynthesis

# Define path to normal study data
data_path = joinpath(@__DIR__, "study_data_normal.txt")

println("--- Starting Inference Pipeline (Normal Endpoint) ---")
println("Using data: $data_path")

# Execute inference pipeline
results = run_inference_pipeline(data_path)

# Display pipeline outputs
println("\n=== FINAL PIPELINE OUTPUTS ===")

# Posterior details
println("\n1. MAP Posterior (Normal Mixture Components):")
for i in 1:length(results.posterior.weights)
    println("   Comp $i: w=$(round(results.posterior.weights[i], digits=3)) | " *
            "μ=$(round(results.posterior.mus[i], digits=3)) | " *
            "σ=$(round(results.posterior.sigmas[i], digits=3))")
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