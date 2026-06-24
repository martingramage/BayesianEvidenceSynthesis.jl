# BayesianEvidenceSynthesis.jl

[![Julia 1.10](https://img.shields.io/badge/julia-1.10-purple.svg)](https://julialang.org/)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
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

## Usage Modes

| Mode                     | Requirements                             |
| ------------------------ | ---------------------------------------- |
| Quick Report Generation  | Open `index.html` and use the hosted API |
| Local API Execution      | Julia installation required              |
| Development & Validation | Julia + tests + examples                 |

---

## Quick Start (No Installation Required)

If your goal is simply to generate Bayesian evidence synthesis reports, no Julia installation is required.

The repository includes a lightweight browser interface:

```text
index.html
```

Simply:

1. Download or clone the repository.
2. Open `index.html` in your preferred browser.
3. Upload your study data.
4. Download the generated PDF report.

The frontend communicates directly with the hosted BayesianEvidenceSynthesis API, allowing report generation without running any local services.

---

## Repository Structure

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

* **RBesT** — MCMC-based estimation of MAP priors.
* **Bayesmeta** — Analytical and numerical integration methods for Bayesian meta-analysis.

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

## REST API

### Endpoint

```http
POST /generate_report
```

### Input

* Binary or summary data file containing study information.

### Output

A PDF report including:

* MAP posterior distributions
* ESS diagnostics
* Robustified prior distributions
* Summary tables
* Graphical outputs

### Example Request

```bash
curl -X POST \
  -F "file=@study_data.bin" \
  http://localhost:8080/generate_report \
  --output report.pdf
```

---

## Local Installation and Usage

For users who wish to run the framework locally, customize analyses, execute examples, or contribute to development.

### Installation

Clone the repository and instantiate the Julia environment:

```bash
git clone https://github.com/martingramage/BayesianEvidenceSynthesis.jl.git

cd BayesianEvidenceSynthesis.jl

julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### 1. Start the Local API Server

Launch the Oxygen.jl server:

```bash
julia --project=. server.jl
```

Once started, the REST API will be available locally.

### 2. Run the Test Suite

Validate inference routines and diagnostics:

```bash
julia --project=. test/runtests.jl
```

### 3. Execute Example Workflows

Run one of the included end-to-end examples:

```bash
julia --project=. examples/main_binary.jl
```

Additional workflows are available in the `examples/` directory.

### 4. Submit Data

#### Option A — Browser Interface

Open:

```text
index.html
```

in your preferred browser.

The frontend can be configured to use either:

* The hosted cloud API.
* Your locally running API instance.

#### Option B — REST API

Send data directly to the local server:

```bash
curl -X POST \
  -F "file=@study_data.bin" \
  http://localhost:8080/generate_report \
  --output report.pdf
```

---

## Verification

Verify that the package loads correctly:

```bash
julia --project=. -e 'using BayesianEvidenceSynthesis; println("Package integrity verified.")'
```

---

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

See the `LICENSE` file for details.


