#!/usr/bin/env bash
# Build an AahaOS bootable initramfs + fetch the Linux kernel for QEMU.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
CFG="$ROOT/os/configs/${ARCH}.mk"
STAGING="$ROOT/build/${ARCH}/rootfs"
OUT_DIR="$ROOT/images/${ARCH}"
INITRD="$OUT_DIR/initramfs.cpio.gz"
VERSION="$(tr -d '[:space:]' < "$ROOT/os/VERSION")"

if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH" >&2
    exit 2
fi

echo "== AahaOS ${VERSION} image (${ARCH})"

"$ROOT/scripts/fetch-kernel.sh" "$ARCH"
"$ROOT/scripts/fetch-busybox.sh" "$ARCH"

rm -rf "$STAGING"
mkdir -p "$STAGING"/{bin,sbin,usr/bin,usr/sbin,etc/aaha,proc,sys,dev,tmp,run,root,home/aaha}

# BusyBox + common applets we actually use.
cp -f "$ROOT/build/${ARCH}/busybox" "$STAGING/bin/busybox"
chmod 0755 "$STAGING/bin/busybox"
applets=(
    sh ash ls cat echo printf pwd mkdir mount umount hostname
    uname dmesg sleep reboot poweroff halt clear cp mv rm ln
    chmod chown cat grep sed awk head tail wc ps kill
    ip ifconfig lsmod
)
for a in "${applets[@]}"; do
    ln -sf busybox "$STAGING/bin/$a"
done
ln -sf ../bin/busybox "$STAGING/sbin/reboot"
ln -sf ../bin/busybox "$STAGING/sbin/poweroff"
ln -sf ../bin/busybox "$STAGING/sbin/halt"

# Overlay identity files.
cp -a "$ROOT/os/rootfs-overlay/." "$STAGING/"
printf '%s\n' "$VERSION" > "$STAGING/etc/aaha/version"

# Init: prefer a static C binary on the host arch; otherwise portable ash.
if [[ "$ARCH" == "$(uname -m)" ]]; then
    echo "-- compiling aaha-init and aaha CLI (static)"
    gcc -static -Os -Wall -Wextra -o "$STAGING/sbin/init" "$ROOT/os/init.c"
    gcc -static -Os -Wall -Wextra -o "$STAGING/usr/bin/aaha" "$ROOT/os/aaha.c"
    strip -s "$STAGING/sbin/init" "$STAGING/usr/bin/aaha" 2>/dev/null || true
else
    echo "-- cross C compiler not required; using portable ash init + aaha.sh"
    cp -f "$ROOT/os/init.sh" "$STAGING/sbin/init"
    chmod 0755 "$STAGING/sbin/init"
    cp -f "$ROOT/os/aaha.sh" "$STAGING/usr/bin/aaha"
    chmod 0755 "$STAGING/usr/bin/aaha"
fi

# Make sure init is executable.
chmod 0755 "$STAGING/sbin/init"
ln -sf ../sbin/init "$STAGING/bin/init"

# Manifest consumed by PocketHost (image path contract).
mkdir -p "$STAGING/usr/share/aaha"
cat > "$STAGING/usr/share/aaha/manifest.json" <<EOF
{
  "os": "AahaOS",
  "version": "${VERSION}",
  "arch": "${ARCH}",
  "kind": "embedded-linux",
  "hostname": "aaha",
  "root": "initramfs",
  "not": ["windows", "vmware", "generic-iso", "from-scratch-kernel"]
}
EOF

# Pack initramfs (newc). Device nodes are created by init via devtmpfs.
mkdir -p "$OUT_DIR"
(
    cd "$STAGING"
    find . -print0 | cpio --null --create --format=newc --owner=0:0
) | gzip -9 > "$INITRD"

# Host-side manifest next to the image.
cat > "$OUT_DIR/manifest.json" <<EOF
{
  "os": "AahaOS",
  "version": "${VERSION}",
  "arch": "${ARCH}",
  "kernel": "vmlinuz",
  "initramfs": "initramfs.cpio.gz",
  "kind": "embedded-linux",
  "contract": "android/pockethost/app/src/main/assets/aahaos/IMAGE_CONTRACT.txt"
}
EOF

echo
echo "built:"
echo "  $OUT_DIR/vmlinuz"
echo "  $INITRD ($(du -h "$INITRD" | awk '{print $1}'))"
echo "  $OUT_DIR/manifest.json"
echo
echo "run:  make run ARCH=${ARCH}"
