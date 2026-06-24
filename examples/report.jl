# examples/report.jl
using BayesianEvidenceSynthesis
using Distributions
using Plots

# 1. Create a sample clinical trial dataset
filepath = "sample_study_for_report.txt"
open(filepath, "w") do io
    println(io, "normal")
    println(io, "mean,sd,n")
    println(io, "0.5,0.1,10")
    println(io, "0.6,0.12,15")
    println(io, "0.45,0.08,20")
end

println("Running Inference Pipeline...")
results = run_inference_pipeline(filepath)

println("Calculating Metrics and Generating PDF...")

# 2. Calculate all three ESS methods
ess_elir_val   = ess_elir(results.posterior)
ess_moment_val = ess_moment(results.posterior)
ess_morita_val = ess_morita(results.posterior)

# 3. Universal Density Evaluator
function eval_density(mix, x)
    if hasproperty(mix, :alphas) 
        return sum(w * pdf(Beta(a, b), x) for (w, a, b) in zip(mix.weights, mix.alphas, mix.betas))
    else
        return sum(w * pdf(Normal(mu, sig), x) for (w, mu, sig) in zip(mix.weights, mix.mus, mix.sigmas))
    end
end

# 4. Determine Axis Limits
if hasproperty(results.posterior, :alphas)
    x_vals = range(0.001, 0.999, length=1000)
    x_label = "Response Scale (p)"
else
    mu_mean = sum(results.posterior.weights .* results.posterior.mus)
    x_vals = range(mu_mean - 2.5, mu_mean + 2.5, length=1000)
    x_label = "Effect Size (θ)"
end

# Evaluate the curves
y_map = [eval_density(results.posterior, x) for x in x_vals]
y_robust = [eval_density(results.robustified_posterior, x) for x in x_vals]

# 5. Build Top Panel: The Distributions Plot
p_dist = plot(x_vals, y_map, label="MAP Posterior", linewidth=2.5, color=:blue,
              title="Bayesian Prior Distribution Comparison", xlabel=x_label, ylabel="Density")
plot!(p_dist, x_vals, y_robust, label="Robustified MAP (20% Vague)", linewidth=2.5, color=:red, linestyle=:dash)

# 6. Build Bottom Panel: The ESS Table
table_text = """
---------------------------------------------------
           EFFECTIVE SAMPLE SIZE (ESS)
---------------------------------------------------
  Method                   Equivalent Patients
---------------------------------------------------
  ELIR (Recommended)     :  $ess_elir_val
  Moments Matching       :  $ess_moment_val
  Morita Method          :  $ess_morita_val
---------------------------------------------------
"""

p_table = plot(framestyle=:none, showaxis=false, grid=false, xticks=false, yticks=false)
annotate!(p_table, 0.15, 0.5, text(table_text, 11, :left, :courier, :black))

# 7. Combine and save
final_layout = plot(p_dist, p_table, layout=grid(2, 1, heights=[0.75, 0.25]), size=(700, 650))
savefig(final_layout, "Bayesian_Analysis_Report.pdf")

# Clean up
rm(filepath)
println("SUCCESS! Open 'Bayesian_Analysis_Report.pdf' to view your results.")