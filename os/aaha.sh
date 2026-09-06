#!/bin/sh
# Portable aaha CLI (used when C binary is not built for this arch).
set -eu

usage() {
    cat <<'EOF'
aaha — AahaOS operator CLI

Usage: aaha <command>

  status   short OS identity
  ident    full identity (variant, os-release, machine)
  mem      memory from /proc/meminfo (real)
  net      local interfaces the kernel already exposes
  lock     read-only-root reminder + current mount flags
  help     this text
EOF
}

variant() {
    if [ -f /etc/aaha/variant ]; then
        cat /etc/aaha/variant
    else
        echo core
    fi
}

os_keys() {
    if [ -f /etc/os-release ]; then
        grep -E '^(PRETTY_NAME|VERSION_ID|ID|VARIANT|VARIANT_ID)=' /etc/os-release || true
    fi
}

cmd_status() {
    echo "AahaOS status"
    echo "-------------"
    echo "os        : AahaOS (custom embedded Linux)"
    echo "not       : hypervisor clone, Windows, distro installer, from-scratch kernel"
    os_keys
    echo "variant   : $(variant)"
    echo "hostname  : $(hostname 2>/dev/null || echo aaha)"
    echo "kernel    : $(uname -s) $(uname -r) ($(uname -m))"
    echo "rootfs    : initramfs (ephemeral). Persist is a later host job."
    echo "auth      : no password login; console only."
}

cmd_ident() {
    echo "AahaOS identity"
    echo "---------------"
    echo "product   : AahaOS $(cat /etc/aaha/version 2>/dev/null || echo 0.3.0)"
    echo "variant   : $(variant)  (Core = console guest, Net = Core + DHCP applets)"
    echo "hostname  : $(hostname 2>/dev/null || echo aaha)"
    os_keys
    echo "uname     : $(uname -a)"
    echo "prompt    : aaha@aaha"
    echo "services  : none (no sshd, no getty login)"
}

cmd_mem() {
    echo "AahaOS mem"
    echo "----------"
    if [ -r /proc/meminfo ]; then
        grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached):' /proc/meminfo || true
    else
        echo "no /proc/meminfo — proc not mounted?"
    fi
    echo "Source: /proc/meminfo (this guest). Not a host leak tool."
}

cmd_net() {
    echo "AahaOS net (local view)"
    echo "-----------------------"
    echo "variant   : $(variant)"
    ifaces=""
    if [ -d /sys/class/net ]; then
        for n in /sys/class/net/*; do
            [ -e "$n" ] || continue
            ifaces="$ifaces ${n##*/}"
        done
    fi
    echo "ifaces    :${ifaces:- (none)}"
    if [ -r /proc/net/dev ]; then
        cat /proc/net/dev
    else
        echo "no /proc/net/dev — proc not mounted?"
    fi
    if [ "$(variant)" = "net" ]; then
        echo
        echo "IPv4 routes (/proc/net/route):"
        if [ -r /proc/net/route ]; then
            cat /proc/net/route
        else
            echo "(no /proc/net/route)"
        fi
        echo
        echo "Net variant includes busybox udhcpc + ping. No port scan, no exploit tools."
    else
        echo
        echo "Core variant: interface list only. AahaOS Net adds DHCP applets."
    fi
    echo "This command only lists what the kernel already exposes."
}

cmd_lock() {
    cat <<'EOF'
aaha lock
---------
Reminder: AahaOS v0.3 boots an ephemeral initramfs.
Reboot loses /tmp. No disk unlock secret, no password, no sshd.
Not a backdoor. Not a security boundary.

EOF
    if [ -r /proc/mounts ]; then
        awk '$2=="/" { print "root mount: " $1 " " $2 " (" $3 ") " $4 }' /proc/mounts | head -n 1
    else
        echo "root mount: (no /proc/mounts)"
    fi
    echo "PocketHost will own persist / snapshots later."
}

cmd="${1:-}"
case "$cmd" in
    status) cmd_status ;;
    ident) cmd_ident ;;
    mem) cmd_mem ;;
    net) cmd_net ;;
    lock) cmd_lock ;;
    help|-h|--help) usage ;;
    "") usage; exit 1 ;;
    *) echo "aaha: unknown command '$cmd'" >&2; usage; exit 1 ;;
esac
