#!/usr/bin/env bash
# Copy built aarch64 images into dist/ for GitHub raw / Termux wget.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER="$(tr -d '[:space:]' < "$ROOT/os/VERSION")"

"$ROOT/scripts/build-image.sh" aarch64 core
"$ROOT/scripts/build-image.sh" aarch64 net
"$ROOT/scripts/build-image.sh" aarch64 lab
"$ROOT/scripts/build-image.sh" aarch64 study

mkdir -p "$ROOT/dist/aarch64/core" "$ROOT/dist/aarch64/net" "$ROOT/dist/aarch64/lab" "$ROOT/dist/aarch64/study"
cp -f "$ROOT/images/aarch64/vmlinuz" "$ROOT/dist/aarch64/vmlinuz"
cp -f "$ROOT/images/aarch64/initramfs.cpio.gz" "$ROOT/dist/aarch64/core/initramfs.cpio.gz"
cp -f "$ROOT/images/aarch64-net/initramfs.cpio.gz" "$ROOT/dist/aarch64/net/initramfs.cpio.gz"
cp -f "$ROOT/images/aarch64-lab/initramfs.cpio.gz" "$ROOT/dist/aarch64/lab/initramfs.cpio.gz"
cp -f "$ROOT/images/aarch64-study/initramfs.cpio.gz" "$ROOT/dist/aarch64/study/initramfs.cpio.gz"
cat > "$ROOT/dist/README.md" <<'DOC'
# Published AahaOS phone images

These files are **our** aarch64 guest (kernel + initramfs), not a random ISO.

- `aarch64/vmlinuz` — Linux virt kernel (GPL-2.0)
- `aarch64/core/initramfs.cpio.gz` — Core (local-only, persist /data)
- `aarch64/net/initramfs.cpio.gz` — Net (DHCP + dropbear)
- `aarch64/lab/initramfs.cpio.gz` — Lab (Net + extra applets)
- `aarch64/study/initramfs.cpio.gz` — Study (authorized classroom lessons)

Termux: `scripts/termux-boot-aahaos.sh` wgets these from `main`.
LAN: `scripts/share-aahaos.sh`
DOC
cat > "$ROOT/dist/aarch64/manifest.json" <<EOF
{
  "os": "AahaOS",
  "version": "${VER}",
  "arch": "aarch64",
  "variants": ["core", "net", "lab", "study"],
  "kernel": "vmlinuz",
  "termux": "scripts/termux-boot-aahaos.sh"
}
EOF
echo "published $ROOT/dist/aarch64"
ls -lh "$ROOT/dist/aarch64" "$ROOT/dist/aarch64/core" "$ROOT/dist/aarch64/net" "$ROOT/dist/aarch64/lab" "$ROOT/dist/aarch64/study"
