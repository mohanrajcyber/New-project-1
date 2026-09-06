#!/usr/bin/env bash
# Boot AahaOS in QEMU on serial (headless).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
VARIANT="${2:-${AAHA_VARIANT:-core}}"
CFG="$ROOT/os/configs/${ARCH}.mk"
if [[ "$VARIANT" == "core" ]]; then
    IMG="$ROOT/images/${ARCH}"
else
    IMG="$ROOT/images/${ARCH}-${VARIANT}"
fi

if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH" >&2
    exit 2
fi
if [[ ! -f "$IMG/vmlinuz" || ! -f "$IMG/initramfs.cpio.gz" ]]; then
    echo "image missing — run: make image ARCH=${ARCH} VARIANT=${VARIANT}" >&2
    exit 1
fi

# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

MEM="${AAHA_MEM:-256}"
DISK="${AAHA_DISK:-0}"
echo "PocketHost-style QEMU boot: AahaOS ${VARIANT} ${ARCH} (serial console)"
echo "  kernel  $IMG/vmlinuz"
echo "  initrd  $IMG/initramfs.cpio.gz"
echo "  console $CONSOLE  memory ${MEM}M"
echo "  quit    Ctrl-A x   (or Ctrl-C if this is a test run)"
echo

extra=()
if [[ "$ARCH" == "aarch64" ]]; then
    extra+=(-cpu "${QEMU_CPU}")
fi
if [[ "$VARIANT" == "net" ]]; then
    extra+=(-netdev user,id=n0 -device virtio-net-pci,netdev=n0)
    echo "  net     virtio-net + QEMU user (DHCP)"
fi
if [[ "$DISK" =~ ^[0-9]+$ ]] && [[ "$DISK" -gt 0 ]]; then
    DISKIMG="${AAHA_DISK_IMG:-$ROOT/build/${ARCH}-${VARIANT}/persist.img}"
    mkdir -p "$(dirname "$DISKIMG")"
    if [[ ! -f "$DISKIMG" ]]; then
        dd if=/dev/zero of="$DISKIMG" bs=1M count="$DISK" status=none
    fi
    extra+=(-drive "file=${DISKIMG},if=virtio,format=raw")
    echo "  disk    ${DISK}M $DISKIMG (not auto-mounted in guest v0.3)"
fi

exec "$QEMU" \
    -machine "$QEMU_MACHINE" \
    "${extra[@]}" \
    -m "$MEM" \
    -kernel "$IMG/vmlinuz" \
    -initrd "$IMG/initramfs.cpio.gz" \
    -append "$KERNEL_CMDLINE" \
    -nographic \
    -no-reboot \
    -monitor none \
    -serial mon:stdio
