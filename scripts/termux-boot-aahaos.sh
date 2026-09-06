#!/usr/bin/env bash
# Boot OUR AahaOS aarch64 guest on a phone (Termux + QEMU).
# Not an ISO wizard. Not a random distro.
set -euo pipefail

REPO_RAW="${AAHA_RAW:-https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/dist/aarch64}"
DEST="${AAHA_DIR:-$HOME/aahaos}"
VARIANT="${AAHA_VARIANT:-core}"
MEM="${AAHA_MEM:-512}"
DISK="${AAHA_DISK:-64}"

if [[ "$VARIANT" != "core" && "$VARIANT" != "net" ]]; then
    echo "AAHA_VARIANT must be core or net" >&2
    exit 2
fi

mkdir -p "$DEST"
cd "$DEST"

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "missing $1 — in Termux:  pkg update && pkg install qemu-system-aarch64-headless wget" >&2
        exit 1
    fi
}
need wget
need qemu-system-aarch64

echo "== AahaOS phone boot"
echo "  variant $VARIANT   ram ${MEM}M   disk ${DISK}M"
echo "  dest    $DEST"
echo "  source  $REPO_RAW"

if [[ ! -f vmlinuz ]]; then
    echo "-- wget vmlinuz"
    wget -q -O vmlinuz "$REPO_RAW/vmlinuz"
fi
INITRD="initramfs-${VARIANT}.cpio.gz"
if [[ ! -f "$INITRD" ]]; then
    echo "-- wget $INITRD"
    wget -q -O "$INITRD" "$REPO_RAW/${VARIANT}/initramfs.cpio.gz"
fi

drive=()
if [[ "$DISK" =~ ^[0-9]+$ ]] && [[ "$DISK" -gt 0 ]]; then
    DISKIMG="$DEST/persist-${VARIANT}.img"
    if [[ ! -f "$DISKIMG" ]]; then
        echo "-- create persist disk ${DISK}M"
        dd if=/dev/zero of="$DISKIMG" bs=1M count="$DISK" status=none
    fi
    drive=(-drive "file=${DISKIMG},if=virtio,format=raw")
    echo "  disk    ${DISK}M $DISKIMG (not auto-mounted in guest v0.3)"
fi

net=()
if [[ "$VARIANT" == "net" ]]; then
    net=(-netdev user,id=n0 -device virtio-net-pci,netdev=n0)
    echo "  net     virtio-net + QEMU user (DHCP)"
else
    echo "  net     core = local-only (no virtio-net)"
fi

echo
echo "Starting QEMU serial. You should see the AahaOS banner."
echo "This is the guest. PocketHost is not pretending to run it."
echo

exec qemu-system-aarch64 \
    -machine virt \
    -cpu max \
    -m "$MEM" \
    -kernel "$DEST/vmlinuz" \
    -initrd "$DEST/$INITRD" \
    -append "console=ttyAMA0 rdinit=/sbin/init panic=5" \
    "${drive[@]}" \
    "${net[@]}" \
    -nographic \
    -no-reboot
