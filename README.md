# AahaOS + PocketHost

One-tap boot of **our** guest OS. Not a Limbo / Vectras / Andronix wrapper. Not an ISO wizard.

**AahaOS** — custom embedded Linux: our init, hostname `aaha`, MOTD, `aaha` CLI, our initramfs.

**PocketHost** — Android host UI. Not a hypervisor brand.

Web (phone browser): [web/index.html](web/index.html) · short landing: [docs/LANDING.md](docs/LANDING.md)

## What this is

- Our branding, `/sbin/init`, `/etc/os-release` (`NAME=AahaOS`), prompt, tools.
- Real **x86_64** and **aarch64** images that boot in QEMU (serial).
- Two of **our** variants (both build): **Core** (console) and **Net** (Core + DHCP/ping applets).
- PocketHost: AahaOS card → **Ready · engine off** → **Start**. Engine tab = Termux sheet. No browse-ISO.

## What this is not

- Not a from-scratch production kernel. The kernel is Linux (GPL-2.0). We write userspace + image.
- Not a hypervisor clone, not Windows, not a pirated ISO shop.
- Not “download Alpine/Debian yourself and install it.”
- PocketHost does **not** claim the VM is running. JNI/QEMU-on-phone is next.

## Proof on a Linux PC

Needs: `qemu-system-x86`, `qemu-system-aarch64`, `busybox-static`, `gcc`, `cpio`, `gzip`, `curl`.

```bash
make test       # x86_64 Core + aarch64 Core + x86_64 Net (banner grep)
make run        # interactive serial (Ctrl-A x)
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

```bash
make image-aarch64
make image-net
```

## PocketHost (Android)

Folder: `android/pockethost` · package `app.pockethost` · minSdk 26

Tabs: **AahaOS** · **Snaps** (empty, honest) · **Engine** (Termux commands + copy) · **More** (RAM/disk defaults).

Image contract: `android/pockethost/app/src/main/assets/aahaos/`

Gradle wrapper is valid. This environment has no Android SDK, so `assembleDebug` stops at “SDK location not found”. With Android Studio:

```bash
cd android/pockethost && ./gradlew :app:assembleDebug
```

## Phone-only tester

See [docs/PHONE.md](docs/PHONE.md). Sideload APK → Ready + engine off. Start stays honest. Next: Termux QEMU on our aarch64 image, or JNI.

## Tree

```text
os/                 AahaOS userspace + Core/Net overlays
scripts/            fetch kernel, build, run, test
android/pockethost  one-tap host UI
web/index.html      phone-open static page + console demo
docs/LANDING.md     short mobile read
```

LICENSE: MIT for our userspace and PocketHost. Linux kernel binary fetched at build time is GPL-2.0.

Demo login: **none**.
