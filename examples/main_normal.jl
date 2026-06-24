# examples/main_normal.jl
using BayesianEvidenceSynthesis

# 1. Create a sample clinical trial dataset (Continuous/Normal Endpoint)
filepath = "sample_normal_study.txt"
open(filepath, "w") do io
    println(io, "normal")
    println(io, "mean,sd,n")
    println(io, "0.5,0.1,10")
    println(io, "0.6,0.12,15")
    println(io, "0.45,0.08,20")
end

println("--- Starting Inference Pipeline (Normal Endpoint) ---")

# 2. Run the pipeline!
results = run_inference_pipeline(filepath)

# 3. View the Outputs
println("\n=== FINAL PIPELINE OUTPUTS ===")

println("\n1. MAP Posterior (Normal Mixture Components):")
println("   Weights: ", round.(results.posterior.weights, digits=3))
println("   Means:   ", round.(results.posterior.mus, digits=3))
println("   Sigmas:  ", round.(results.posterior.sigmas, digits=3))

println("\n2. Effective Sample Size (ESS via ELIR):")
println("   Equivalent to: ", results.ess, " patients")

println("\n3. Robustified Posterior (Mitigating Prior-Data Conflict):")
println("   Weights: ", round.(results.robustified_posterior.weights, digits=3))
println("   Means:   ", round.(results.robustified_posterior.mus, digits=3))

# Clean up the sample file
rm(filepath)