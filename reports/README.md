# Scan evidence

The `2026-11-03/` directory contains the original supplied VM report set, including the console summary and captured build inputs. Its `arm64-base-verification/` subdirectory contains a separate follow-up that resolves the auxiliary base-scan architecture gap. Trivy JSON reports are losslessly compressed to keep the repository smaller; no findings or metadata have been removed.

## Original report index

| File | Scope | Reported platform | Findings |
|---|---|---|---:|
| `base-golang.json.gz` | Pinned standalone Go base | linux/amd64 | 3,186 |
| `base-distroless.json.gz` | Pinned standalone runtime base | linux/amd64 | 0 |
| `single-before.json.gz` | Baseline single-stage application | linux/arm64 | 3,250 |
| `multi-before.json.gz` | Baseline multi-stage application | linux/arm64 | 64 |
| `single-after.json.gz` | Remediated single-stage application | linux/arm64 | 3,187 |
| `multi-after.json.gz` | Remediated multi-stage application | linux/arm64 | 1 |
| `govulncheck-before.txt` | Source analysis | VM Go toolchain: linux/arm64 | 11 reachable |
| `govulncheck-after.txt` | Source analysis | VM Go toolchain: linux/arm64 | 0 reachable; 1 module-only |

Also included: the original `summary.txt`, both Dockerfiles, `.dockerignore`, the human-readable `summary.md`, and `ORIGINAL_SHA256SUMS`.

## ARM64 follow-up and historical architecture caveat

The four application scans form an ARM64 before/after comparison. The two standalone base reports are AMD64 and must not be described as platform-matched validation of those application images.

Equal totals do not establish identical package inventories. The original collector did not explicitly constrain the platform/source of standalone base scans; the recorded metadata establishes the mismatch, not its complete root cause.

The [follow-up verification](2026-11-03/arm64-base-verification/README.md) explicitly selected ARM64 for both pinned base images. It used Trivy 0.76.1 and a cached database with the original `UpdatedAt` timestamp, and is retained separately from the original reports.

| File in `2026-11-03/arm64-base-verification/` | Reported platform | Findings |
|---|---|---:|
| `base-golang-arm64.json.gz` | linux/arm64 | 3,186 OS; zero Go |
| `base-distroless-arm64.json.gz` | linux/arm64 | 0 |

Use these two reports for platform-matched base corroboration. The follow-up does not change the four application-image results or constitute a complete rebuild/test rerun. The current collector also explicitly selects image sources/platform and validates report metadata; the full revised collector has not been rerun.

## Read and verify the reports

Inspect a report without expanding it permanently:

```bash
gzip -dc reports/2026-11-03/multi-after.json.gz | jq .
```

To restore all six original JSON files and verify all uploaded files:

```bash
cd reports/2026-11-03
gzip -dk -- *.json.gz
shasum -a 256 -c ORIGINAL_SHA256SUMS
# Linux alternative: sha256sum -c ORIGINAL_SHA256SUMS
```

The checksum manifest refers to the original uncompressed filenames. The generated `.json` copies are ignored by Git; the `.json.gz` files remain the committed evidence.

Checksums establish byte integrity, not independent attestation of the VM or scan provenance. The additional authored `summary.md` is not an original uploaded file and is not included in that manifest.

## New reproductions

`collect-results.sh` defaults to a timestamped directory under `reports/runs/`, ignored by Git until a run is intentionally selected. New advisory snapshots may change the counts; do not silently replace historical reports with a new run under the same date.
