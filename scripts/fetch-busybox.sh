#!/usr/bin/env bash
# Resolve a static busybox for the guest arch.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
CFG="$ROOT/os/configs/${ARCH}.mk"
DEST_DIR="$ROOT/build/${ARCH}"
DEST="$DEST_DIR/busybox"
mkdir -p "$DEST_DIR"

# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

if [[ "${BUSYBOX_SRC:-host}" == "host" ]]; then
    src=""
    for c in /bin/busybox /usr/bin/busybox; do
        if [[ -x "$c" ]] && file "$c" | grep -q "statically linked"; then
            src="$c"
            break
        fi
    done
    if [[ -z "$src" ]]; then
        echo "need a statically linked busybox on the host (apt: busybox-static)" >&2
        exit 1
    fi
    cp -f "$src" "$DEST"
    chmod 0755 "$DEST"
    echo "using host busybox: $src -> $DEST"
    exit 0
fi

apk="$DEST_DIR/busybox-static.apk"
if [[ ! -f "$apk" ]] || [[ "$(sha256sum "$apk" | awk '{print $1}')" != "${BUSYBOX_SHA256:-}" ]]; then
    echo "fetching busybox-static apk for ${ARCH}"
    curl -fL --retry 4 --retry-delay 2 -o "$apk" "$BUSYBOX_URL"
    got="$(sha256sum "$apk" | awk '{print $1}')"
    if [[ "$got" != "$BUSYBOX_SHA256" ]]; then
        echo "busybox apk checksum failed: $got" >&2
        exit 1
    fi
fi

extract="$DEST_DIR/busybox-apk"
rm -rf "$extract"
mkdir -p "$extract"
tar -xzf "$apk" -C "$extract"
bb="$(find "$extract" -name 'busybox*' -type f | head -n 1)"
if [[ -z "$bb" ]]; then
    echo "busybox binary missing from apk" >&2
    exit 1
fi
cp -f "$bb" "$DEST"
chmod 0755 "$DEST"
echo "using apk busybox: $DEST"
