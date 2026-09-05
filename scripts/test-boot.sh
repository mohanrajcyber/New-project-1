#!/usr/bin/env bash
# Headless proof: AahaOS prints its banner on the QEMU serial console.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
CFG="$ROOT/os/configs/${ARCH}.mk"
IMG="$ROOT/images/${ARCH}"
LOG="$ROOT/build/${ARCH}/serial-boot.log"
PIDFILE="$ROOT/build/${ARCH}/qemu.pid"

if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH" >&2
    exit 2
fi
if [[ ! -f "$IMG/vmlinuz" || ! -f "$IMG/initramfs.cpio.gz" ]]; then
    echo "building image first..."
    "$ROOT/scripts/build-image.sh" "$ARCH"
fi

# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

mkdir -p "$ROOT/build/${ARCH}"
rm -f "$LOG" "$PIDFILE"

extra=()
if [[ "$ARCH" == "aarch64" ]]; then
    extra+=(-cpu "${QEMU_CPU}")
fi

echo "== serial boot test (${ARCH})"
"$QEMU" \
    -machine "$QEMU_MACHINE" \
    "${extra[@]}" \
    -m 192 \
    -kernel "$IMG/vmlinuz" \
    -initrd "$IMG/initramfs.cpio.gz" \
    -append "$KERNEL_CMDLINE" \
    -display none \
    -serial "file:${LOG}" \
    -monitor none \
    -no-reboot \
    -pidfile "$PIDFILE" \
    -daemonize

cleanup() {
    if [[ -f "$PIDFILE" ]]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null || true
        rm -f "$PIDFILE"
    fi
}
trap cleanup EXIT

ok=0
for _ in $(seq 1 60); do
    if [[ -f "$LOG" ]] && grep -q "AahaOS" "$LOG" && grep -q "நம்ம OS" "$LOG" && grep -q "AahaOS status" "$LOG"; then
        ok=1
        break
    fi
    sleep 1
done

echo "---- serial log ----"
if [[ -f "$LOG" ]]; then
    cat "$LOG"
else
    echo "(no serial log)"
fi
echo "--------------------"

if [[ "$ok" -ne 1 ]]; then
    echo "FAIL: AahaOS banner not seen on serial within 60s" >&2
    exit 1
fi

echo "PASS: AahaOS banner + Tamil MOTD on ${ARCH} serial"
