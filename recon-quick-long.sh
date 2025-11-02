#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-https://example.com}"
OUTROOT="${2:-recon-results}"
TIMEOUT=10   # curl timeout in seconds

HOST="$(echo "$TARGET" | sed -E 's|https?://||' | sed -E 's|/.*||')"
TS="$(date +%Y%m%d_%H%M%S)"
OUTDIR="$OUTROOT/${HOST}-${TS}"
mkdir -p "$OUTDIR"

echo "Saving results to: $OUTDIR"

# Helper to run a command, print a header and save stdout+stderr to file
run_and_save(){
  local label="$1"; shift
  local outfile="$OUTDIR/$(printf '%s' "$label" | tr ' /' '__').txt"
  printf "\n===== %s =====\n" "$label" | tee -a "$outfile"
  "$@" 2>&1 | tee -a "$outfile"
  printf "\n" | tee -a "$outfile"
}

run_and_save "HEAD (headers)" curl -sS --max-time "$TIMEOUT" -I "$TARGET"
run_and_save "OPTIONS (CORS / methods) - follow redirects" curl -sS --max-time "$TIMEOUT" -L -X OPTIONS -i "$TARGET"
run_and_save "Accept: application/json (headers)" curl -sS --max-time "$TIMEOUT" -I -H "Accept: application/json" "$TARGET"
run_and_save "Range probe (bytes=0-0)" curl -sS --max-time "$TIMEOUT" -I -H "Range: bytes=0-0" "$TARGET"

run_and_save "TLS quick check (openssl handshake - brief)" \
  bash -c "openssl s_client -connect '$HOST:443' -servername '$HOST' < /dev/null 2>/dev/null || echo 'openssl handshake failed or blocked'"

run_and_save "robots.txt (first 200 lines)" bash -c "curl -sS --max-time $TIMEOUT '$TARGET/robots.txt' | sed -n '1,200p' || echo 'no robots or fetch failed'"

echo "Done. Files: $OUTDIR"
