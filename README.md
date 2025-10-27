# Chainguard Solutions Engineer Technical Challenge

## Overview

This technical challenge evaluates your practical skills in Linux systems, containerization, and secure software supply chain practices. You will containerize an application using multiple approaches, analyze security posture, and present your findings.

**Time Allocation**: 4-8 hours (take-home)  
**Deliverable**: Working implementation + technical presentation

---

> **⚠️ IMPORTANT NOTE**
>
> This challenge is comprehensive by design. We understand you may not complete every task, and that's perfectly acceptable. We're more interested in your problem-solving approach, technical decisions, and how you navigate challenges than achieving full completion. Focus on demonstrating your thought process and documenting your journey.

---

## Environment Setup

### 1. Spin up a Linux VM

Spin up a Linux virtual machine using your preferred virtualization platform.

### 2. Install Container Engine

Within this VM, install a container engine of your choice.

### 3. Clone the Repository
```bash
git clone https://github.com/maligin/chainguard-technical-challenge
cd chainguard-technical-challenge
```

Document your tool choices and reasoning.

---

## Container Security Fundamentals

Work with the Go application located in the `/go` directory of this repository. See the [README.md](go/README.md) in that directory for build instructions.

**Important**: The application dependencies contain known CVEs. After your initial build and scan, you will need to patch the Go application and its dependencies to eliminate these vulnerabilities.

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
- Patch the Go application (and its dependencies)
- Update or optimize base images as needed
- Rescan and document improvements

**4. Deployment**
- Run as a standalone container
- Validate deployment is functional

### Deliverables
- All Dockerfiles
- Vulnerability scan reports (before/after)
- Documentation of findings and methodology

---

## Bonus Tasks (Optional)

If time permits, explore these advanced topics:

**Supply Chain Security**
- Generate SBOM for each container
- Sign container images
- Deploy a local container registry
- Push signed images to your registry

**Kubernetes Deployment**
- Deploy a local Kubernetes cluster
- Deploy the application to Kubernetes
- Create Kubernetes manifests
- Validate cluster deployment

---

## Presentation & Interview

Prepare a 30-45 minute technical presentation covering:

**Environment & Architecture (5-10 min)**
- Setup decisions and rationale
- Tool selection justification

**Deep Dive (10-15 min)**
- Dockerfile design choices
- Security findings and remediation approach
- Production challenges for traditional container builds
- Bonus tasks (if completed)

**Q&A (5-10 min)**
- Security best practices
- Supply chain considerations
- Operational challenges

Prepare to walk live through your setup, Dockerfiles, and results of your findings (results can be presented using a slide deck).

## Evaluation Criteria

Your presentation will be assessed on:
- Problem-solving approach and technical reasoning
- Security awareness and analysis depth
- Quality of work completed (over quantity)
- Code quality and documentation (where needed)
- Communication and presentation skills
- Ability to articulate challenges and tradeoffs

---
