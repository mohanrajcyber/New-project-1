#!/usr/bin/env bash
# Copy built aarch64 images into dist/ for GitHub raw / Termux wget.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="$(tr -d '[:space:]' < "$ROOT/os/VERSION")"

"$ROOT/scripts/build-image.sh" aarch64 core
"$ROOT/scripts/build-image.sh" aarch64 net

mkdir -p "$ROOT/dist/aarch64/core" "$ROOT/dist/aarch64/net"
cp -f "$ROOT/images/aarch64/vmlinuz" "$ROOT/dist/aarch64/vmlinuz"
cp -f "$ROOT/images/aarch64/initramfs.cpio.gz" "$ROOT/dist/aarch64/core/initramfs.cpio.gz"
cp -f "$ROOT/images/aarch64-net/initramfs.cpio.gz" "$ROOT/dist/aarch64/net/initramfs.cpio.gz"
cat > "$ROOT/dist/README.md" <<'DOC'
# Published AahaOS phone images

These files are **our** aarch64 guest (kernel + initramfs), not a random ISO.

- `aarch64/vmlinuz` — Linux virt kernel (GPL-2.0), fetched at build
- `aarch64/core/initramfs.cpio.gz` — AahaOS Core (local-only)
- `aarch64/net/initramfs.cpio.gz` — AahaOS Net (virtio-net + udhcpc)

Termux: `scripts/termux-boot-aahaos.sh` wgets these from `main`.
DOC
cat > "$ROOT/dist/aarch64/manifest.json" <<EOF
{
  "os": "AahaOS",
  "version": "${VER}",
  "arch": "aarch64",
  "variants": ["core", "net"],
  "kernel": "vmlinuz",
  "termux": "scripts/termux-boot-aahaos.sh"
}
EOF
echo "published $ROOT/dist/aarch64"
ls -lh "$ROOT/dist/aarch64" "$ROOT/dist/aarch64/core" "$ROOT/dist/aarch64/net"
