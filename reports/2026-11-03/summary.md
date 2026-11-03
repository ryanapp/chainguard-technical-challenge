# Validated Debian 13 comparison

This is the selected presentation evidence from the user's VM summary supplied on 3 November 2026. It supersedes the earlier Debian 12 runtime comparison; the full raw scan reports remain on the user's VM at `~/results-debian13`.

## Fixed inputs

- **Source baseline:** `42fd9eb228ff400c504dfe985dcee97de323ace7`.
- **Builder, both layouts and states:** `golang:1.26.10-bookworm@sha256:23ce71337b726608afb1bc00986e630a05034a87a87ea1fc2cd1ae5cf33387eb`.
- **Multi-stage runtime, both states:** `gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329`.
- **Compiler/platform:** Go 1.26.10, linux/arm64.
- **Tools:** Trivy 0.76.1; govulncheck v1.9.0; Docker 29.9.2.
- **Trivy DB:** `2026-11-03T13:13:42.304243913Z`.
- **Go DB:** `2026-11-02T22:01:43Z`.
- **Image names:** `hello-server-debian13:{single,multi}-{before,after}`.

## Results

| Image | OS | Go | Total | Reported fixable | Size |
|---|---:|---:|---:|---:|---|
| single-before | 3,186 | 64 | 3,250 | 67 | 1.6 GB |
| multi-before | 0 | 64 | 64 | 64 | 17.2 MB |
| single-after | 3,186 | 1 | 3,187 | 4 | 1.75 GB |
| multi-after | 0 | 1 | 1 | 1 | 17.6 MB |

The Go base alone reports 3,186 OS findings, 3 fixable. The Debian 13 distroless base alone reports zero.

| Image | Critical | High | Medium | Low | Unknown |
|---|---:|---:|---:|---:|---:|
| single-before | 4 | 287 | 1,762 | 1,162 | 35 |
| multi-before | 0 | 32 | 27 | 0 | 5 |
| single-after | 4 | 255 | 1,735 | 1,162 | 31 |
| multi-after | 0 | 0 | 0 | 0 | 1 |

The OS-only severity split is Critical 4, High 255, Medium 1,735, Low 1,162, Unknown 30. Most OS findings are Medium, not Low or negligible; severity is not exploitability.

| govulncheck category | Before | After |
|---|---:|---:|
| Reachable | 11 | 0 |
| Imported-package, not called | 8 | 0 |
| Required-module only | 44 | 1 |

The older Go 1.24.10 comparison reports 32 reachable findings. Recorded older GODEBUG defaults change from 33 to 0; these are compatibility settings, not 33 vulnerabilities.

Standalone final-image response: `multi-after says: Hello World!`. This is a smoke check, not comprehensive regression or production validation.

The executed container command was:

```bash
docker run -d --rm -p 8080:8080 --name hello-check \
  hello-server-debian13:multi-after
```

The image sets `USER 65532:65532`; the run did not use `--read-only`, `--cap-drop=ALL` or `--security-opt=no-new-privileges`.

## Selection rationale and interpretation

Debian 13 is stable with full Debian support scheduled until August 2028 ([Debian](https://www.debian.org/releases/trixie/)). Distroless publishes the static Debian 13 non-root image for ARM64 and uses Debian 13 with `CGO_ENABLED=0` in its Go example ([Distroless](https://github.com/GoogleContainerTools/distroless)).

Choose the image for supported runtime availability and workload fit, pin it and test it. Treat zero OS findings as an observation, not the selection criterion or proof of security; Distroless's lifecycle is also distinct from Debian's own OS support ([Distroless support policy](https://github.com/GoogleContainerTools/distroless/blob/main/SUPPORT_POLICY.md)).

The runtime choices differ in Debian release and package inventory, while trimming/stripping flags differ between the binaries. This is a practical comparison of image layouts and runtime choices, not an isolated experiment proving that multi-stage syntax alone causes the entire reduction.

The same Debian 13 runtime and compiler are held fixed across dependency remediation. The final one Go finding requires its build-specific applicability assessment; no VEX attestation has been published.

## Presentation phrasing

“I chose the upstream-supported Debian 13 distroless static runtime for this Go application, using its non-root variant and pinning the digest. I kept the runtime constant across dependency remediation and verified that the resulting application ran correctly.”

“The selected multi-stage image went from 64 to 1 findings. It has zero OS findings in this scan, one remaining Go finding, and no reachable vulnerabilities reported by govulncheck.”
