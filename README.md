# AahaOS + PocketHost

One-tap boot of **our** guest OS. Not a Limbo / Vectras / Andronix wrapper. Not an ISO wizard.

**AahaOS** — custom embedded Linux: our init, hostname `aaha`, MOTD, `aaha` CLI, our initramfs.

**PocketHost** — Android host UI. Not a hypervisor brand.

Live site (GitHub Pages, **web demo only**): https://mohanrajcyber.github.io/New-project-1/

Phone boot (real guest): [docs/TERMUX.md](docs/TERMUX.md) · APK: [docs/APK.md](docs/APK.md)

## What this is

- Our branding, `/sbin/init`, `/etc/os-release` (`NAME=AahaOS`), prompt, tools.
- Real **x86_64** and **aarch64** images that boot in QEMU (serial).
- Two of **our** variants: **Core** (local-only console) and **Net** (`virtio-net` + `udhcpc` on QEMU user-net).
- Published phone images: `dist/aarch64/` (committed; Termux wget from the public repo).
- PocketHost: Ready → Start hands off to Termux. Snaps create a local row. RAM/disk/variant persist into the QEMU command.

## What this is not

- Not a from-scratch production kernel. The kernel is Linux (GPL-2.0). We write userspace + image.
- Not a hypervisor clone, not Windows, not a pirated ISO shop.
- Not “download Alpine/Debian yourself and install it.”
- PocketHost does **not** claim the VM is running inside the APK. The web page does **not** run QEMU.

## Proof on a Linux PC

Needs: `qemu-system-x86`, `qemu-system-aarch64`, `busybox-static`, `gcc`, `cpio`, `gzip`, `curl`.

```bash
make test       # x86_64 + aarch64, Core + Net (banner + Net iface)
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
aaha help
```

No password. No sshd. Console only. Ephemeral initramfs.
On **Net**, `aaha net` lists `eth0` (or similar) in addition to `lo` when QEMU attached virtio-net.

## Phone (Termux)

```bash
pkg update && pkg install qemu-system-aarch64-headless wget
curl -fsSL -o ~/termux-boot-aahaos.sh \
  https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/scripts/termux-boot-aahaos.sh
chmod +x ~/termux-boot-aahaos.sh
bash ~/termux-boot-aahaos.sh
# Net:
AAHA_VARIANT=net AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
```

## PocketHost (Android)

Folder: `android/pockethost` · package `app.pockethost` · minSdk 26

Tabs: **AahaOS** · **Snaps** (Create snapshot → row) · **Engine** (Termux sheet) · **More** (RAM/disk/variant → `qemu -m` / persist img).

```bash
cd android/pockethost && ./gradlew :app:assembleDebug
```

## Tree

```text
os/                 AahaOS userspace + Core/Net overlays
scripts/            fetch kernel, build, run, test, Termux boot
dist/aarch64/       published phone kernel + initramfs (Core + Net)
android/pockethost  one-tap host UI
web/index.html      phone-open static page + console demo
index.html          GitHub Pages root (same demo + Termux steps)
docs/TERMUX.md      phone boot
docs/APK.md         Gradle / sideload
```

LICENSE: MIT for our userspace and PocketHost. Linux kernel binary fetched at build time is GPL-2.0.

Demo login: **none**.
