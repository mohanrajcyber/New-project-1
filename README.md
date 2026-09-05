# AahaOS + PocketHost

One-tap boot of **our** guest OS. Not a Limbo / Vectras / Andronix wrapper. Not an ISO wizard.

**AahaOS** is the guest: a custom embedded Linux (our init, hostname `aaha`, MOTD, `aaha` CLI, our initramfs).

**PocketHost** is the Android host UI. It is **not** VMware.

## What this is

- Our branding, `/sbin/init`, `/etc/os-release` (`NAME=AahaOS`), prompt, tools.
- A real **x86_64** image that boots in QEMU (serial) on Linux. **aarch64** also boots under TCG (phone-class later).
- PocketHost: AahaOS card → status **Ready** → **Start**. No browse-ISO.

## What this is not

- Not a from-scratch production kernel. The kernel is Linux (GPL-2.0). We write userspace + image.
- Not VMware, not Windows, not a pirated ISO shop.
- Not “download Alpine/Debian yourself and install it.”
- PocketHost v1 does **not** claim the VM is running. The JNI/QEMU-on-phone engine is the next step.

## Proof on a Linux PC

Needs: `qemu-system-x86`, `busybox-static`, `gcc`, `cpio`, `gzip`, `curl`.

```bash
make image      # x86_64 kernel + our initramfs
make test-boot  # headless serial; must print AahaOS + Tamil line
make run        # interactive serial console (Ctrl-A x to quit)
```

Inside the guest:

```text
aaha status
aaha net
aaha lock
```

No password. No sshd. Console only. Root is an ephemeral initramfs (read-only story).

Phone-class image (TCG on a PC is slow):

```bash
make image-aarch64
make run-aarch64
```

## PocketHost (Android)

Folder: `android/pockethost`  
Package: `app.pockethost`  ·  minSdk 26

1. Open that folder in Android Studio.
2. You should see one card: **AahaOS / Ready / Start**.
3. **Start** tells the truth: image is Ready, in-app QEMU is not wired yet.
4. Settings: RAM + bundled disk defaults only.

Image path contract: `android/pockethost/app/src/main/assets/aahaos/`  
(`manifest.json` + `IMAGE_CONTRACT.txt`). Built images live in `images/<arch>/` after `make image`.

Gradle wrapper is valid (`./gradlew` downloads Gradle + AGP). This environment has no Android SDK, so `assembleDebug` stops at “SDK location not found”. On a machine with Android Studio / SDK:

```bash
cd android/pockethost && ./gradlew :app:assembleDebug
```

## Phone-only tester (later)

1. Install the PocketHost APK (sideload when CI/Studio builds it). You will see Ready + Start.
2. Start will **not** lie that AahaOS is running until an engine exists.
3. Next engine options (pick one later): Termux + `qemu-system-aarch64` pointed at our `vmlinuz` + `initramfs.cpio.gz`, or a JNI QEMU module that reads the same contract.
4. Do not download a random distro ISO.

## Tree

```text
os/                 AahaOS userspace (init, aaha CLI, overlay)
scripts/            fetch kernel, build initramfs, run/test QEMU
images/             generated (gitignored)
android/pockethost  one-tap host UI
```

Demo login: **none**. If a write-up says `aaha`/`aaha`, that is only a label — there is no password prompt in v1.
