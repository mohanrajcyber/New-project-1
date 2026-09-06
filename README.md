# AahaOS + PocketHost

One-tap boot of **our** guest OS. Not a Limbo / Vectras / Andronix wrapper. Not an ISO wizard.

**AahaOS** — custom embedded Linux: our init, hostname `aaha`, MOTD, `aaha` CLI, our initramfs.

**PocketHost** — Android host UI. Not a hypervisor brand.

Live site (GitHub Pages, **web demo only**): https://mohanrajcyber.github.io/New-project-1/

v0.4: persist `/data`, Net/Lab dropbear `:2222`, Lab variant, Termux/LAN share, real `aaha lock`. Web is still a demo.

Phone boot (real guest): [docs/TERMUX.md](docs/TERMUX.md) · APK: [docs/APK.md](docs/APK.md)

## What this is

- Our branding, `/sbin/init`, `/etc/os-release` (`NAME=AahaOS`), prompt, tools.
- Real **x86_64** and **aarch64** images that boot in QEMU (serial).
- Three of **our** variants: **Core** (local-only), **Net** (`virtio-net` + DHCP + dropbear), **Lab** (Net + extra applets).
- Persist disk at guest `/data` (vfat). Files survive reboot when `AAHA_DISK` is set.
- Published phone images: `dist/aarch64/` (committed; Termux wget from the public repo).
- PocketHost: Ready → Start hands off to Termux. Snaps create a local row. RAM/disk/variant persist into the QEMU command (`AAHA_VARIANT`, `AAHA_MEM`).

## What this is not

- Not a from-scratch production kernel. The kernel is Linux (GPL-2.0). We write userspace + image.
- Not a hypervisor clone, not Windows, not a pirated ISO shop.
- Not “download Alpine/Debian yourself and install it.”
- PocketHost does **not** claim the VM is running inside the APK. The web page does **not** run QEMU.

## Proof on a Linux PC

Needs: `qemu-system-x86`, `qemu-system-aarch64`, `busybox-static`, `gcc`, `cpio`, `gzip`, `curl`.

```bash
make test       # x86_64 + aarch64, Core + Net + Lab + persist/lock
make run        # interactive serial (Ctrl-A x)
make publish-dist
```

Inside the guest:

```text
aaha status
aaha ident
aaha mem
aaha net
aaha lock
aaha lock persist
aaha lab
aaha help
```

Console. Net/Lab also start dropbear (`ssh -p 2222 root@127.0.0.1`, blank password). Initramfs is ephemeral; `/data` is the persist disk.

## Phone (Termux)

```bash
pkg update && pkg install qemu-system-aarch64-headless wget
curl -fsSL -o ~/termux-boot-aahaos.sh \
  https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/scripts/termux-boot-aahaos.sh
chmod +x ~/termux-boot-aahaos.sh
bash ~/termux-boot-aahaos.sh
# Net (DHCP + ssh :2222):
AAHA_VARIANT=net AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
# Lab:
AAHA_VARIANT=lab AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
```

## PocketHost (Android)

Folder: `android/pockethost` · package `app.pockethost` · minSdk 26

Tabs: **AahaOS** · **Snaps** · **Serial (via Termux)** · **Engine** · **More** (Core/Net/Lab + 256/512/1024 → `AAHA_VARIANT` / `AAHA_MEM`).

```bash
cd android/pockethost && ./gradlew :app:assembleRelease
```

## Tree

```text
os/                 AahaOS userspace + Core/Net/Lab overlays
scripts/            fetch kernel, build, run, test, Termux boot, LAN share
dist/aarch64/       published phone kernel + initramfs (Core + Net + Lab)
android/pockethost  one-tap host UI
web/index.html      phone-open static page + console demo
index.html          GitHub Pages root (same demo + Termux steps)
docs/TERMUX.md      phone boot
docs/APK.md         Gradle / sideload
```

LICENSE: MIT for our userspace and PocketHost. Linux kernel binary fetched at build time is GPL-2.0.

Demo login: **none**.
