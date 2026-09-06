#!/bin/sh
# AahaOS portable PID 1 (ash). Used on aarch64 when the C init is not
# cross-compiled. Same identity and banner as os/init.c.
# shellcheck disable=SC2169

HOSTNAME="aaha"

mkdir -p /proc /sys /dev /tmp /run /root /dev/pts 2>/dev/null
mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t devtmpfs devtmpfs /dev 2>/dev/null
mount -t tmpfs tmpfs /tmp 2>/dev/null
mount -t tmpfs tmpfs /run 2>/dev/null
mount -t devpts devpts /dev/pts 2>/dev/null

[ -e /dev/null ] || mknod /dev/null c 1 3
[ -e /dev/console ] || mknod /dev/console c 5 1

hostname "$HOSTNAME" 2>/dev/null
export PATH=/sbin:/usr/sbin:/bin:/usr/bin
export HOME=/root
export USER=aaha
export LOGNAME=aaha
export TERM=linux
export PS1='aaha@aaha:\w# '
export AAHAOS=1
cd /root || true

echo
if [ -f /etc/aaha/banner ]; then
    cat /etc/aaha/banner
fi
echo
VER="0.1.0"
if [ -f /etc/aaha/version ]; then
    VER=$(cat /etc/aaha/version)
fi
VARIANT="core"
if [ -f /etc/aaha/variant ]; then
    VARIANT=$(cat /etc/aaha/variant)
fi
echo "  AahaOS $VER  —  custom embedded Linux guest"
echo "  hostname : $HOSTNAME"
echo "  variant  : $VARIANT"
echo "  kernel   : $(uname -s) $(uname -r)"
echo "  machine  : $(uname -m)"
echo "  root     : initramfs (ephemeral, treat as read-only story)"
echo "  login    : none — console only, no password, no sshd"
echo
if [ -f /etc/motd ]; then
    cat /etc/motd
fi
echo
echo "  Type  aaha help  —  or just use the shell."
echo
if [ -x /usr/bin/aaha ]; then
    /usr/bin/aaha ident
    echo
fi

if [ "$VARIANT" = "net" ]; then
    ip link set lo up 2>/dev/null || true
    if [ -f /lib/modules/aaha/virtio_net.ko ]; then
        insmod /lib/modules/aaha/af_packet.ko 2>/dev/null || true
        insmod /lib/modules/aaha/failover.ko 2>/dev/null || true
        insmod /lib/modules/aaha/net_failover.ko 2>/dev/null || true
        insmod /lib/modules/aaha/virtio_net.ko 2>/dev/null || true
    fi
    IFACE=""
    n=0
    while [ "$n" -lt 8 ]; do
        IFACE=$(ls /sys/class/net 2>/dev/null | grep -v '^lo$' | head -n 1)
        [ -n "$IFACE" ] && break
        n=$((n + 1))
        sleep 1
    done
    if [ -n "$IFACE" ]; then
        echo "AahaOS Net: bringing up $IFACE (DHCP via udhcpc)"
        ip link set "$IFACE" up 2>/dev/null || true
        if [ -x /sbin/udhcpc ] || [ -x /bin/udhcpc ]; then
            udhcpc -i "$IFACE" -s /usr/share/udhcpc/default.script -q -t 6 -T 2 || true
        fi
        /usr/bin/aaha net || true
        echo
    else
        echo "AahaOS Net: no interface besides lo (need QEMU virtio-net)."
        echo
    fi
fi

# PID 1 must not exit.
while true; do
    if [ -x /bin/sh ]; then
        /bin/sh -l
    else
        /bin/busybox ash -l
    fi
    echo
    echo "aaha-init: shell exited — restarting console."
    sleep 1
done
