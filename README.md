# Chainguard technical challenge

A Go container-security exercise comparing a single-stage image with a minimal, non-root Debian 13 runtime, then remediating the application dependencies. The original task is preserved in [CHALLENGE.md](CHALLENGE.md); this repository retains its upstream Git history.

## Recorded result

The Linux ARM64 VM run on 3 November 2026 used Go 1.26.10, Trivy 0.76.1 and govulncheck v1.9.0. The same compiler, runtime digest and advisory snapshots were held fixed across dependency remediation.

| Image | Before findings | After findings | Final composition | Final size |
|---|---:|---:|---|---|
| Single-stage | 3,250 | 3,187 | 3,186 OS + 1 Go | 1.75 GB |
| Multi-stage | 64 | 1 | 0 OS + 1 Go | 17.6 MB |

govulncheck reported 11 reachable findings before and zero after, with one required-module-only finding remaining. The final multi-stage container returned `Hello World!`; that is a smoke check, not comprehensive testing or proof of zero risk.

See the [recorded results and severity breakdown](reports/2026-11-03/summary.md). **The full raw VM reports have not yet been committed:** the repository currently contains the recorded summary, reproduction scripts and an explicit [report checklist](reports/README.md), not a complete raw-report hand-in.

## Repository contents

- **Dockerfiles:** [single-stage](Dockerfile.single-stage) and [multi-stage](Dockerfile.multi-stage), with explicit digest pins.
- **Application:** [go/](go/) contains the selected final dependency state; application source is unchanged.
- **Reproduction:** [collect-results.sh](collect-results.sh) rebuilds and scans the four comparison images; [scan.sh](scan.sh) supports individual dependency experiments.
- **VM setup:** [cg-cloud-init.yaml](cg-cloud-init.yaml) records the pinned tool installation.
- **Methodology:** [docs/METHODOLOGY.md](docs/METHODOLOGY.md) explains choices, evidence boundaries and the residual assessment.
- **Reports:** [reports/](reports/) separates the recorded summary from raw evidence still to be supplied.

The presentation is shared separately. Optional signing, SBOM attestation and Kubernetes deployment are not claimed as completed.

## Build and run the final application

Run from the repository root on a Docker-enabled Linux environment:

```bash
docker build -f Dockerfile.single-stage -t hello-server-debian13:single-after ./go
docker build -f Dockerfile.multi-stage -t hello-server-debian13:multi-after ./go

docker run -d --rm -p 8080:8080 --name hello-check \
  hello-server-debian13:multi-after
curl --fail http://localhost:8080/
docker rm -f hello-check
```

The multi-stage Dockerfile supplies `USER 65532:65532`. The recorded command did not use read-only filesystem, capability-drop or no-new-privileges flags; those need separate compatibility testing.

## Reproduce the comparison

The scripts need Docker Engine, Go 1.26.10, Trivy 0.76.1, govulncheck v1.9.0, Git, curl, jq, Python 3, GNU tar and Bash. The pinned cloud-init file provisions the original Linux VM; tools for optional work are installed but their presence does not mean the bonus tasks were completed.

From a Mac with Multipass, using the cloud-init file in this checkout:

```bash
multipass launch 24.04 --name cg --cpus 4 --memory 8G --disk 30G \
  --cloud-init cg-cloud-init.yaml --timeout 900
multipass exec cg -- cloud-init status --wait
multipass shell cg
```

The setup clones the original upstream repository for provenance. Clone this solution separately inside the VM:

```bash
git clone https://github.com/ryanapp/chainguard-technical-challenge.git ~/chainguard-solution
cd ~/chainguard-solution
export OUT="$PWD/reports/runs/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"
set -o pipefail
./collect-results.sh 2>&1 | tee "$OUT/summary.txt"
```

Do not use a shallow clone that omits baseline commit `42fd9eb228ff400c504dfe985dcee97de323ace7`. The collector builds the baseline source at that commit and substitutes this checkout's final `go.mod` and `go.sum` for the after state. Both multi-stage builds use the same Debian 13 runtime.

Each run downloads current advisory data once and freezes it for that run. Later dates can yield different counts; the original timestamps are recorded with the results. This repository does not bundle historical vulnerability databases.

The collector keeps new runs separate, checks scanner errors and asserts the expected HTTP response. These packaging/error-handling improvements were made after the recorded VM run; no new complete container run is implied.

For standalone use of `scan.sh`, first set `GOVULNDB_URL` to a separately retained local Go vulnerability database and download a Trivy database. The collector's temporary Go snapshot is cleaned up at exit; it does not provide a persistent database for later manual experiments.

## Inspect the actual dependency changes

```bash
git diff 42fd9eb228ff400c504dfe985dcee97de323ace7 HEAD -- go/go.mod go/go.sum
```

This is one solution commit following the preserved upstream history, not a fabricated sequence of intermediate remediation commits. The final dependency choices are explicit and should be reviewed again before any production use.
