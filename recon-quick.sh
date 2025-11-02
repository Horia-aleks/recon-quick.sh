#!/usr/bin/env bash
set -euo pipefail
TARGET="${1:-https://example.com}"
HOST="$(echo "$TARGET" | sed -E 's|https?://||' | sed -E 's|/.*||')"

echo "Target: $TARGET"
echo "-------- HEAD (headers) --------"
curl -sS -I "$TARGET" | sed -n '1,20p'

echo
echo "-------- OPTIONS (CORS / methods) --------"
curl -sS -X OPTIONS -i -L "$TARGET" | sed -n '1,40p'

echo
echo "-------- Accept: application/json (headers) --------"
curl -sS -I -H "Accept: application/json" "$TARGET" | sed -n '1,20p'

echo
echo "-------- Range probe (bytes=0-0) --------"
curl -sS -I -H "Range: bytes=0-0" "$TARGET" | sed -n '1,20p'

echo
echo "-------- TLS quick check (openssl) --------"
# Non-intrusive: single connect, prints negotiated cipher/version if handshake succeeds
openssl s_client -connect "$HOST:443" -servername "$HOST" < /dev/null 2>/dev/null | sed -n '1,60p' || echo "openssl handshake failed or blocked"

echo
echo "-------- robots.txt (first 80 lines) --------"
curl -sS "$TARGET/robots.txt" | sed -n '1,80p' || echo "no robots or fetch failed"

echo
echo "Done."
