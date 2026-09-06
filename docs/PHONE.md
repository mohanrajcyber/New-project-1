# Phone tester (short)

0. **Web now:** open `web/index.html` on GitHub preview (Ready → Start = labeled console demo, not a live guest).
1. Sideload PocketHost (`android/pockethost`) when you have an APK.
2. **AahaOS** tab: status **Ready** + **engine off**. Start does **not** claim the guest is running.
3. **Engine** tab: Termux command sheet + copy. Point QEMU at **our** `vmlinuz` + `initramfs.cpio.gz` (from `make image-aarch64`).
4. **Snaps** tab: empty on purpose — no guest disk yet, no fake restore points.
5. Do not download a random ISO.
