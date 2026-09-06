# AahaOS

**Our** guest OS. One image. One tap. Pocket ready.

ஆஹா! இது நம்ம OS.

AahaOS is a custom embedded Linux — our init, our hostname `aaha`, our `aaha` CLI, our initramfs. PocketHost is the Android host UI. It is not a hypervisor clone and not an ISO shop.

**Core** — console guest, local-only (default).  
**Net** — Core plus `virtio-net` + DHCP + dropbear (`ssh -p 2222`).  
**Lab** — Net plus extra applets (`aaha lab`). Distinct `PRETTY_NAME`.

Live site (demo, not a VM): https://mohanrajcyber.github.io/New-project-1/

**Phone boot (real guest):** [TERMUX.md](TERMUX.md)  
**APK:** [APK.md](APK.md)  
PC: `make test` then `make run`.

See the root [README](../README.md).
