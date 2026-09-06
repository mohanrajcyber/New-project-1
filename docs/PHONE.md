# Phone tester (short)

Live site (GitHub Pages, from `main`): https://mohanrajcyber.github.io/New-project-1/

0. **Web:** that URL (or `web/index.html`) is a **console demo**. Start does not boot a live guest.
1. **Real boot on the phone:** Termux + our aarch64 image. Follow [TERMUX.md](TERMUX.md).
2. **PocketHost APK:** see [APK.md](APK.md). Start copies the Termux command and opens Termux if installed. Status is Ready / Starting / Handed off / Unavailable — never Running unless this process owns QEMU (it does not).
3. **Snaps:** Create snapshot adds a local row (settings + initramfs copy if present).
4. **More:** RAM / persist-disk / Core|Net are saved and passed as `AAHA_MEM`, `AAHA_DISK`, `AAHA_VARIANT`.
5. Do not download a random ISO.
