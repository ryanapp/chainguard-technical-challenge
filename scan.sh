#!/usr/bin/env bash
# scan.sh: build the app, then report what each check finds.
#
# Run from the challenge repo's go/ folder:
#   ../scan.sh
#
# Reports:
#   1. govulncheck summary: reachable findings vs ones your code doesn't call
#   2. Trivy count for the binary on its own (uses the DB snapshot you
#      downloaded separately; it does not update it)
#   3. How many old GODEBUG defaults the go line switches back on
set -euo pipefail

if [ ! -f go.mod ]; then
  echo "Run this from the folder that contains go.mod (the repo's go/ folder)." >&2
  exit 1
fi

OUT_DIR="$(mktemp -d)"
trap 'rm -rf "${OUT_DIR}"' EXIT

echo "== go line: $(grep -m1 '^go ' go.mod) | compiler: $(go env GOVERSION)"

CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o "${OUT_DIR}/hello-server" .
echo "build: OK"

echo "== govulncheck"
# Exit code 3 means "vulnerabilities found", which is a normal result here.
# Any other non-zero code is a real error.
GV_RC=0
# Use a separately retained frozen local copy. Without it, govulncheck queries
# vuln.go.dev live and counts can change between runs.
: "${GOVULNDB_URL:?set GOVULNDB_URL to a retained frozen DB, e.g. file://\$HOME/vulndb}"
echo "db: ${GOVULNDB_URL}"
GV_OUT="$(govulncheck -db "${GOVULNDB_URL}" ./... 2>&1)" || GV_RC=$?
if [ "${GV_RC}" -ne 0 ] && [ "${GV_RC}" -ne 3 ]; then
  echo "${GV_OUT}" >&2
  echo "govulncheck failed (exit ${GV_RC})" >&2
  exit 1
fi
echo "${GV_OUT}" | grep -A3 "^Your code is affected"

echo "== trivy (binary only)"
# If Trivy fails (for example, no DB downloaded yet), set -e stops the script
# here instead of printing a misleading count.
TRIVY_OUT="$(trivy rootfs --quiet --skip-db-update --scanners vuln "${OUT_DIR}")"
echo "${TRIVY_OUT}" | grep -m1 "^Total" || echo "Total: 0 (no findings)"

echo "== old GODEBUG defaults switched on by the go line"
GODEBUG_DEFAULTS="$(go list -f '{{.DefaultGODEBUG}}' .)"
if [ -z "${GODEBUG_DEFAULTS}" ]; then
  echo "0"
else
  echo "${GODEBUG_DEFAULTS}" | tr ',' '\n' | grep -c '='
fi
