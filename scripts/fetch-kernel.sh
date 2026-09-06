#!/usr/bin/env bash
# Fetch a Linux kernel bzImage/Image for AahaOS. This is the kernel only —
# not an Alpine ISO, not a distro installer.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
CFG="$ROOT/os/configs/${ARCH}.mk"

if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH (expected os/configs/${ARCH}.mk)" >&2
    exit 2
fi

# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

DEST_DIR="$ROOT/images/${ARCH}"
DEST="$DEST_DIR/vmlinuz"
mkdir -p "$DEST_DIR"

if [[ -f "$DEST" ]]; then
    got="$(sha256sum "$DEST" | awk '{print $1}')"
    if [[ "$got" == "$KERNEL_SHA256" ]]; then
        echo "kernel already present: $DEST"
        exit 0
    fi
    echo "kernel checksum mismatch — re-fetching"
fi

echo "fetching Linux kernel for ${ARCH}"
echo "  url: $KERNEL_URL"
tmp="$(mktemp)"
curl -fL --retry 4 --retry-delay 2 -o "$tmp" "$KERNEL_URL"
got="$(sha256sum "$tmp" | awk '{print $1}')"
if [[ "$got" != "$KERNEL_SHA256" ]]; then
    echo "checksum failed for kernel:" >&2
    echo "  expected $KERNEL_SHA256" >&2
    echo "  got      $got" >&2
    echo "The Alpine virt kernel URL/version may have rolled. Update" >&2
    echo "os/configs/${ARCH}.mk KERNEL_SHA256 after reviewing the file." >&2
    rm -f "$tmp"
    exit 1
fi
mv "$tmp" "$DEST"
echo "saved $DEST"
echo "note: this is a Linux kernel binary (GPL-2.0). AahaOS userspace is ours."
