# DESIGN.md

## 1. Project Overview
A modular, high-performance Julia library for **Bayesian Evidence Synthesis**. The system automates the derivation of Meta-Analytic-Predictive (MAP) priors by synthesizing historical clinical trial data and supports robust inference for new study designs.

## 2. Core Objectives
* **Transparency:** Provide an end-to-end implementation of Bayesian evidence synthesis, moving beyond black-box packages to explicit mathematical implementation.
* **Modular Strategy:** Decouple data parsing, inference computation (MCMC vs. Numerical), and decision analytics.
* **Reproducibility:** Utilize strict version control and automated testing to ensure clinical-grade reliability.

## 3. System Architecture
The system is built as a pipeline with three distinct layers:

### A. Data Contract (Parser)
* **Input:** Structured `.txt` files containing endpoint type (Binary, Normal, Poisson) and summary statistics.
* **Schema:** The `ClinicalStudyInput` struct ensures data validity before any inference is executed.

### B. Inference Engine
The engine uses **Multiple Dispatch** to toggle between two distinct computational strategies:
1.  **MCMC Strategy:** Leverages `Turing.jl` (HMC sampling) for non-conjugate or complex likelihoods, followed by EM-based parametric mixture fitting (following `RBesT` logic).
2.  **Numerical Strategy:** Implements marginal likelihood integration using `QuadGK.jl` under normality assumptions (Bayesmeta-style), providing high-speed results when normality holds.



### C. Analytics Service
* **Information Quantification:** Implements the **ELIR (Effective Log-Information Ratio)** method for calculating Effective Sample Size (ESS), providing a predictively consistent metric for historical data weight.
* **Robustification:** Implements manual robustification by injecting "vague" mixture components to mitigate prior-data conflict.

## 4. Engineering Standards
* **Performance:** Uses `ForwardDiff.jl` for exact curvature calculation (required for ESS).
* **Quality:** Automated test suite (`test/runtests.jl`) comparing results against standard benchmarks.
* **Documentation:** Technical documentation generated via `Documenter.jl` explaining the pushforward measures and Jacobian corrections used in logit-normal transformations.
