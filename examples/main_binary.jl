# examples/main_binary.jl
using BayesianEvidenceSynthesis

# 1. Create a sample clinical trial dataset (Binary Endpoint)
filepath = "sample_binary_study.txt"
open(filepath, "w") do io
    println(io, "binary")
    println(io, "r,n")
    println(io, "2,10")
    println(io, "5,20")
    println(io, "3,15")
end

println("--- Starting Inference Pipeline (Binary Endpoint) ---")

# 2. Run the pipeline!
results = run_inference_pipeline(filepath)

# 3. View the Outputs
println("\n=== FINAL PIPELINE OUTPUTS ===")

println("\n1. MAP Posterior (Beta Mixture Components):")
println("   Weights: ", round.(results.posterior.weights, digits=3))
println("   Alphas:  ", round.(results.posterior.alphas, digits=3))
println("   Betas:   ", round.(results.posterior.betas, digits=3))

println("\n2. Effective Sample Size (ESS via ELIR):")
println("   Equivalent to: ", results.ess, " patients")

println("\n3. Robustified Posterior (Mitigating Prior-Data Conflict):")
println("   Weights: ", round.(results.robustified_posterior.weights, digits=3))
println("   Alphas:  ", round.(results.robustified_posterior.alphas, digits=3))

# Clean up the sample file
rm(filepath)