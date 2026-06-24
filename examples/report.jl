# examples/report.jl
using BayesianEvidenceSynthesis
using Distributions
using Plots

# 1. Prepare sample clinical trial dataset
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

# 2. Reusable table formatting function
function format_mixture_table(mix, label::String)
    table = "--- $label ---\n"
    table *= "MIXTURE COMPONENTS (Weights | Parameters)\n"
    table *= "---------------------------------------------------\n"
    is_beta = hasproperty(mix, :alphas)
    num_comp = length(mix.weights)
    for i in 1:num_comp
        w = round(mix.weights[i], digits=3)
        comp_name = (label == "ROBUSTIFIED" && i == num_comp) ? "robust" : "Comp $i"
        if is_beta
            m1 = round(mix.alphas[i], digits=2)
            m2 = round(mix.betas[i], digits=2)
            table *= "$comp_name: $w | Alpha: $m1 ; Beta: $m2\n"
        else
            m1 = round(mix.mus[i], digits=3)
            m2 = round(mix.sigmas[i], digits=3)
            table *= "$comp_name: $w | Mean: $m1 ; Sig: $m2\n"
        end
    end
    return table * "\n"
end

# 3. Analytics and Axis Setup
ess_elir_val   = ess_elir(results.posterior)
ess_moment_val = ess_moment(results.posterior)
ess_morita_val = ess_morita(results.posterior)

if hasproperty(results.posterior, :alphas)
    x_vals = range(0.001, 0.999, length=1000)
    x_label = "Response Scale (p)"
else
    mu_mean = sum(results.posterior.weights .* results.posterior.mus)
    x_vals = range(mu_mean - 2.5, mu_mean + 2.5, length=1000)
    x_label = "Effect Size (θ)"
end

# 4. Generate Density Curves
y_map = [eval_density(results.posterior, x) for x in x_vals]
y_robust = [eval_density(results.robustified_posterior, x) for x in x_vals]

p_dist = plot(x_vals, y_map, label="MAP Posterior", linewidth=2.5, color=:blue,
              title="Prior Distribution Comparison", xlabel=x_label, ylabel="Density",
              bottom_margin=10Plots.mm)
plot!(p_dist, x_vals, y_robust, label="Robustified MAP", linewidth=2.5, color=:red, linestyle=:dash)

# 5. Construct Report Text: Posterior -> ESS -> Robustified
table_post = format_mixture_table(results.posterior, "POSTERIOR")
ess_text   = "ESS (ELIR): $ess_elir_val | Moments: $ess_moment_val | Morita: $ess_morita_val"
table_rob  = format_mixture_table(results.robustified_posterior, "ROBUSTIFIED")

full_text = table_post * "\n" * ess_text * "\n\n" * table_rob

# 6. Render Text Panel and Final Layout
p_text = plot(framestyle=:none, showaxis=false, grid=false, xticks=false, yticks=false)
annotate!(p_text, 0, 0.95, Plots.text(full_text, 8, :left, :courier, :black))

final_layout = plot(p_dist, p_text, layout=grid(2, 1, heights=[0.4, 0.6]), size=(800, 1100))
savefig(final_layout, "Bayesian_Analysis_Report.pdf")

# 7. Cleanup
rm(filepath, force=true)
println("SUCCESS! Open 'Bayesian_Analysis_Report.pdf' to view your results.")