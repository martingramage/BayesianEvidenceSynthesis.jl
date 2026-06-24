# server.jl
using Oxygen
using HTTP
using BayesianEvidenceSynthesis
using Distributions
using Plots

"""
Evaluates the probability density of a mixture model at point x.
"""
function eval_density(mix, x)
    if hasproperty(mix, :alphas) 
        return sum(w * Distributions.pdf(Beta(a, b), x) for (w, a, b) in zip(mix.weights, mix.alphas, mix.betas))
    else
        return sum(w * Distributions.pdf(Normal(mu, sig), x) for (w, mu, sig) in zip(mix.weights, mix.mus, mix.sigmas))
    end
end

"""
Formats a mixture model into a labeled table string.
"""
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

@post "/generate_report" function(req::HTTP.Request)
    println("--> Received new request for a PDF report...")
    
    temp_file = "temp_upload_$(time_ns()).txt"
    write(temp_file, req.body)
    
    try
        results = run_inference_pipeline(temp_file)
        
        # Data aggregation
        ess_elir_val   = ess_elir(results.posterior)
        ess_moment_val = ess_moment(results.posterior)
        ess_morita_val = ess_morita(results.posterior)
        
        # Configure plotting based on distribution type
        if hasproperty(results.posterior, :alphas)
            x_vals = range(0.001, 0.999, length=1000)
            x_label = "Response Scale (p)"
        else
            mu_mean = sum(results.posterior.weights .* results.posterior.mus)
            x_vals = range(mu_mean - 2.5, mu_mean + 2.5, length=1000)
            x_label = "Effect Size (θ)"
        end
        
        # Plot distributions
        y_map = [eval_density(results.posterior, x) for x in x_vals]
        y_robust = [eval_density(results.robustified_posterior, x) for x in x_vals]
        
        p_dist = plot(x_vals, y_map, label="MAP Posterior", linewidth=2.5, color=:blue,
                      title="Prior Distribution Comparison", xlabel=x_label, ylabel="Density",
                      bottom_margin=10Plots.mm)
        plot!(p_dist, x_vals, y_robust, label="Robustified MAP", linewidth=2.5, color=:red, linestyle=:dash)
        
        # Dynamic layout: Adjust grid height if number of components is large
        num_comp = length(results.posterior.weights)
        layout_heights = (num_comp > 10) ? [0.25, 0.75] : [0.4, 0.6]
        
        # Construct tabular report text
        full_text = format_mixture_table(results.posterior, "POSTERIOR") *
                    "ESS (ELIR): $ess_elir_val | Moments: $ess_moment_val | Morita: $ess_morita_val\n\n" *
                    format_mixture_table(results.robustified_posterior, "ROBUSTIFIED")
        
        # Annotate text area with vertical spacing
        p_text = plot(framestyle=:none, showaxis=false, grid=false, xticks=false, yticks=false, ylim=(0, 1.0))
        annotate!(p_text, 0.05, 0.95, Plots.text(full_text, 8, :left, :top, :courier, :black))
        
        # Save to PDF with increased canvas size for better vertical rendering
        final_layout = plot(p_dist, p_text, layout=grid(2, 1, heights=layout_heights), size=(800, 1500))
        plot!(final_layout, bottom_margin=5Plots.mm, top_margin=5Plots.mm)
        
        output_pdf = "Report_$(time_ns()).pdf"
        savefig(final_layout, output_pdf)
        
        pdf_bytes = read(output_pdf)
        
        # Cleanup
        rm(temp_file, force=true)
        rm(output_pdf, force=true)
        
        println("--> Success! Sending PDF back to client.")
        return HTTP.Response(200, ["Content-Type" => "application/pdf"], body=pdf_bytes)
        
    catch e
        rm(temp_file, force=true)
        println("--> Error processing request: ", e)
        return HTTP.Response(500, "Server Error: Ensure data format integrity.")
    end
end

# Ask Render which port it wants to use
render_port = parse(Int, get(ENV, "PORT", "8080"))

# Print a message so we know when it reaches this point
println("Libraries loaded! Starting server on 0.0.0.0:$render_port...")

# Start the server
serve(host="0.0.0.0", port=render_port, cors=true)