# BayesianEvidenceSynthesis.jl

[![Julia 1.10](https://img.shields.io/badge/julia-1.10-purple.svg)](https://julialang.org/)
[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Live API](https://img.shields.io/badge/Live%20API-Running-brightgreen)](https://huggingface.co/spaces/martingramage/bayesian-evidence-synthesis)

A Julia framework for **Bayesian evidence synthesis**, **Meta-Analytic Predictive (MAP) prior construction**, **effective sample size (ESS) estimation**, and **prior robustification**.

The package is designed for historical borrowing applications in clinical development, pharmaceutical statistics, and Bayesian decision-making workflows. It reproduces and extends key functionality from the R ecosystems **RBesT** and **Bayesmeta**, while providing a unified Julia-native environment for inference, diagnostics, reporting, and deployment.

---

## Overview

BayesianEvidenceSynthesis.jl facilitates the incorporation of historical evidence into current studies through Bayesian meta-analysis.

Core capabilities include:

* Construction of **Meta-Analytic Predictive (MAP) priors**
* Estimation of **Effective Sample Size (ESS)** using:

  * ELIR ESS
  * Moment-Matching ESS
  * Morita ESS
* Generation of **robustified priors** to mitigate prior-data conflict
* Automated generation of reproducible PDF reports
* Local and cloud-based execution through a REST API

The framework is implemented entirely in Julia and can be used either as a package, a local service, or a hosted web application.

---

## Usage Modes

| Mode                     | Description                                                      |
| ------------------------ | ---------------------------------------------------------------- |
| Hosted Report Generation | Use the browser interface and cloud API without installing Julia |
| Local API Execution      | Run the Oxygen.jl service locally                                |
| Development & Validation | Full package installation with tests and examples                |

---

## Quick Start (No Installation Required)

If your goal is simply to generate Bayesian evidence synthesis reports, you do **not** need to install Julia. The application can be used directly from your web browser in either of the following ways.

### Web Interface

Launch the hosted application through your browser:

**[Launch Bayesian Evidence Synthesis App](https://huggingface.co/spaces/martingramage/Bayesian-Evidence-Synthesis)**

1. Open the link above.
2. Upload your study data.
3. Click **Generate PDF Report** to create and download your report.

Alternatively, you can download the `index.html` file and open it in any modern web browser. The interface will automatically use a locally running backend if one is available; otherwise, it will seamlessly fall back to the hosted cloud API to generate your report.

### Direct API Usage

You can also submit data directly to the hosted API:

```bash
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@examples/study_data_binary.txt" \
  https://martingramage-bayesian-evidence-synthesis.hf.space/generate_report \
  --output report.pdf
```

Once processing is complete, the generated PDF report will be downloaded automatically as `report.pdf`.

---

## Repository Structure

```text
.
├── src/                # Core package implementation
├── examples/           # End-to-end workflow examples
├── test/               # Unit and integration tests
├── server.jl           # Oxygen.jl REST API
├── index.html          # Browser interface
├── Dockerfile          # Containerized deployment
├── Project.toml        # Julia environment
└── Manifest.toml       # Reproducible dependency snapshot
```

### Main Components

| Component    | Description                                            |
| ------------ | ------------------------------------------------------ |
| `src/`       | Bayesian inference routines and package implementation |
| `examples/`  | Reproducible workflows demonstrating package usage     |
| `test/`      | Validation of inference procedures and diagnostics     |
| `server.jl`  | REST API implementation using Oxygen.jl                |
| `index.html` | Browser-based report generation interface              |
| `Dockerfile` | Production deployment configuration                    |

---

## Methodological Background

The framework was developed following a comparative evaluation of two widely used Bayesian evidence synthesis approaches:

* **RBesT** — MCMC-based MAP prior estimation
* **Bayesmeta** — Analytical and numerical Bayesian meta-analysis methods

A detailed benchmarking study is available at:

### RBesT vs Bayesmeta Comparison

https://github.com/martingramage/RBest-vs-Bayesmeta

---

## Features

* Bayesian meta-analysis for historical borrowing
* MAP prior construction and posterior updating
* Multiple ESS estimation methodologies
* Prior robustification procedures
* Automated PDF report generation
* REST API deployment through Oxygen.jl
* Browser-based report generation
* Containerized execution using Docker

---

## Local Installation and Development

The hosted API is sufficient for most users and requires no installation.

The instructions below are intended for users who wish to:

* Run the API locally
* Customize analyses
* Modify the report generation workflow
* Execute examples and validation studies
* Contribute to package development

### Installation

Clone the repository and instantiate the Julia environment:

```bash
git clone https://github.com/martingramage/BayesianEvidenceSynthesis.jl.git

cd BayesianEvidenceSynthesis.jl

julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Verify Installation

Confirm that the package loads correctly:

```bash
julia --project=. -e 'using BayesianEvidenceSynthesis; println("Package integrity verified.")'
```

---

## Running the Local API

The package includes an Oxygen.jl-based REST API.

Start the server with:

```bash
julia --project=. server.jl
```

Once started, the API will be available at:

```text
http://localhost:7860
```

All report generation requests will be handled locally on your machine.

---

## Browser Interface and Automatic Fallback

The repository includes a lightweight browser interface:

```text
index.html
```

When opened in a browser, the interface automatically attempts to connect to a locally running API server:

```text
http://localhost:7860
```

If a local server is detected, all computations and report generation are performed locally.

If no local server is available, the interface automatically falls back to the hosted cloud deployment:

```text
https://martingramage-bayesian-evidence-synthesis.hf.space
```

No configuration changes are required.

A status indicator within the interface displays which backend is currently being used:

* Local API
* Hosted Cloud API

This design allows users to switch seamlessly between local and cloud execution without modifying the interface.

---

## REST API Usage

Whether running locally or using the hosted deployment, the API exposes the same endpoint:

```http
POST /generate_report
```

### Input

A study dataset containing binary or summary-level information.

### Output

A PDF report containing:

* MAP posterior distributions
* Effective Sample Size diagnostics
* Robustified prior distributions
* Mixture model summaries
* Publication-quality figures and tables

### Example: Local Server

```bash
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@examples/study_data_binary.txt" \
  http://localhost:7860/generate_report \
  --output report.pdf
```

### Example: Hosted Cloud Service

```bash
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@examples/study_data_binary.txt" \
  https://martingramage-bayesian-evidence-synthesis.hf.space/generate_report \
  --output report.pdf
```

The generated report will be downloaded automatically upon completion.

---

## Running Tests

Execute the complete validation suite:

```bash
julia --project=. test/runtests.jl
```

---

## Running Examples

Example workflows are provided in the `examples/` directory.

```bash
julia --project=. examples/main_binary.jl
```

These examples demonstrate MAP prior construction, posterior synthesis, ESS estimation, and robustification procedures.

---

## Intended Use

BayesianEvidenceSynthesis.jl is intended for:

* Bayesian statisticians
* Clinical trial researchers
* Pharmaceutical statisticians
* Evidence synthesis workflows
* Historical borrowing studies
* Methodological research and education

---

## Disclaimer

This software is provided for research, methodological evaluation, education, and statistical workflow development.

While the package implements established Bayesian evidence synthesis methodologies, users remain responsible for verifying the suitability of all models, assumptions, input data, and resulting analyses for their specific application.

The authors make no guarantee regarding the correctness, completeness, or regulatory acceptability of results generated by the software. Any use of outputs in clinical development, regulatory submissions, healthcare decision-making, or other high-impact settings should be accompanied by appropriate scientific review, validation, and independent verification.

By using this software, users acknowledge that responsibility for interpretation and decision-making remains with the analyst and not with the software itself.

---

## License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).

See the `LICENSE` file for details.
