# Methodology and decisions

The comparison separates runtime package contents from dependencies compiled into a Go binary. It uses the original application source at upstream commit `42fd9eb228ff400c504dfe985dcee97de323ace7`, with explicit before/after dependency states.

## Controlled inputs and limits

The Go 1.26.10 Bookworm builder is identical in both Dockerfiles and both remediation states. The multi-stage runtime is a pinned Debian 13 distroless static non-root image, also identical before and after.

The runtime comparison changes both package inventory and Debian release. The multi-stage binary also uses `-trimpath` and `-ldflags="-s -w"`; do not attribute every size difference to multi-stage syntax alone. The selected compiler is fixed, rather than interpreting the repository's go 1.18 directive as a requirement to use an obsolete compiler.

The runtime keeps build-time tooling out of the application image. It does not patch the builder, whose own inventory still needs maintenance.

The uploaded evidence exposed a platform mismatch in the auxiliary base scans: `base-golang.json` and `base-distroless.json` identify AMD64, whereas all four application-image reports identify ARM64. Matching finding totals do not prove identical inventories; architecture-specific package names differ. Use the ARM64 application reports for the main comparison and do not present the standalone base files as platform-matched corroboration.

The original reports are preserved unchanged. A separate [ARM64 base verification](../reports/2026-11-03/arm64-base-verification/README.md), started at 2026-11-03T22:57:02Z in the same VM, explicitly selected `linux/arm64` and remote image sources. Both report architectures and pinned base references were checked. The results confirm 3,186 OS findings in the Go builder and zero in the Debian 13 runtime, without changing the main application results.

That verification used Trivy 0.76.1 and the retained database with `UpdatedAt` 2026-11-03T13:13:42.304243913Z, matching the original summary. The uploaded metadata also records `DownloadedAt` 2026-11-03T18:03:15.465453448Z. Database checksums were captured for the follow-up; the original run did not capture a database checksum, so this is not retrospective byte-for-byte proof of database identity. The database binary itself is not included.

The collector now passes an explicit platform to builds and scans, chooses remote versus local image sources explicitly, and checks report architecture. Only the two base scans were rerun in the follow-up; the revised complete collector, four application builds, source checks and smoke check were not rerun.

## Why this runtime

Debian 13 is a stable release, and Distroless publishes `static-debian13:nonroot` for ARM64, with a Go example using `CGO_ENABLED=0` ([Debian release information](https://www.debian.org/releases/trixie/), [Distroless documentation](https://github.com/GoogleContainerTools/distroless)). Its support policy is separate from Debian's own operating-system lifecycle ([Distroless policy](https://github.com/GoogleContainerTools/distroless/blob/main/SUPPORT_POLICY.md)).

The choice is based on support, workload fit, non-root identity and reproducible selection. Zero OS findings is an observed result for a database snapshot, not the selection criterion or proof that the image is risk-free.

## Why these tools

- **Multipass and cloud-init:** isolated Linux VM, native ARM64 environment in the recorded run, and a scripted setup.
- **Docker:** a familiar workflow for building and running the comparison images; Podman would also be valid and was not benchmarked.
- **Trivy:** package and binary advisory inventory for both complete images.
- **govulncheck:** complementary source-level import and static call-path analysis, not proof of practical exploitability.
- **Fixed snapshots:** advisory data is downloaded once per run so a changing database does not masquerade as remediation.

Trivy's baseline 64 Go findings and govulncheck's 63 baseline findings come from different advisory coverage, not filtering the same list. The extra Trivy advisory is CVE-2023-26125, which the Go database excluded as `NOT_A_VULNERABILITY` ([Go database issue](https://github.com/golang/vulndb/issues/1755)).

## Dependency decisions

| Change | Reason |
|---|---|
| go directive: 1.18 → 1.26.10 | Remove recorded older compatibility defaults while holding the compiler fixed; behaviour still needs testing. |
| x/net: original snapshot → v0.62.0 | Address the 11 findings reported reachable; associated x/* minimum versions also rise. |
| gin: v1.8.1 → v1.9.1 | Target the framework advisories reported in this experiment without adopting the broader evaluated upgrade path. |
| protobuf: v1.28.0 → v1.33.0 | Address the remaining protobuf advisory. |

Gin v1.9.1 is a scoped experiment choice, not a recommended permanent production pin. The evaluated v1.12.0 route changed more dependencies, including quic-go; the selected route already includes sonic. More dependencies do not automatically imply more exploitable risk. Production adoption needs support review and compatibility testing.

The recorded VM run verifies the before and final endpoints, not a claim that every intermediate change was individually committed and tested there.

## Residual Go finding

The remaining finding was identified as GO-2026-5932 in `golang.org/x/crypto/openpgp`. The installed x/crypto module remains v0.58.0; its advisory lists fixed pseudo-version `0.58.1-0.20261009181718-2f1f834330b2` ([Go advisory](https://vuln.go.dev/ID/GO-2026-5932.json)).

The affected package is not imported in the analysed build. A proposed OpenVEX `not_affected` statement would use build-specific supporting evidence for `vulnerable_code_not_present`; no VEX document or attestation has been published ([OpenVEX specification](https://github.com/openvex/spec)).

This is not justified by lack of a fix, and a pseudo-version is not inherently unsafe. A further tested update remains an option, particularly for an organisation requiring zero reported findings. No organisation-wide exception or production risk acceptance is claimed.

## Production implications

The builder's 3,186 OS findings include 4 Critical, 255 High, 1,735 Medium, 1,162 Low and 30 Unknown. The reported statuses are 2,911 affected, 214 fix_deferred, 58 will_not_fix and 3 fixed; “fixed” means a fixed version is reported, not that the installed package has been patched.

Runtime minimisation reduces what ships, but does not eliminate maintenance, triage, exception ownership or update adoption. A production loop should detect new findings, propose updates, build/test/scan, and deploy the approved immutable artifact with health checks and a rollback path.

No controlled Chainguard alternative was measured. Supplier maintenance and supply-chain evidence are separate evaluation questions; a useful comparison would align compiler, architecture, dependency state, snapshot and tests rather than swap several variables and attribute the difference to the vendor.

## Completed versus proposed

Completed in the recorded VM run: four image builds and scans, source reachability checks, dependency remediation, image-size collection and the final standalone HTTP smoke check.

Completed in the separate follow-up: two platform-matched ARM64 base scans with the original scanner version and matching cached database timestamp. The original AMD64 base reports remain historical evidence, not the selected corroborating base scans.

Not completed: comprehensive regression testing, signature or attestation verification, application signing, Kubernetes deployment or publication of an OpenVEX statement. The presentation is shared separately, and the complete uploaded reports are available with provenance and decompression instructions in [the evidence guide](../reports/README.md).
