# Phone boot (Termux)

Boots **our** aarch64 AahaOS image — not a random ISO.

Repo is public. Images live at `dist/aarch64/` on `main`.

```bash
pkg update
pkg install qemu-system-aarch64-headless wget
curl -fsSL -o ~/termux-boot-aahaos.sh \
  https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/scripts/termux-boot-aahaos.sh
chmod +x ~/termux-boot-aahaos.sh
bash ~/termux-boot-aahaos.sh
```

Net guest (DHCP over QEMU user-net + virtio-net):

```bash
AAHA_VARIANT=net AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
```

You should see the AahaOS banner and `aaha@aaha`.  
On Net: `aaha net` should list `eth0` (or similar) in addition to `lo`.  
Quit QEMU with `Ctrl-A x`.

The script wget's:

- https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/dist/aarch64/vmlinuz
- https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/dist/aarch64/core/initramfs.cpio.gz
- or `.../net/initramfs.cpio.gz` when `AAHA_VARIANT=net`

Same files are also on Pages: https://mohanrajcyber.github.io/New-project-1/dist/aarch64/

`AAHA_MEM` becomes `qemu -m`. `AAHA_DISK` (MiB, 0 = skip) creates `persist-<variant>.img`. v0.3 does not auto-mount that disk inside the guest.

PocketHost Start can copy this command or hand off to Termux. It will not claim the guest is running inside the APK.
