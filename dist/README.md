# Published AahaOS phone images

These files are **our** aarch64 guest (kernel + initramfs), not a random ISO.

- `aarch64/vmlinuz` — Linux virt kernel (GPL-2.0)
- `aarch64/core/initramfs.cpio.gz` — Core (local-only, persist /data)
- `aarch64/net/initramfs.cpio.gz` — Net (DHCP + dropbear)
- `aarch64/lab/initramfs.cpio.gz` — Lab (Net + extra applets)
- `aarch64/study/initramfs.cpio.gz` — Study (authorized classroom lessons)

Termux: `scripts/termux-boot-aahaos.sh` wgets these from `main`.
LAN: `scripts/share-aahaos.sh`
