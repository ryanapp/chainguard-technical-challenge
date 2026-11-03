#!/usr/bin/env bash
# Builds the four images (single/multi x before/after) from clean copies of
# the challenge, scans everything against one frozen DB snapshot, and prints
# a compact summary. Both multi-stage builds use the same Debian 13 runtime.
# New reports use a timestamped reports/runs folder unless OUT is supplied.
#
# Usage (inside the VM, from the repository root):
#   export OUT="$PWD/reports/runs/$(date -u +%Y%m%dT%H%M%SZ)"
#   mkdir -p "$OUT"
#   set -o pipefail
#   ./collect-results.sh 2>&1 | tee "$OUT/summary.txt"
# KIT defaults to the folder this script lives in.
set -euo pipefail

KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
REPO="${REPO:-$KIT}"
BASE_COMMIT="42fd9eb228ff400c504dfe985dcee97de323ace7"
OUT="${OUT:-$REPO/reports/runs/$(date -u +%Y%m%dT%H%M%SZ)}"
IMAGE_REPO="${IMAGE_REPO:-hello-server-debian13}"
PLATFORM="${PLATFORM:-$(go env GOOS)/$(go env GOARCH)}"
case "$PLATFORM" in
  linux/arm64|linux/amd64) ;;
  *) echo "Use a supported Linux target: linux/arm64 or linux/amd64" >&2; exit 1 ;;
