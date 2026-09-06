# Published AahaOS phone images

These files are **our** aarch64 guest (kernel + initramfs), not a random ISO.

- `aarch64/vmlinuz` — Linux virt kernel (GPL-2.0), fetched at build
- `aarch64/core/initramfs.cpio.gz` — AahaOS Core (local-only)
- `aarch64/net/initramfs.cpio.gz` — AahaOS Net (virtio-net + udhcpc)

Termux: `scripts/termux-boot-aahaos.sh` wgets these from `main`.
