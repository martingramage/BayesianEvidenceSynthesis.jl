# src/BayesianEvidenceSynthesis.jl
module BayesianEvidenceSynthesis

using DataFrames, CSV, Turing, Optim, Distributions, StatsFuns, QuadGK, ForwardDiff

export ClinicalStudyInput, parse_input_file
export run_inference_pipeline, compute_posterior
export ess_elir, robustify, ess_moment, ess_morita

include("parser.jl")
include("numerical.jl")
include("mixfit.jl")  # <-- Add this here!
include("mcmc.jl")
include("inference.jl")
include("analytics.jl")

end