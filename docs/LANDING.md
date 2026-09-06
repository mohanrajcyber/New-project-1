# AahaOS

**Our** guest OS. One image. One tap. Pocket ready.

ஆஹா! இது நம்ம OS.

AahaOS is a custom embedded Linux — our init, our hostname `aaha`, our `aaha` CLI, our initramfs. PocketHost is the Android host UI. It is not a hypervisor clone and not an ISO shop.

**Core** — console guest (default).  
**Net** — Core plus busybox DHCP/ping applets. Still our OS, not a downloaded distro.

Phone web: open `web/index.html` (Ready → Start is a labeled console demo).  
PC: `make test` then `make run`.  
APK later: sideload PocketHost → Ready · engine off → Engine tab for the Termux sheet.

See the root [README](../README.md).
