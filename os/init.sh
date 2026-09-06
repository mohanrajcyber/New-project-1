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
echo "  root     : initramfs + /data persist when AAHA_DISK is set"
echo "  login    : console; dropbear on Net/Lab (blank password, host :2222)"
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

if [ -x /usr/lib/aaha/bringup.sh ]; then
    /bin/sh /usr/lib/aaha/bringup.sh
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