esac
export GOOS="${PLATFORM%/*}" GOARCH="${PLATFORM#*/}"
WORK="$(mktemp -d)"
SMOKE_CID=""
cleanup() {
  if [[ -n "$SMOKE_CID" ]]; then docker rm -f "$SMOKE_CID" >/dev/null 2>&1 || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT
mkdir -p "${OUT}"

for f in .dockerignore Dockerfile.single-stage Dockerfile.multi-stage \
         go/go.mod go/go.sum; do
  [ -f "${KIT}/${f}" ] || { echo "missing ${KIT}/${f}" >&2; exit 1; }
done

BUILDER_IMAGE="$(awk 'toupper($1) == "FROM" {print $2; exit}' "${KIT}/Dockerfile.single-stage")"
MULTI_BUILDER="$(awk 'toupper($1) == "FROM" {print $2; exit}' "${KIT}/Dockerfile.multi-stage")"
RUNTIME_IMAGE="$(awk 'toupper($1) == "FROM" {image=$2} END {print image}' "${KIT}/Dockerfile.multi-stage")"
[[ "${BUILDER_IMAGE}" == "${MULTI_BUILDER}" ]] || { echo "builder images differ" >&2; exit 1; }
for ref in "${BUILDER_IMAGE}" "${RUNTIME_IMAGE}"; do
  [[ "${ref}" =~ @sha256:[0-9a-f]{64}$ ]] || { echo "base image is not digest-pinned: ${ref}" >&2; exit 1; }
done
echo "== fixed build inputs (same for before and after)"
echo "builder: ${BUILDER_IMAGE}"
echo "runtime: ${RUNTIME_IMAGE}"
echo "images: ${IMAGE_REPO} | reports: ${OUT}"
echo "platform: ${PLATFORM}"
cp "${KIT}/Dockerfile.single-stage" "${KIT}/Dockerfile.multi-stage" "${KIT}/.dockerignore" "${OUT}/"

echo "== versions"
go version
govulncheck -version 2>/dev/null | grep -E '^(Scanner|DB)' || true
trivy --version | head -1
docker version --format 'docker {{.Server.Version}}'

echo "== freeze DBs (one snapshot for every scan below)"
trivy image --download-db-only --quiet
trivy --version | grep -A2 'Vulnerability DB' | grep UpdatedAt | sed 's/^ */trivy db /'
mkdir -p "$WORK/vulndb"
curl -sSfL -o "$WORK/vulndb/vulndb.zip" https://vuln.go.dev/vulndb.zip
python3 -m zipfile -e "$WORK/vulndb/vulndb.zip" "$WORK/vulndb"
echo "go vuln db $(cat "$WORK/vulndb/index/db.json")"
cp "$WORK/vulndb/index/db.json" "${OUT}/go-db-metadata.json"
sha256sum "$WORK/vulndb/vulndb.zip" | awk '{print $1}' > "${OUT}/go-db-sha256.txt"
trivy --version > "${OUT}/trivy-version.txt"
export GOVULNDB_URL="file://$WORK/vulndb"

echo "== prepare clean before/after sources from ${BASE_COMMIT}"
for s in before after; do
  git -C "${REPO}" archive "${BASE_COMMIT}" go | tar -x -C "${WORK}" --one-top-level="${s}"
  cp "${KIT}/.dockerignore" "${WORK}/${s}/go/"
done
cp "${KIT}/go/go.mod" "${WORK}/after/go/go.mod"
cp "${KIT}/go/go.sum" "${WORK}/after/go/go.sum"
echo "before: $(grep -m1 '^go ' "${WORK}/before/go/go.mod") | after: $(grep -m1 '^go ' "${WORK}/after/go/go.mod")"

echo "== build images"
for s in before after; do
  for k in single multi; do
    docker build --platform "${PLATFORM}" -q -f "${KIT}/Dockerfile.${k}-stage" -t "${IMAGE_REPO}:${k}-${s}" "${WORK}/${s}/go" >/dev/null
    echo "built ${IMAGE_REPO}:${k}-${s}"
  done
done

# Prints: total, severities, fixable, statuses, and a per-target breakdown
summarise() {
  jq -r '
    [.Results[]? | .Target as $t | .Class as $c | .Type as $y
      | .Vulnerabilities[]? | . + {T:$t, C:$c, Y:$y}] as $v
    | "  total \($v|length) | fixable \([$v[]|select((.FixedVersion // "") != "")]|length)",
      "  severity " + ([$v|group_by(.Severity)[]|"\(.[0].Severity)=\(length)"]|join(" ")),
      "  status   " + ([$v|group_by(.Status)[]|"\(.[0].Status // "none")=\(length)"]|join(" ")),
      ($v|group_by(.T)[]|"  - \(.[0].C)/\(.[0].Y) \(.[0].T): \(length)")
  ' "$1"
}

scan_image() {
  local ref="$1" name="$2" image_source="${3:-docker}"
  trivy image --platform "${PLATFORM}" --image-src "${image_source}" --skip-db-update --quiet --scanners vuln -f json -o "${OUT}/${name}.json" "${ref}"
  jq -e --arg platform "${PLATFORM}" \
    '(.Metadata.ImageConfig.os + "/" + .Metadata.ImageConfig.architecture) == $platform' \
    "${OUT}/${name}.json" >/dev/null || {
      echo "Platform mismatch in ${name}; expected ${PLATFORM}" >&2
      exit 1
    }
  echo "${name} (${ref})"
  summarise "${OUT}/${name}.json"
}

echo "== trivy: base images alone"
scan_image "${BUILDER_IMAGE}" base-golang remote
scan_image "${RUNTIME_IMAGE}" base-distroless remote

echo "== trivy: built images"
for s in before after; do
  for k in single multi; do
    scan_image "${IMAGE_REPO}:${k}-${s}" "${k}-${s}"
  done
done

echo "== govulncheck (source, go1.26.10)"
for s in before after; do
  rc=0
  (cd "${WORK}/${s}/go" && govulncheck -db "${GOVULNDB_URL}" ./... >"${OUT}/govulncheck-${s}.txt" 2>&1) || rc=$?
  if [[ "$rc" != 0 && "$rc" != 3 ]]; then
    cat "${OUT}/govulncheck-${s}.txt" >&2
    echo "govulncheck failed for ${s} (exit ${rc})" >&2
    exit "$rc"
  fi
  echo "${s}:"
  grep -E '^(Your code|No vulnerabilities)' "${OUT}/govulncheck-${s}.txt" | sed 's/^/  /' || true
  sed -n '/^This scan also found/,/^$/p' "${OUT}/govulncheck-${s}.txt" | sed 's/^/  /'
done

echo "== govulncheck before, older compiler (the one-sentence compiler story)"
rc=0
(cd "${WORK}/before/go" && GOTOOLCHAIN=go1.24.10 govulncheck -db "${GOVULNDB_URL}" ./... >"${OUT}/govulncheck-older-compiler.txt" 2>&1) || rc=$?
if [[ "$rc" == 0 || "$rc" == 3 ]]; then
  grep -E '^Your code' "${OUT}/govulncheck-older-compiler.txt" | sed 's/^/  /' || true
else
  echo "  Optional older-compiler check failed (exit $rc); see its report." >&2
fi

echo "== old GODEBUG defaults in the shipped binary"
for s in before after; do
  cid="$(docker create "${IMAGE_REPO}:multi-${s}")"
  docker cp -q "${cid}:/hello-server" "${WORK}/bin-${s}"
  docker rm "${cid}" >/dev/null
  n="$(go version -m "${WORK}/bin-${s}" | grep -o 'DefaultGODEBUG=[^ ]*' | tr ',' '\n' | grep -c . || true)"
  echo "  ${s}: ${n}"
done

echo "== image sizes"
docker image ls --filter "reference=${IMAGE_REPO}:*" --format '{{.Repository}}:{{.Tag}} {{.Size}}' | sort

echo "== functional check"
SMOKE_CID="$(docker run -d --rm -p 8080:8080 --name hello-check "${IMAGE_REPO}:multi-after")"
response=""
for _attempt in {1..20}; do
  if response="$(curl -fsS --max-time 2 http://localhost:8080/ 2>/dev/null)"; then break; fi
  sleep 0.5
done
[[ "$response" == "Hello World!" ]] || { echo "Unexpected smoke-check response: $response" >&2; exit 1; }
echo "  multi-after says: ${response}"
docker rm -f "$SMOKE_CID" >/dev/null
SMOKE_CID=""

rm -rf "${WORK}"
echo "== done. JSON reports in ${OUT}"
