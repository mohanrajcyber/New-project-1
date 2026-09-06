#!/usr/bin/env bash
# Boot OUR AahaOS aarch64 guest on a phone (Termux + QEMU).
# Not an ISO wizard. Not a random distro.
set -euo pipefail

REPO_RAW="${AAHA_RAW:-https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/dist/aarch64}"
DEST="${AAHA_DIR:-$HOME/aahaos}"
VARIANT="${AAHA_VARIANT:-core}"
MEM="${AAHA_MEM:-512}"
DISK="${AAHA_DISK:-64}"
SSH_PORT="${AAHA_SSH_PORT:-2222}"
SHARE="${AAHA_SHARE:-$HOME/aaha-share}"

if [[ "$VARIANT" != "core" && "$VARIANT" != "net" && "$VARIANT" != "lab" && "$VARIANT" != "study" ]]; then
    echo "AAHA_VARIANT must be core, net, lab, or study" >&2
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
        if command -v mkfs.vfat >/dev/null 2>&1; then
            mkfs.vfat -n AAHADATA "$DISKIMG" >/dev/null
            echo "  formatted vfat (not ext2 — this virt kernel mounts vfat)"
        else
            echo "  raw image — guest formats vfat on first mount (install dosfstools to preformat)"
        fi
    fi
    drive=(-drive "file=${DISKIMG},if=virtio,format=raw")
    echo "  disk    ${DISK}M $DISKIMG -> guest /data"
fi

net=()
if [[ "$VARIANT" == "net" || "$VARIANT" == "lab" || "$VARIANT" == "study" ]]; then
    net=(-netdev "user,id=n0,hostfwd=tcp::${SSH_PORT}-:22" -device virtio-net-pci,netdev=n0)
    echo "  net     virtio-net + QEMU user  ssh -p ${SSH_PORT} root@127.0.0.1"
else
    echo "  net     core = local-only (no virtio-net)"
fi

share=()
mkdir -p "$SHARE"
if qemu-system-aarch64 -device virtio-9p-pci,help >/dev/null 2>&1 \
    || qemu-system-aarch64 -device help 2>/dev/null | grep -q virtio-9p-pci; then
    share=(-fsdev "local,id=aaha,path=${SHARE},security_model=none" \
           -device virtio-9p-pci,fsdev=aaha,mount_tag=aaha)
    echo "  share   $SHARE -> guest /share"
else
    echo "  share   skipped (this qemu has no virtio-9p-pci)"
fi

echo "  serial  Termux console. Optional log: script -q $DEST/serial.log $0"
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
    "${share[@]}" \
    -nographic \
    -no-reboot
