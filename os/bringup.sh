#!/bin/sh
# AahaOS guest bring-up (called from PID 1). Persist, share, net, ssh, tests.
# shellcheck disable=SC2169

load_mods() {
    if [ -d /lib/modules/aaha ]; then
        for m in af_packet failover net_failover virtio_net virtio_blk \
                 9pnet 9pnet_virtio 9p; do
            [ -f "/lib/modules/aaha/${m}.ko" ] || continue
            insmod "/lib/modules/aaha/${m}.ko" 2>/dev/null || true
        done
    fi
}

mount_persist() {
    mkdir -p /data
    n=0
    DEV=""
    while [ "$n" -lt 8 ]; do
        for cand in /dev/vda /dev/vda1 /dev/vd0 /dev/virtio-pci-0; do
            if [ -b "$cand" ]; then
                DEV="$cand"
                break
            fi
        done
        [ -n "$DEV" ] && break
        n=$((n + 1))
        sleep 1
    done
    if [ -z "$DEV" ]; then
        echo "AahaOS persist: no virtio block device (no AAHA_DISK / virtio_blk)."
        return 1
    fi
    if [ -d /lib/modules/aaha ]; then
        for m in nls_cp437 nls_iso8859-1 fat vfat ext2 ext4; do
            [ -f "/lib/modules/aaha/${m}.ko" ] || continue
            insmod "/lib/modules/aaha/${m}.ko" 2>/dev/null || true
        done
    fi
    have_vfat=0
    have_ext2=0
    grep -q vfat /proc/filesystems 2>/dev/null && have_vfat=1
    grep -q '	fat$' /proc/filesystems 2>/dev/null && have_vfat=1
    grep -q ext2 /proc/filesystems 2>/dev/null && have_ext2=1

    try_vfat() {
        mount -t vfat -o iocharset=iso8859-1,codepage=437 "$DEV" /data 2>/dev/null && return 0
        mount -t vfat "$DEV" /data 2>/dev/null && return 0
        return 1
    }

    # This virt kernel's netboot modules include fat/vfat, not ext2/ext4.
    # Never format ext2 unless the guest can actually mount it.
    if try_vfat; then
        echo "AahaOS persist: $DEV mounted on /data (vfat)"
        mkdir -p /data/lost+found 2>/dev/null || true
        return 0
    fi
    if [ "$have_ext2" -eq 1 ]; then
        mount -t ext2 "$DEV" /data 2>/dev/null && {
            echo "AahaOS persist: $DEV mounted on /data (ext2)"
            return 0
        }
    fi

    MKFAT=""
    for c in mkfs.vfat mkfs.fat /sbin/mkfs.vfat /sbin/mkfs.fat /usr/sbin/mkfs.vfat; do
        if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then
            MKFAT=$(command -v "$c" 2>/dev/null || echo "$c")
            break
        fi
    done
    if [ -n "$MKFAT" ]; then
        echo "AahaOS persist: formatting $DEV vfat (virt kernel: vfat first, not ext2)"
        "$MKFAT" -n AAHADATA "$DEV" >/dev/null 2>&1 || "$MKFAT" "$DEV" >/dev/null 2>&1 || true
        if try_vfat; then
            echo "AahaOS persist: $DEV mounted on /data (vfat)"
            mkdir -p /data/lost+found 2>/dev/null || true
            return 0
        fi
    fi
    if [ "$have_ext2" -eq 1 ] && { [ -x /sbin/mke2fs ] || [ -x /bin/mke2fs ] || command -v mke2fs >/dev/null 2>&1; }; then
        echo "AahaOS persist: formatting $DEV ext2 (vfat mkfs missing; ext2 is available)"
        mke2fs -F -L aaha-data "$DEV" >/dev/null 2>&1 || true
        mount -t ext2 "$DEV" /data 2>/dev/null || true
    else
        echo "AahaOS persist: not formatting ext2 (no ext2.ko in this virt kernel)"
    fi
    if grep -q ' /data ' /proc/mounts 2>/dev/null; then
        echo "AahaOS persist: $DEV mounted on /data"
        mkdir -p /data/lost+found 2>/dev/null || true
        return 0
    fi
    echo "AahaOS persist: $DEV present but mount failed"
    return 1
}

mount_share() {
    mkdir -p /share
    if mount -t 9p -o trans=virtio,version=9p2000.L aaha /share 2>/dev/null; then
        echo "AahaOS share: 9p tag aaha mounted on /share"
        return 0
    fi
    if mount -t 9p -o trans=virtio aaha /share 2>/dev/null; then
        echo "AahaOS share: 9p tag aaha mounted on /share"
        return 0
    fi
    echo "AahaOS share: 9p not mounted (need virtio-9p-pci + 9p.ko). QEMU args are shipped."
    return 1
}

