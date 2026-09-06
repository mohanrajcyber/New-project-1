# Phone boot (Termux) — AahaOS 0.4

Boots **our** aarch64 image. Repo is public.

```bash
pkg update
pkg install qemu-system-aarch64-headless wget
# optional persist format on the phone:
pkg install dosfstools
curl -fsSL -o ~/termux-boot-aahaos.sh \
  https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/scripts/termux-boot-aahaos.sh
chmod +x ~/termux-boot-aahaos.sh
```

**Core** (local, persist `/data` if `AAHA_DISK>0`):

```bash
AAHA_VARIANT=core AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
```

**Net** (DHCP + dropbear, host `2222→22`):

```bash
AAHA_VARIANT=net AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
# other Termux session:
ssh -p 2222 -o StrictHostKeyChecking=no root@127.0.0.1
# blank password
```

**Lab** (Net + extra applets, `PRETTY_NAME` Lab):

```bash
AAHA_VARIANT=lab AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh
```

**Share on LAN** (second phone, same Wi-Fi):

```bash
curl -fsSL -o ~/share-aahaos.sh \
  https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/scripts/share-aahaos.sh
bash ~/share-aahaos.sh
# on the other phone:
AAHA_RAW=http://PHONE_IP:8766 AAHA_VARIANT=core bash ~/termux-boot-aahaos.sh
```

**Serial log** (optional, for PocketHost paste):

```bash
script -q ~/aahaos/serial.log bash ~/termux-boot-aahaos.sh
```

Inside the guest: `aaha lock` remounts `/` ro. `aaha lock persist` / `aaha unlock persist` openssl-tars `/data`. Host share dir `~/aaha-share` is passed as virtio-9p; this kernel’s netboot modules have **no 9p.ko**, so `/share` may stay unmounted (QEMU args are still shipped).

Quit QEMU: `Ctrl-A x`.
