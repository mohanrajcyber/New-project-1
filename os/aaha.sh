#!/bin/sh
# Portable aaha CLI (used when C binary is not built for this arch).
set -eu

usage() {
    cat <<'EOF'
aaha — AahaOS operator CLI

Usage: aaha <command>

  status   OS identity, kernel, hostname
  net      local interfaces (no scanner, no exploit tools)
  lock     read-only-root reminder (v1 stub)
  help     this text
EOF
}

cmd_status() {
    echo "AahaOS status"
    echo "-------------"
    echo "os        : AahaOS (custom embedded Linux)"
    echo "not       : VMware, Windows, Alpine installer, from-scratch kernel"
    if [ -f /etc/os-release ]; then
        grep -E '^(PRETTY_NAME|VERSION_ID|ID)=' /etc/os-release || true
    fi
    echo "hostname  : $(hostname 2>/dev/null || echo aaha)"
    echo "kernel    : $(uname -s) $(uname -r) ($(uname -m))"
    echo "rootfs    : initramfs (ephemeral). Persist is a later host job."
    echo "auth      : no password login; console only."
}

cmd_net() {
    echo "AahaOS net (local view)"
    echo "-----------------------"
    if [ -r /proc/net/dev ]; then
        cat /proc/net/dev
    else
        echo "no /proc/net/dev — proc not mounted?"
    fi
    echo
    echo "This command only lists what the kernel already exposes."
}

cmd_lock() {
    cat <<'EOF'
aaha lock (v1 stub)
-------------------
AahaOS v1 boots an ephemeral initramfs. Treat the guest as
read-only: reboot loses /tmp. There is no disk unlock secret,
no default password, and no remote lock service.

Not armed. Not a backdoor. PocketHost will own persist later.
EOF
}

cmd="${1:-}"
case "$cmd" in
    status) cmd_status ;;
    net) cmd_net ;;
    lock) cmd_lock ;;
    help|-h|--help) usage ;;
    "") usage; exit 1 ;;
    *) echo "aaha: unknown command '$cmd'" >&2; usage; exit 1 ;;
esac