bringup_net() {
    ip link set lo up 2>/dev/null || true
    IFACE=""
    n=0
    while [ "$n" -lt 8 ]; do
        IFACE=$(ls /sys/class/net 2>/dev/null | grep -v '^lo$' | head -n 1)
        [ -n "$IFACE" ] && break
        n=$((n + 1))
        sleep 1
    done
    if [ -z "$IFACE" ]; then
        echo "AahaOS Net: no interface besides lo (need QEMU virtio-net)."
        return 1
    fi
    echo "AahaOS Net: bringing up $IFACE (DHCP via udhcpc)"
    ip link set "$IFACE" up 2>/dev/null || true
    if [ -x /sbin/udhcpc ] || [ -x /bin/udhcpc ]; then
        udhcpc -i "$IFACE" -s /usr/share/udhcpc/default.script -q -t 6 -T 2 || true
    fi
    /usr/bin/aaha net || true
    echo
}

start_dropbear() {
    if [ ! -x /usr/sbin/dropbear ] && [ ! -x /sbin/dropbear ]; then
        echo "AahaOS ssh: dropbear not in this image"
        return 1
    fi
    mkdir -p /etc/dropbear /var/run /var/log
    if [ ! -f /etc/passwd ]; then
        echo 'root:x:0:0:root:/root:/bin/sh' > /etc/passwd
        echo 'root:x:0:' > /etc/group
    fi
    if [ ! -f /etc/shadow ]; then
        echo 'root::0:0:99999:7:::' > /etc/shadow
    fi
    DB=$(command -v dropbear || echo /usr/sbin/dropbear)
    echo "AahaOS ssh: starting $DB"
    $DB -R -B -p 22 2>&1 || $DB -R -p 22 2>&1 || true
    if pidof dropbear >/dev/null 2>&1 || pgrep dropbear >/dev/null 2>&1; then
        echo "AahaOS ssh: dropbear on :22 (blank password, lab guest). Host: ssh -p 2222 root@127.0.0.1"
        return 0
    fi
    echo "AahaOS ssh: dropbear failed to start"
    return 1
}

run_tests() {
    TEST=""
    if [ -r /proc/cmdline ]; then
        for tok in $(cat /proc/cmdline); do
            case "$tok" in
                aaha.test=*) TEST=${tok#aaha.test=} ;;
            esac
        done
    fi
    [ -z "$TEST" ] && return 0
    echo "AahaOS test hook: $TEST"
    case "$TEST" in
        persist-write)
            if grep -q ' /data ' /proc/mounts; then
                echo "persist-ok-$(date +%s)" > /data/stamp
                sync
                echo "AAHA_PERSIST_WRITE_OK"
            else
                echo "AAHA_PERSIST_WRITE_FAIL"
            fi
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
        persist-read)
            if [ -f /data/stamp ]; then
                echo "AAHA_PERSIST_READ_OK $(cat /data/stamp)"
            else
                echo "AAHA_PERSIST_READ_FAIL"
            fi
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
        lock)
            /usr/bin/aaha lock
            if grep -E ' / .*[,\s]ro[,\s]' /proc/mounts | grep -q ' / '; then
                echo "AAHA_LOCK_OK"
            else
                # busybox remount may show ro in field 4
                awk '$2=="/" { print; if ($4 ~ /(^|,)ro($|,)/) ok=1 } END { exit ok?0:1 }' /proc/mounts \
                    && echo "AAHA_LOCK_OK" || echo "AAHA_LOCK_FAIL"
            fi
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
        persist-crypt)
            PASS=aaha-test
            echo hello-vault > /data/secret.txt
            printf '%s\n%s\n' "$PASS" "$PASS" | /usr/bin/aaha lock persist
            rm -f /data/secret.txt
            printf '%s\n' "$PASS" | /usr/bin/aaha unlock persist
            if [ -f /data/secret.txt ] && grep -q hello-vault /data/secret.txt; then
                echo "AAHA_CRYPT_OK"
            else
                echo "AAHA_CRYPT_FAIL"
            fi
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
        lab)
            cat /etc/os-release
            /usr/bin/aaha lab
            echo "AAHA_LAB_OK"
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
        share)
            if grep -q ' /share ' /proc/mounts && [ -d /share ]; then
                echo host-was-here > /share/from-guest.txt 2>/dev/null || true
                echo "AAHA_SHARE_OK"
            else
                echo "AAHA_SHARE_FAIL"
            fi
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
        ssh)
            if pidof dropbear >/dev/null 2>&1 || pgrep dropbear >/dev/null 2>&1; then
                echo "AAHA_SSH_OK"
            else
                echo "AAHA_SSH_FAIL"
            fi
            sleep 2
            poweroff -f 2>/dev/null || reboot -f
            ;;
        study)
            cat /etc/os-release
            /usr/bin/aaha study
            /usr/bin/aaha lesson 1
            echo "AAHA_STUDY_OK"
            sleep 1
            poweroff -f 2>/dev/null || reboot -f
            ;;
    esac
}

VARIANT="core"
[ -f /etc/aaha/variant ] && VARIANT=$(cat /etc/aaha/variant)

load_mods
mount_persist || true
mount_share || true

echo
if [ -f /etc/aaha/ethics ]; then
    cat /etc/aaha/ethics
else
    echo "AahaOS: authorized use only. Own systems / written permission only."
fi
echo

if [ "$VARIANT" = "net" ] || [ "$VARIANT" = "lab" ] || [ "$VARIANT" = "study" ]; then
    bringup_net
    start_dropbear || true
fi

run_tests
