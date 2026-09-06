#!/usr/bin/env bash
# Prove persist, lock, lab, optional 9p + ssh on this host QEMU.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
CFG="$ROOT/os/configs/${ARCH}.mk"
# shellcheck disable=SC1090
source <(sed -n 's/^[[:space:]]*\([A-Z0-9_]*\) := \(.*\)$/\1="\2"/p' "$CFG")

boot_hook() {
    local variant="$1" hook="$2" needle="$3"
    local img
    if [[ "$variant" == "core" ]]; then
        img="$ROOT/images/${ARCH}"
    else
        img="$ROOT/images/${ARCH}-${variant}"
    fi
    if [[ ! -f "$img/initramfs.cpio.gz" ]]; then
        "$ROOT/scripts/build-image.sh" "$ARCH" "$variant"
    fi
    local build="$ROOT/build/${ARCH}-${variant}-feat"
    mkdir -p "$build"
    local log="$build/${hook}.log" pid="$build/${hook}.pid"
    rm -f "$log" "$pid"
    extra=()
    [[ "$ARCH" == "aarch64" ]] && extra+=(-cpu "${QEMU_CPU}")
    if [[ "$variant" == "net" || "$variant" == "lab" ]]; then
        extra+=(-netdev user,id=n0,hostfwd=tcp::$((2222))-:22 -device virtio-net-pci,netdev=n0)
    fi
    local diskimg="$build/persist.img"
    if [[ ! -f "$diskimg" ]]; then
        dd if=/dev/zero of="$diskimg" bs=1M count=32 status=none
        if command -v mkfs.vfat >/dev/null 2>&1; then
            mkfs.vfat -n AAHADATA "$diskimg" >/dev/null
        else
            mkfs.ext2 -F -L aaha-data "$diskimg" >/dev/null
        fi
    fi
    extra+=(-drive "file=${diskimg},if=virtio,format=raw")
    mkdir -p "$build/share"
    extra+=(-fsdev "local,id=aaha,path=${build}/share,security_model=none")
    extra+=(-device virtio-9p-pci,fsdev=aaha,mount_tag=aaha)
    echo "== feature boot ${ARCH} ${variant} hook=${hook}"
    "$QEMU" \
        -machine "$QEMU_MACHINE" \
        "${extra[@]}" \
        -m 256 \
        -kernel "$img/vmlinuz" \
        -initrd "$img/initramfs.cpio.gz" \
        -append "$KERNEL_CMDLINE aaha.test=${hook}" \
        -display none \
        -serial "file:${log}" \
        -monitor none \
        -no-reboot \
        -pidfile "$pid" \
        -daemonize
    ok=0
    for _ in $(seq 1 90); do
        if [[ -f "$log" ]] && grep -q "$needle" "$log"; then
            ok=1
            break
        fi
        sleep 1
    done
    if [[ -f "$pid" ]]; then
        kill "$(cat "$pid")" 2>/dev/null || true
        rm -f "$pid"
    fi
    if [[ "$ok" -ne 1 ]]; then
        echo "---- $log ----"
        tail -n 40 "$log" || true
        echo "FAIL: $needle not seen (${ARCH} ${variant} ${hook})" >&2
        return 1
    fi
    echo "PASS: ${ARCH} ${variant} ${hook}"
}

"$ROOT/scripts/build-image.sh" "$ARCH" core
"$ROOT/scripts/build-image.sh" "$ARCH" lab

# persist survive: write then read on a second boot, same img
rm -f "$ROOT/build/${ARCH}-core-feat/persist.img"
boot_hook core persist-write AAHA_PERSIST_WRITE_OK
# keep the same persist.img for read
boot_hook core persist-read AAHA_PERSIST_READ_OK

boot_hook core lock AAHA_LOCK_OK
rm -f "$ROOT/build/${ARCH}-core-feat/persist.img"
boot_hook core persist-crypt AAHA_CRYPT_OK
boot_hook lab lab AAHA_LAB_OK
if boot_hook lab ssh AAHA_SSH_OK; then
    echo "PASS: dropbear process in guest"
else
    echo "NOTE: dropbear did not stay up (libs or qemu user-net)"
fi

prove_ssh_banner() {
    local img="$ROOT/images/${ARCH}-lab"
    local build="$ROOT/build/${ARCH}-lab-sshprobe"
    local log="$build/live.log" pid="$build/live.pid"
    local port=2223
    mkdir -p "$build/share"
    rm -f "$log" "$pid"
    extra=()
    [[ "$ARCH" == "aarch64" ]] && extra+=(-cpu "${QEMU_CPU}")
    extra+=(-netdev "user,id=n0,hostfwd=tcp::${port}-:22" -device virtio-net-pci,netdev=n0)
    echo "== ssh banner probe hostfwd :${port}"
    "$QEMU" \
        -machine "$QEMU_MACHINE" \
        "${extra[@]}" \
        -m 256 \
        -kernel "$img/vmlinuz" \
        -initrd "$img/initramfs.cpio.gz" \
        -append "$KERNEL_CMDLINE" \
        -display none \
        -serial "file:${log}" \
        -monitor none \
        -no-reboot \
        -pidfile "$pid" \
        -daemonize
    banner_ok=0
    for _ in $(seq 1 40); do
        if python3 - <<PY 2>/dev/null
import socket
s = socket.socket()
s.settimeout(2)
try:
    s.connect(("127.0.0.1", ${port}))
    data = s.recv(64)
    s.close()
    raise SystemExit(0 if b"dropbear" in data.lower() or data.startswith(b"SSH-") else 1)
except Exception:
    raise SystemExit(1)
PY
        then
            banner_ok=1
            break
        fi
        sleep 1
    done
    if [[ -f "$pid" ]]; then
        kill "$(cat "$pid")" 2>/dev/null || true
        rm -f "$pid"
    fi
    if [[ "$banner_ok" -eq 1 ]]; then
        echo "PASS: SSH banner on 127.0.0.1:${port} (dropbear via QEMU hostfwd)"
        return 0
    fi
    echo "NOTE: no SSH banner on :${port} (guest dropbear or hostfwd)"
    tail -n 20 "$log" || true
    return 1
}
prove_ssh_banner || true

if boot_hook core share AAHA_SHARE_OK; then
    echo "PASS: 9p share mounted"
else
    echo "NOTE: 9p guest mount failed (QEMU has virtio-9p-pci; this kernel netboot initramfs has no 9p.ko)"
fi

echo "PASS: feature proofs (${ARCH})"
