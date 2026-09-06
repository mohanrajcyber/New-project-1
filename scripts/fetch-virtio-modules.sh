#!/usr/bin/env bash
# Pull virtio-net kernel modules from Alpine's netboot initramfs (same
# kernel we already fetch). We do not use Alpine userspace.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
CFG="$ROOT/os/configs/${ARCH}.mk"
if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH" >&2
    exit 2
fi
# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

if [[ -z "${MODULES_INITRD_URL:-}" ]]; then
    echo "MODULES_INITRD_URL missing in $CFG" >&2
    exit 2
fi

CACHE="$ROOT/build/${ARCH}/alpine-initramfs-virt"
DEST="$ROOT/build/${ARCH}/virtio-modules"
mkdir -p "$(dirname "$CACHE")" "$DEST"

need_fetch=1
if [[ -f "$CACHE" ]]; then
    got="$(sha256sum "$CACHE" | awk '{print $1}')"
    if [[ "$got" == "$MODULES_INITRD_SHA256" ]]; then
        need_fetch=0
    fi
fi
if [[ "$need_fetch" -eq 1 ]]; then
    echo "fetching kernel modules initramfs for ${ARCH}"
    tmp="$(mktemp)"
    curl -fL --retry 4 --retry-delay 2 -o "$tmp" "$MODULES_INITRD_URL"
    got="$(sha256sum "$tmp" | awk '{print $1}')"
    if [[ "$got" != "$MODULES_INITRD_SHA256" ]]; then
        echo "checksum failed for modules initramfs:" >&2
        echo "  expected $MODULES_INITRD_SHA256" >&2
        echo "  got      $got" >&2
        rm -f "$tmp"
        exit 1
    fi
    mv "$tmp" "$CACHE"
fi

extract="$(mktemp -d)"
trap 'rm -rf "$extract"' EXIT
gzip -dc "$CACHE" | (cd "$extract" && cpio -idm --quiet)

rm -rf "$DEST"
mkdir -p "$DEST"
mapfile -t kos < <(find "$extract" -type f \( \
    -name 'virtio_net.ko' -o -name 'net_failover.ko' -o -name 'failover.ko' \
    -o -name 'af_packet.ko' -o -name 'virtio_blk.ko' \
    -o -name '9p.ko' -o -name '9pnet.ko' -o -name '9pnet_virtio.ko' \
    -o -name 'ext2.ko' -o -name 'ext4.ko' -o -name 'fat.ko' -o -name 'vfat.ko' \
    -o -name 'nls_cp437.ko' -o -name 'nls_iso8859-1.ko' \))
if [[ "${#kos[@]}" -lt 5 ]]; then
    echo "expected virtio_net + virtio_blk + failover stack" >&2
    find "$extract" -name '*virtio*' -o -name '*failover*' >&2 || true
    exit 1
fi
for ko in "${kos[@]}"; do
    cp -f "$ko" "$DEST/$(basename "$ko")"
done
if [[ ! -f "$DEST/9p.ko" ]]; then
    echo "note: 9p.ko not in this netboot initramfs (guest 9p mount may fail)"
fi
echo "virtio modules -> $DEST"
ls -l "$DEST"
