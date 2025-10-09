# Chainguard Solutions Engineer Technical Challenge

## Overview

This technical challenge evaluates your practical skills in Linux systems, containerization, Kubernetes, and secure software supply chain practices. You will containerize an application using multiple approaches, analyze security posture, and present your findings.

**Time Allocation**: 4-8 hours (take-home)  
**Deliverable**: Working implementation + technical presentation

---

## Environment Setup

Spin up a Linux virtual machine using your preferred virtualization platform. Within this VM:

- Install a container engine
- Deploy a local Kubernetes cluster
- Deploy a local container registry

Document your tool choices and reasoning.

---

## Part 1: Container Security Fundamentals

Work with the Go application from the Chainguard demo repository:

```bash
git clone https://github.com/chainguard-dev/hello-melange-apko
cd hello-melange-apko/go
```

### Requirements

**1. Containerization**
- Create a single-stage Dockerfile
- Create a multi-stage Dockerfile
- Use any base image of your choice

**2. Security Analysis**
- Scan both containers with a CVE scanner
- Document all vulnerabilities found
- Compare results between both approaches

**3. Remediation**
- Patch the Go application dependencies
- Update or optimize base images as needed
- Rescan and document improvements

**4. Supply Chain Security**
- Generate SBOM for each container
- Sign all container images
- Push signed images to your local registry

**5. Deployment**
- Deploy as a standalone container
- Deploy to your Kubernetes cluster
- Validate both deployments are functional

### Deliverables
- All Dockerfiles
- Vulnerability scan reports (before/after)
- SBOM files
- Kubernetes manifests
- Documentation of findings and methodology

---

## Part 2: Advanced Builds with Wolfi

Rebuild the same Go application using Wolfi and Chainguard tooling.

### Requirements

**1. Create Three Container Variants**
- Wolfi-base multi-stage Dockerfile using `cgr.dev/chainguard/wolfi-base`
- Apko + Melange build with shell
- Apko + Melange build without shell (distroless)

**2. Comparative Analysis**

Analyze and compare all containers across:
- Image size
- CVE count and severity
- SBOM composition
- Attack surface
- Runtime performance
- Operational considerations

**3. Deployment**
- Deploy one Wolfi-based variant as standalone container
- Deploy to Kubernetes
- Validate functionality

### Deliverables
- All build configurations (Dockerfiles, apko.yaml, melange.yaml)
- Comprehensive comparison document
- Deployment manifests
- Analysis and recommendations

---

## Presentation & Interview

Prepare a 30-45 minute technical presentation covering:

**Environment & Architecture (5-10 min)**
- Setup decisions and rationale
- Tool selection justification

**Part 1 Deep Dive (10-15 min)**
- Dockerfile design choices
- Security findings and remediation approach
- SBOM insights
- Production challenges for traditional container builds

**Part 2 Deep Dive (10-15 min)**
- Wolfi-based build approaches
- Build process differences
- Distroless philosophy and tradeoffs
- Comparative analysis results

**Q&A (5-10 min)**
- Security best practices
- Supply chain considerations
- Kubernetes security
- Operational challenges

---

## Submission

Create a GitHub repository containing:
- All source code and configurations
- `RESULTS.md` with detailed findings
- Scan outputs and SBOMs
- Clear documentation for reproducing your work

Submit your repository link to your Chainguard contact.

---

## Evaluation Criteria

Your submission will be assessed on:
- Technical execution and completeness
- Security awareness and analysis depth
- Problem-solving approach
- Code quality and documentation
- Communication and presentation skills

---

Good luck.
