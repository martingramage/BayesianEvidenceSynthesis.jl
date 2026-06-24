# BayesianEvidenceSynthesis.jl

[![Julia 1.10](https://img.shields.io/badge/julia-1.10-purple.svg)](https://julialang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Live API](https://img.shields.io/badge/Live%20API-Running-brightgreen)](https://huggingface.co/spaces/martingramage/bayesian-evidence-synthesis)

A Julia framework for Bayesian evidence synthesis and meta-analysis, designed to support the construction of Meta-Analytic Predictive (MAP) priors, effective sample size (ESS) estimation, and robustification procedures commonly used in clinical development and regulatory settings.

The package reproduces and extends key functionalities available in the R packages **RBesT** and **Bayesmeta**, providing a unified environment for posterior synthesis, prior diagnostics, and automated report generation.

---

## Overview

BayesianEvidenceSynthesis.jl facilitates the incorporation of historical evidence into current studies through Bayesian meta-analysis. The framework provides tools for:

* Construction of **Meta-Analytic Predictive (MAP) priors**.
* Estimation of **Effective Sample Size (ESS)** using multiple methodologies:

  * ELIR ESS
  * Moment-matching ESS
  * Morita ESS
* Generation of **robustified priors** to address potential prior-data conflict.
* Automated production of reproducible evidence synthesis reports.

The project is implemented entirely in Julia and exposes its functionality through both a package interface and a REST API.

---

## Repository Structure

The repository follows a modular architecture:

```text
.
├── src/                # Core package implementation
├── examples/           # End-to-end workflow examples
├── test/               # Unit and integration tests
├── server.jl           # Oxygen.jl API entry point
├── index.html          # Frontend interface
├── Dockerfile          # Containerized deployment
├── Project.toml        # Julia environment definition
└── Manifest.toml       # Reproducible dependency snapshot
```

### Main Components

| Component    | Description                                                             |
| ------------ | ----------------------------------------------------------------------- |
| `src/`       | Bayesian inference routines, numerical methods, and package definitions |
| `examples/`  | Reproducible workflows illustrating package usage                       |
| `test/`      | Validation of inference algorithms and diagnostics                      |
| `server.jl`  | REST API implementation using Oxygen.jl                                 |
| `index.html` | Browser-based interface for report generation                           |
| `Dockerfile` | Deployment configuration for production environments                    |

---

## Methodological Background

This framework was developed following a comparative evaluation of two widely used approaches for Bayesian evidence synthesis:

* **RBesT**: MCMC-based estimation of MAP priors.
* **Bayesmeta**: Analytical and numerical integration methods for Bayesian meta-analysis.

For a detailed methodological discussion and benchmarking study, see:

**RBesT vs Bayesmeta Comparison Repository**

https://github.com/martingramage/RBest-vs-Bayesmeta

---

## Features

* Bayesian meta-analysis for historical borrowing.
* MAP prior construction and posterior updating.
* Multiple ESS estimation methodologies.
* Robustification procedures for prior-data conflict assessment.
* Automated PDF report generation.
* REST API deployment through Oxygen.jl.
* Containerized execution using Docker.

---

## API

The application exposes a report-generation endpoint:

### Endpoint

```http
POST /generate_report
```

### Input

* Binary data file containing study information.

### Output

A PDF report including:

* MAP posterior distributions
* ESS diagnostics
* Robustified prior distributions
* Summary tables and graphical outputs

---

## Installation

Clone the repository and instantiate the Julia environment:

```bash
git clone https://github.com/martingramage/BayesianEvidenceSynthesis.jl.git

cd BayesianEvidenceSynthesis.jl

julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

---

## Verification

Verify that the package loads correctly:

```bash
julia --project=. -e 'using BayesianEvidenceSynthesis; println("Package integrity verified.")'
```

---

## Deployment

To synchronize changes with both GitHub and the deployed Hugging Face Space:

```bash
git add .

git commit -m "docs: update README"

git push origin main

git push huggingface main
```

---

## License

This project is distributed under the AGPL-3.0 License.

See the `LICENSE` file for details.
