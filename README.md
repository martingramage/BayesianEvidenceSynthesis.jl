# 📊 BayesianEvidenceSynthesis.jl

![Julia Version](https://img.shields.io/badge/Julia-v1.11+-9558B2?logo=julia)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

**BayesianEvidenceSynthesis.jl** is a high-performance Julia package for deriving Meta-Analytic Predictive (MAP) prior distributions. It facilitates the incorporation of historical information into clinical trials using Bayesian hierarchical models.

This package provides a unified framework to compare and utilize two industry-standard approaches for borrowing historical control data:
1. **The MCMC Approach (RBesT methodology):** Uses exact Hamiltonian Monte Carlo (NUTS) to yield an asymptotically correct posterior, automatically fitted to a parametric conjugate mixture via an Expectation-Maximization (EM) algorithm.
2. **The Numerical Integration Approach (bayesmeta methodology):** Uses highly optimized adaptive quadrature (`QuadGK`) under normality assumptions to produce a fully analytical mixture distribution in fractions of a second.

---

## ✨ Key Features

- **Binary Endpoints:** Exact posterior sampling via `Turing.jl` (NUTS), followed by automated parametric Beta-mixture fitting using a custom Expectation-Maximization (EM) algorithm with exact Newton-Raphson M-steps. Automatically selects the optimal number of components using the Akaike Information Criterion (AIC).
- **Normal Endpoints:** Blazing fast analytical numerical integration using `QuadGK.jl` to handle continuous effect sizes, preserving the exact normal mixture distribution.
- **Advanced Analytics:** Calculate the **Effective Sample Size (ESS)** using the rigorously defined Effective Log-Information Ratio (ELIR) method, alongside traditional Moments-matching and Morita methods.
- **Robustification:** Automatically mitigate prior-data conflict by injecting a vague distribution component (e.g., 20% weight) to prevent Type-I error inflation.
- **Automated Reporting:** Generate presentation-ready `.pdf` reports containing visual density comparisons and ESS tables using `Plots.jl`.

---

## 📂 Repository Structure

Our architecture separates the mathematical engine (`src/`) from the end-user driver scripts (`examples/`).

```text
├── Project.toml               # Package dependencies
├── Manifest.toml              # Locked dependency versions
├── README.md                  # Project documentation
│
├── examples/                  # 🚀 RUN THESE SCRIPTS
│   ├── main.jl                # CLI script for fast console outputs
│   └── report.jl              # Generates a visual PDF report of the priors
│
├── src/                       # 🧠 THE MATHEMATICAL ENGINE
│   ├── BayesianEvidenceSynthesis.jl 
│   ├── parser.jl              # Handles clinical study data ingestion
│   ├── inference.jl           # Orchestrates MCMC vs Numerical paths
│   ├── mcmc.jl                # Turing.jl models and sampling
│   ├── mixfit.jl              # EM algorithm and AIC model selection
│   └── analytics.jl           # ESS math (ELIR/Morita) & Robustification
│
└── test/                      # ✅ TEST SUITE
    └── runtests.jl            # Automated CI tests