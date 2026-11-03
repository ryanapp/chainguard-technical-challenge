# ARM64 base-image verification

This separate VM scan began at `2026-11-03T22:57:02Z`. It supplements the original AMD64 base reports with platform-matched evidence for the four ARM64 application-image scans; it does not replace or rewrite the original run.

## Inputs and results

The exact digest-pinned references are retained in `inputs.txt` and in each report's `ArtifactName`. They match the builder and runtime references used in the original Dockerfiles.

| Base | Platform | OS | OS findings | Go findings |
|---|---|---|---:|---:|
| Go 1.26.10 Bookworm builder | linux/arm64 | Debian 12.15 | 3,186 | 0 |
| Distroless static Debian 13 non-root runtime | linux/arm64 | Debian 13.7 | 0 | 0 |

Builder severity: Critical 4, High 255, Medium 1,735, Low 1,162, Unknown 30. Status: affected 2,911, fix_deferred 214, will_not_fix 58, fixed 3; “fixed” indicates a reported fixed package version, not an installed fix.

The builder OS finding records match the original single-stage baseline when compared by advisory ID, package name, installed version, fixed version, severity and status. This is stronger than equal totals, but is not a claim that the complete application and base images are identical.

## Database and scope

Trivy is `0.76.1`. The retained database metadata records `UpdatedAt: 2026-11-03T13:13:42.304243913Z`, matching the original summary, and `DownloadedAt: 2026-11-03T18:03:15.465453448Z`.

The follow-up copied the cached database, skipped database updates, selected `--platform linux/arm64 --image-src remote`, and checked both report architectures. Only the two base images were scanned: there were no new application builds, govulncheck analyses or functional tests.

`trivy-db-sha256.txt` contains hashes captured for the database binary and metadata during this follow-up. The metadata checksum matches the supplied `trivy-db-metadata.json`; the database binary was not uploaded and its checksum cannot be independently checked here. The original run did not record a database hash, so matching timestamps are not retrospective cryptographic proof of database identity.

Zero reported runtime findings is snapshot-specific evidence, not proof of zero vulnerabilities or comprehensive workload compatibility. Debian 13 was held constant across dependency remediation; this is not an extra Debian 12-to-13 remediation stage.

## Files and integrity

Both Trivy JSON reports are compressed losslessly. The other five uploaded files are retained unchanged: `inputs.txt`, `scanned-at.txt`, `trivy-version.txt`, `trivy-db-metadata.json`, and `trivy-db-sha256.txt`.

From this directory, restore the JSON reports and verify all seven original files:

```bash
gzip -dk -- base-*.json.gz
shasum -a 256 -c ORIGINAL_SHA256SUMS
# Linux alternative: sha256sum -c ORIGINAL_SHA256SUMS
```

`ORIGINAL_SHA256SUMS` was generated from the supplied files during ingestion. It verifies preservation, not independent attestation of the VM execution; the authored README and Git ignore rules are not original uploaded evidence.
