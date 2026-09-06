#!/usr/bin/env bash
# Serve OUR aarch64 images on the LAN (same Wi-Fi, two phones).
# Not acoustic crypto. Busybox httpd or python3.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$ROOT/dist/aarch64}"
PORT="${AAHA_SHARE_PORT:-8766}"

if [[ ! -d "$DIR" ]]; then
    echo "missing $DIR — run make publish-dist" >&2
    exit 1
fi

ip=""
if command -v hostname >/dev/null 2>&1; then
    ip=$(hostname -I 2>/dev/null | awk '{print $1}') || true
fi
if [[ -z "$ip" ]] && command -v ip >/dev/null 2>&1; then
    ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}') || true
fi
ip="${ip:-127.0.0.1}"

echo "AahaOS LAN share"
echo "  dir  $DIR"
echo "  url  http://${ip}:${PORT}/"
echo "  fetch: AAHA_RAW=http://${ip}:${PORT} bash termux-boot-aahaos.sh"
echo "Ctrl-C to stop. This is not a guest. This is a file server."

cd "$DIR"
if python3 -c 'import http.server' 2>/dev/null; then
    exec python3 -m http.server "$PORT" --bind 0.0.0.0
fi
if command -v busybox >/dev/null 2>&1; then
    exec busybox httpd -f -p "$PORT" -h "$DIR"
fi
echo "need python3 or busybox httpd" >&2
exit 1
