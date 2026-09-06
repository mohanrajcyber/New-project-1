#!/usr/bin/env bash
# Headless proof: AahaOS prints its banner on the QEMU serial console.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
VARIANT="${2:-${AAHA_VARIANT:-core}}"
CFG="$ROOT/os/configs/${ARCH}.mk"
if [[ "$VARIANT" == "core" ]]; then
    IMG="$ROOT/images/${ARCH}"
    BUILD="$ROOT/build/${ARCH}"
else
    IMG="$ROOT/images/${ARCH}-${VARIANT}"
    BUILD="$ROOT/build/${ARCH}-${VARIANT}"
fi
LOG="$BUILD/serial-boot.log"
PIDFILE="$BUILD/qemu.pid"

if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH" >&2
    exit 2
fi
if [[ ! -f "$IMG/vmlinuz" || ! -f "$IMG/initramfs.cpio.gz" ]]; then
    echo "building image first..."
    "$ROOT/scripts/build-image.sh" "$ARCH" "$VARIANT"
fi

# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

mkdir -p "$BUILD"
rm -f "$LOG" "$PIDFILE"

extra=()
if [[ "$ARCH" == "aarch64" ]]; then
    extra+=(-cpu "${QEMU_CPU}")
fi

echo "== serial boot test (${ARCH} ${VARIANT})"
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
    if [[ -f "$LOG" ]] \
        && grep -q "AahaOS" "$LOG" \
        && grep -q "நம்ம OS" "$LOG" \
        && grep -q "AahaOS identity" "$LOG" \
        && grep -q "variant" "$LOG"; then
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
    echo "FAIL: AahaOS banner/identity not seen on serial within 60s" >&2
    exit 1
fi

echo "PASS: AahaOS banner + Tamil MOTD + ident on ${ARCH} ${VARIANT} serial"
