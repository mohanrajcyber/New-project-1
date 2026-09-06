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
if [[ "$VARIANT" == "net" || "$VARIANT" == "lab" || "$VARIANT" == "study" ]]; then
    extra+=(-netdev user,id=n0,hostfwd=tcp::2222-:22 -device virtio-net-pci,netdev=n0)
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
need_net=0
[[ "$VARIANT" == "net" || "$VARIANT" == "lab" || "$VARIANT" == "study" ]] && need_net=1
for _ in $(seq 1 90); do
    if [[ -f "$LOG" ]] \
        && grep -q "AahaOS" "$LOG" \
        && grep -q "நம்ம OS" "$LOG" \
        && grep -q "AahaOS identity" "$LOG" \
        && grep -q "variant" "$LOG"; then
        if [[ "$need_net" -eq 1 ]]; then
            if grep -Eq 'ifaces[[:space:]]*:.*\b(eth0|enp|ens|virtio)' "$LOG" \
                || grep -Eq 'bringing up (eth0|enp|ens)' "$LOG" \
                || grep -Eq '^[[:space:]]*(eth0|enp[0-9]+s[0-9]+|ens[0-9]+):' "$LOG"; then
                ok=1
                break
            fi
        else
            ok=1
            break
        fi
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
    if [[ "$need_net" -eq 1 ]]; then
        echo "FAIL: AahaOS Net banner ok but no guest iface besides lo within 90s" >&2
    else
        echo "FAIL: AahaOS banner/identity not seen on serial within 90s" >&2
    fi
    exit 1
fi

echo "PASS: AahaOS banner + Tamil MOTD + ident on ${ARCH} ${VARIANT} serial"
if [[ "$need_net" -eq 1 ]]; then
    echo "PASS: Net variant serial shows a non-lo iface (virtio-net + QEMU user)"
fi
if [[ "$VARIANT" == "lab" ]]; then
    if grep -q 'PRETTY_NAME="AahaOS .* (Lab)"' "$LOG"; then
        echo "PASS: Lab PRETTY_NAME on serial"
    else
        echo "FAIL: Lab image missing distinct PRETTY_NAME" >&2
        exit 1
    fi
fi
if [[ "$VARIANT" == "study" ]]; then
    if grep -q 'PRETTY_NAME="AahaOS .* (Study)"' "$LOG" \
        && grep -q 'authorized use only' "$LOG"; then
        echo "PASS: Study PRETTY_NAME + ethics on serial"
    else
        echo "FAIL: Study image missing PRETTY_NAME or ethics banner" >&2
        exit 1
    fi
fi
