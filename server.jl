#server.jl
using Oxygen
using HTTP
using BayesianEvidenceSynthesis
using Distributions
using Plots
using DataFrames
using Dates
using Typst_jll
using UUIDs

# Frontend route to serve the index.html file for the web interface
@get "/" function()
    return html(read("index.html", String))
end

"""
Evaluates the probability density of a mixture model at point x.
"""
function eval_density(mix, x)
    if hasproperty(mix, :alphas)
        return sum(
            w * Distributions.pdf(Beta(a, b), x)
            for (w, a, b) in zip(mix.weights, mix.alphas, mix.betas)
        )
    else
        return sum(
            w * Distributions.pdf(Normal(mu, sig), x)
            for (w, mu, sig) in zip(mix.weights, mix.mus, mix.sigmas)
        )
    end
end

"""
Convert mixture model into DataFrame.
"""
function mixture_dataframe(mix; robustified=false)
    is_beta = hasproperty(mix, :alphas)
    n = length(mix.weights)

    component = [robustified && i == n ? "Robust" : "Comp $i" for i in 1:n]

    if is_beta
        return DataFrame(
            Component = component,
            Weight = round.(mix.weights, digits=3),
            Alpha = round.(mix.alphas, digits=3),
            Beta = round.(mix.betas, digits=3)
        )
    else
        return DataFrame(
            Component = component,
            Weight = round.(mix.weights, digits=3),
            Mean = round.(mix.mus, digits=3),
            Sigma = round.(mix.sigmas, digits=3)
        )
    end
end

"""
Convert DataFrame to Typst table.
"""
function dataframe_to_typst(df::DataFrame)
    headers = ["[$(n)]" for n in names(df)]
    body = String[]

    for row in eachrow(df)
        for value in row
            push!(body, "[$value]")
        end
    end

    ncols = ncol(df)

    return """
#table(
  columns: $ncols,
  stroke: 0.5pt,

  $(join(headers, ",\n")),

  $(join(body, ",\n"))
)
"""
end

"""
Create Typst report.
"""
function build_typst_report(
    report_file,
    plot_file,
    posterior_df,
    robust_df,
    ess_elir,
    ess_moment,
    ess_morita
)
    open(report_file, "w") do io
        write(io,
"""
#set page(
  paper: "a4",
  margin: 1.5cm
)

#set text(
  font: "Libertinus Serif",
  size: 11pt
)

#set heading(numbering: "1.")

= Bayesian Evidence Synthesis Report

Generated: $(Dates.format(now(), "yyyy-mm-dd HH:MM"))

== Executive Summary

This report summarizes the Bayesian evidence synthesis,
Meta-Analytic Predictive (MAP) prior construction,
and robustification procedure.

== Effective Sample Size

#table(
  columns: 2,
  stroke: 0.5pt,

  [Metric], [Value],

  [ELIR ESS], [$(round(ess_elir, digits=2))],
  [Moment ESS], [$(round(ess_moment, digits=2))],
  [Morita ESS], [$(round(ess_morita, digits=2))]
)

== Prior Distribution Comparison

#figure(
  image("$plot_file", width: 100%),
  caption: [MAP Posterior versus Robustified MAP Prior]
)

== MAP Posterior Mixture

$(dataframe_to_typst(posterior_df))

== Robustified MAP Mixture

$(dataframe_to_typst(robust_df))

== Interpretation

The robustified prior incorporates a weakly informative
component designed to mitigate prior-data conflict while
preserving information contributed by historical evidence.

#v(1cm)
#line(length: 100%, stroke: 0.5pt)
#v(0.3cm)

#text(size: 9pt, fill: luma(120))[
  This report was generated automatically using `BayesianEvidenceSynthesis.jl`.
]
"""
)
    end
end

@post "/generate_report" function(req::HTTP.Request)
    println("--> Processing new report generation request...")

    # Generate a unique request ID to prevent concurrent file access collisions
    req_id = uuid4()
    
    temp_file  = "temp_upload_$(req_id).txt"
    plot_file  = "density_plot_$(req_id).png"
    report_typ = "report_$(req_id).typ"
    output_pdf = "Report_$(req_id).pdf"

    # Route handling for both multipart/form-data (browser forms) and raw binary streams (API)
    content_type = HTTP.header(req, "Content-Type", "")
    if startswith(content_type, "multipart/form-data")
        form = HTTP.Form(req)
        write(temp_file, read(form["file"]))
    else
        write(temp_file, req.body)
    end

    try
        results = run_inference_pipeline(temp_file)

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

        y_map = [eval_density(results.posterior, x) for x in x_vals]
        y_robust = [eval_density(results.robustified_posterior, x) for x in x_vals]

        p_dist = plot(
            x_vals,
            y_map,
            label="MAP Posterior",
            linewidth=3,
            xlabel=x_label,
            ylabel="Density",
            title="Prior Distribution Comparison",
            legend=:topright,
            size=(1200, 700),
            left_margin=8Plots.mm,
            bottom_margin=8Plots.mm
        )

        plot!(
            p_dist,
            x_vals,
            y_robust,
            label="Robustified MAP",
            linewidth=3,
            linestyle=:dash
        )

        posterior_df = mixture_dataframe(results.posterior)
        robust_df = mixture_dataframe(results.robustified_posterior; robustified=true)

        savefig(p_dist, plot_file)

        build_typst_report(
            report_typ,
            plot_file,
            posterior_df,
            robust_df,
            ess_elir_val,
            ess_moment_val,
            ess_morita_val
        )

        # Compile Typst document to PDF using the internal JLL binary
        run(`$(typst()) compile $report_typ $output_pdf`)

        pdf_bytes = read(output_pdf)

        # Clean up session assets
        rm(temp_file, force=true)
        rm(plot_file, force=true)
        rm(report_typ, force=true)
        rm(output_pdf, force=true)

        println("--> Successfully generated and returning PDF.")

        return HTTP.Response(
            200,
            ["Content-Type" => "application/pdf"],
            body=pdf_bytes
        )

    catch e
        println("--> Request failed: ", e)
        
        # Ensure all session assets are cleaned up upon failure to prevent disk bloat
        rm(temp_file, force=true)
        rm(plot_file, force=true)
        rm(report_typ, force=true)
        rm(output_pdf, force=true)

        return HTTP.Response(
            500,
            "Server Error: Failed to process data or generate report."
        )
    end
end

println("Libraries loaded! Starting server on 0.0.0.0:7860...")
serve(host="0.0.0.0", port=7860, cors=true)