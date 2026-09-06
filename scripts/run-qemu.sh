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
DISK="${AAHA_DISK:-64}"
SSH_PORT="${AAHA_SSH_PORT:-2222}"
SHARE="${AAHA_SHARE:-$ROOT/share}"
CMDLINE_EXTRA="${AAHA_CMDLINE:-}"
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
if [[ "$VARIANT" == "net" || "$VARIANT" == "lab" ]]; then
    extra+=(-netdev "user,id=n0,hostfwd=tcp::${SSH_PORT}-:22" -device virtio-net-pci,netdev=n0)
    echo "  net     virtio-net + QEMU user (DHCP)  ssh host :${SSH_PORT} -> guest :22"
fi
if [[ "$DISK" =~ ^[0-9]+$ ]] && [[ "$DISK" -gt 0 ]]; then
    DISKIMG="${AAHA_DISK_IMG:-$ROOT/build/${ARCH}-${VARIANT}/persist.img}"
    mkdir -p "$(dirname "$DISKIMG")"
    if [[ ! -f "$DISKIMG" ]]; then
        dd if=/dev/zero of="$DISKIMG" bs=1M count="$DISK" status=none
        if command -v mkfs.vfat >/dev/null 2>&1; then
            mkfs.vfat -n AAHADATA "$DISKIMG" >/dev/null
            echo "  disk    formatted vfat ${DISK}M $DISKIMG -> guest /data"
        elif command -v mkfs.ext2 >/dev/null 2>&1; then
            mkfs.ext2 -F -L aaha-data "$DISKIMG" >/dev/null
            echo "  disk    formatted ext2 ${DISK}M $DISKIMG -> guest /data"
        else
            echo "  disk    raw ${DISK}M (guest mke2fs on first mount)"
        fi
    fi
    extra+=(-drive "file=${DISKIMG},if=virtio,format=raw")
    echo "  disk    $DISKIMG mounted at /data in the guest"
fi
if [[ "${AAHA_SHARE_OFF:-0}" != "1" ]]; then
    mkdir -p "$SHARE"
    extra+=(-fsdev "local,id=aaha,path=${SHARE},security_model=none")
    extra+=(-device virtio-9p-pci,fsdev=aaha,mount_tag=aaha)
    echo "  share   $SHARE -> guest /share (virtio-9p)"
fi

exec "$QEMU" \
    -machine "$QEMU_MACHINE" \
    "${extra[@]}" \
    -m "$MEM" \
    -kernel "$IMG/vmlinuz" \
    -initrd "$IMG/initramfs.cpio.gz" \
    -append "$KERNEL_CMDLINE $CMDLINE_EXTRA" \
    -nographic \
    -no-reboot \
    -monitor none \
    -serial mon:stdio
