# Scan evidence

The [3 November 2026 summary](2026-11-03/summary.md) records the supplied VM results. It is not a substitute for the full raw reports, which have not yet been committed to this repository.

## Files to add from the recorded VM

Copy the following from `~/results-debian13` into `reports/2026-11-03/` after reviewing their contents for anything that should not be public:

```text
base-golang.json
base-distroless.json
single-before.json
multi-before.json
single-after.json
multi-after.json
govulncheck-before.txt
govulncheck-after.txt
summary.txt
```

The summary should retain tool versions, image references, database timestamps and the functional response. If those are also available as separate metadata files, include them.

For example, from a checkout in the same VM:

```bash
cp ~/results-debian13/{base-golang,base-distroless,single-before,multi-before,single-after,multi-after}.json reports/2026-11-03/
cp ~/results-debian13/govulncheck-{before,after}.txt reports/2026-11-03/
cp ~/results-debian13/summary.txt reports/2026-11-03/
git status --short reports/
```

Review the staged contents before committing. Do not add credentials, private keys, image tarballs, compiled binaries or vulnerability-database caches.

## New reproductions

`collect-results.sh` defaults to a timestamped directory under `reports/runs/`. That generated directory is ignored by Git until a particular run is intentionally selected and copied into a clearly dated evidence folder.

New runs use new advisory snapshots and may differ from the recorded result. Do not silently replace historical reports with a new run under the same date.
