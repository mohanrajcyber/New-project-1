#!/usr/bin/env bash
# Build an AahaOS bootable initramfs + fetch the Linux kernel for QEMU.
# Usage: build-image.sh [arch] [variant]
#   variant: core (default) or net
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
VARIANT="${2:-${AAHA_VARIANT:-core}}"
CFG="$ROOT/os/configs/${ARCH}.mk"
STAGING="$ROOT/build/${ARCH}-${VARIANT}/rootfs"
if [[ "$VARIANT" == "core" ]]; then
    OUT_DIR="$ROOT/images/${ARCH}"
else
    OUT_DIR="$ROOT/images/${ARCH}-${VARIANT}"
fi
INITRD="$OUT_DIR/initramfs.cpio.gz"
VERSION="$(tr -d '[:space:]' < "$ROOT/os/VERSION")"

if [[ ! -f "$CFG" ]]; then
    echo "unknown arch: $ARCH" >&2
    exit 2
fi
if [[ "$VARIANT" != "core" && "$VARIANT" != "net" ]]; then
    echo "unknown variant: $VARIANT (core|net)" >&2
    exit 2
fi

echo "== AahaOS ${VERSION} ${VARIANT} image (${ARCH})"

"$ROOT/scripts/fetch-kernel.sh" "$ARCH"
"$ROOT/scripts/fetch-busybox.sh" "$ARCH"

rm -rf "$STAGING"
mkdir -p "$STAGING"/{bin,sbin,usr/bin,usr/sbin,etc/aaha,proc,sys,dev,tmp,run,root,home/aaha}

cp -f "$ROOT/build/${ARCH}/busybox" "$STAGING/bin/busybox"
chmod 0755 "$STAGING/bin/busybox"
applets=(
    sh ash ls cat echo printf pwd mkdir mount umount hostname
    uname dmesg sleep reboot poweroff halt clear cp mv rm ln
    chmod chown grep sed awk head tail wc ps kill tr
    ip ifconfig lsmod
)
if [[ "$VARIANT" == "net" ]]; then
    applets+=(udhcpc ping route wget insmod lsmod rmmod)
fi
for a in "${applets[@]}"; do
    ln -sf busybox "$STAGING/bin/$a"
done
ln -sf ../bin/busybox "$STAGING/sbin/reboot"
ln -sf ../bin/busybox "$STAGING/sbin/poweroff"
ln -sf ../bin/busybox "$STAGING/sbin/halt"
if [[ "$VARIANT" == "net" ]]; then
    ln -sf ../bin/busybox "$STAGING/sbin/udhcpc"
fi

cp -a "$ROOT/os/rootfs-overlay/." "$STAGING/"
if [[ -d "$ROOT/os/variants/${VARIANT}" ]]; then
    cp -a "$ROOT/os/variants/${VARIANT}/." "$STAGING/"
fi
printf '%s\n' "$VERSION" > "$STAGING/etc/aaha/version"
printf '%s\n' "$VARIANT" > "$STAGING/etc/aaha/variant"

pretty="AahaOS ${VERSION} (${VARIANT^})"
# portable title-case for core/net
case "$VARIANT" in
    core) pretty="AahaOS ${VERSION} (Core)" ;;
    net) pretty="AahaOS ${VERSION} (Net)" ;;
esac
sed -i \
    -e "s/^VERSION=.*/VERSION=\"${VERSION}\"/" \
    -e "s/^VERSION_ID=.*/VERSION_ID=${VERSION}/" \
    -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"${pretty}\"/" \
    -e "s/^VARIANT=.*/VARIANT=\"${VARIANT^}\"/" \
    -e "s/^VARIANT_ID=.*/VARIANT_ID=${VARIANT}/" \
    -e "s/^IMAGE_VERSION=.*/IMAGE_VERSION=${VERSION}/" \
    "$STAGING/etc/os-release"
# VARIANT^ may not work on bash < 4; rewrite pretty lines already set.
if [[ "$VARIANT" == "core" ]]; then
    sed -i 's/^VARIANT=.*/VARIANT="Core"/; s/^PRETTY_NAME=.*/PRETTY_NAME="AahaOS '"${VERSION}"' (Core)"/' "$STAGING/etc/os-release"
else
    sed -i 's/^VARIANT=.*/VARIANT="Net"/; s/^PRETTY_NAME=.*/PRETTY_NAME="AahaOS '"${VERSION}"' (Net)"/' "$STAGING/etc/os-release"
fi

if [[ "$VARIANT" == "net" ]]; then
    chmod 0755 "$STAGING/usr/share/udhcpc/default.script" 2>/dev/null || true
    "$ROOT/scripts/fetch-virtio-modules.sh" "$ARCH"
    mkdir -p "$STAGING/lib/modules/aaha"
    cp -f "$ROOT/build/${ARCH}/virtio-modules/"*.ko "$STAGING/lib/modules/aaha/"
    echo "-- bundled virtio-net modules (same kernel, GPL-2.0)"
fi

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

chmod 0755 "$STAGING/sbin/init"
ln -sf ../sbin/init "$STAGING/bin/init"

mkdir -p "$STAGING/usr/share/aaha"
cat > "$STAGING/usr/share/aaha/manifest.json" <<EOF
{
  "os": "AahaOS",
  "version": "${VERSION}",
  "arch": "${ARCH}",
  "variant": "${VARIANT}",
  "kind": "embedded-linux",
  "hostname": "aaha",
  "root": "initramfs",
  "not": ["windows", "hypervisor-clone", "generic-iso", "from-scratch-kernel"]
}
EOF

mkdir -p "$OUT_DIR"
# Reuse the already-fetched kernel for this arch.
if [[ ! -f "$OUT_DIR/vmlinuz" ]]; then
    if [[ -f "$ROOT/images/${ARCH}/vmlinuz" ]]; then
        ln -f "$ROOT/images/${ARCH}/vmlinuz" "$OUT_DIR/vmlinuz" 2>/dev/null \
            || cp -f "$ROOT/images/${ARCH}/vmlinuz" "$OUT_DIR/vmlinuz"
    else
        "$ROOT/scripts/fetch-kernel.sh" "$ARCH"
        if [[ "$OUT_DIR" != "$ROOT/images/${ARCH}" ]]; then
            cp -f "$ROOT/images/${ARCH}/vmlinuz" "$OUT_DIR/vmlinuz"
        fi
    fi
fi

(
    cd "$STAGING"
    find . -print0 | cpio --null --create --format=newc --owner=0:0
) | gzip -9 > "$INITRD"

cat > "$OUT_DIR/manifest.json" <<EOF
{
  "os": "AahaOS",
  "version": "${VERSION}",
  "arch": "${ARCH}",
  "variant": "${VARIANT}",
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
echo "run:  make run ARCH=${ARCH} VARIANT=${VARIANT}"
