#!/bin/sh
# Portable aaha CLI (used on all arches in v0.4).
set -eu

usage() {
    cat <<'EOF'
aaha — AahaOS operator CLI

Usage: aaha <command>

  status   short OS identity
  ident    full identity (variant, os-release, machine)
  mem      memory from /proc/meminfo (real)
  net      local interfaces the kernel already exposes
  lock     remount / read-only (changes /proc/mounts)
  lock persist     encrypt /data with openssl AES-256 (passphrase)
  unlock           remount / read-write
  unlock persist   decrypt /data vault
  lab      Lab tools menu (Lab variant)
  study    Study menu (authorized classroom tools)
  lesson   1–4  run a Study lesson against this guest
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
    if grep -q ' /data ' /proc/mounts 2>/dev/null; then
        echo "persist   : /data mounted"
    else
        echo "persist   : /data not mounted"
    fi
    if grep -q ' /share ' /proc/mounts 2>/dev/null; then
        echo "share     : /share mounted (9p)"
    else
        echo "share     : /share not mounted"
    fi
    echo "auth      : console; dropbear on Net/Lab (blank password, not a boundary)."
}

cmd_ident() {
    echo "AahaOS identity"
    echo "---------------"
    echo "product   : AahaOS $(cat /etc/aaha/version 2>/dev/null || echo 0.4.0)"
    echo "variant   : $(variant)  (Core / Net / Lab / Study)"
    echo "hostname  : $(hostname 2>/dev/null || echo aaha)"
    os_keys
    echo "uname     : $(uname -a)"
    echo "prompt    : aaha@aaha"
    echo "services  : dropbear on Net/Lab only; no getty login"
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
    echo
    echo "SSH (Net/Lab/Study): dropbear :22 — from host  ssh -p 2222 root@127.0.0.1"
    echo "This command only lists what the kernel already exposes."
}

ethics() {
    echo
    if [ -f /etc/aaha/ethics ]; then
        cat /etc/aaha/ethics
    else
        echo "Authorized use only. Only systems you own or have written permission to test."
    fi
    echo
}

root_flags() {
    awk '$2=="/" { print $4; exit }' /proc/mounts 2>/dev/null || echo "?"
}

cmd_lock() {
    echo "aaha lock"
    echo "---------"
    echo "Remounting / read-only. Not a security boundary. Not a backdoor."
    if mount -o remount,ro / 2>/dev/null; then
        echo "remount   : ok"
    else
        echo "remount   : failed ($?)"
    fi
    echo "root flags: $(root_flags)"
    awk '$2=="/" { print "root mount: " $1 " " $2 " (" $3 ") " $4 }' /proc/mounts | head -n 1
}

cmd_unlock() {
    echo "aaha unlock"
    echo "-----------"
    if mount -o remount,rw / 2>/dev/null; then
        echo "remount   : rw ok"
    else
        echo "remount   : failed"
    fi
    echo "root flags: $(root_flags)"
}

cmd_lock_persist() {
    if ! grep -q ' /data ' /proc/mounts; then
        echo "aaha lock persist: /data is not mounted" >&2
        exit 1
    fi
    if [ ! -x /usr/bin/openssl ] && [ ! -x /bin/openssl ]; then
        echo "aaha lock persist: openssl not in this image" >&2
        exit 1
    fi
    if [ -f /data/.aaha-vault.enc ]; then
        echo "already locked ( /data/.aaha-vault.enc exists )" >&2
        exit 1
    fi
    echo "Passphrase (will not echo if tty):"
    if [ -t 0 ]; then
        stty -echo 2>/dev/null || true
        read -r PASS
        stty echo 2>/dev/null || true
        echo
        echo "Again:"
        stty -echo 2>/dev/null || true
        read -r PASS2
        stty echo 2>/dev/null || true
        echo
        [ "$PASS" = "$PASS2" ] || { echo "mismatch" >&2; exit 1; }
    else
        read -r PASS
        read -r PASS2 || PASS2=$PASS
        [ "$PASS" = "$PASS2" ] || { echo "mismatch" >&2; exit 1; }
    fi
    TMP=/run/aaha-vault.enc
    PLAIN=/run/aaha-plain
    mkdir -p /run "$PLAIN"
    rm -rf "$PLAIN"
    mkdir -p "$PLAIN"
    for f in /data/* /data/.[!.]* /data/..?*; do
        [ -e "$f" ] || continue
        base=${f#/data/}
        case "$base" in
            .aaha-vault.enc|.aaha-locked) continue ;;
        esac
        cp -a "$f" "$PLAIN/" 2>/dev/null || true
    done
    if ! tar -C "$PLAIN" -cf - . \
        | openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:"$PASS" -out "$TMP"; then
        echo "aaha lock persist: openssl/tar failed" >&2
        rm -rf "$PLAIN" "$TMP"
        unset PASS PASS2
        exit 1
    fi
    rm -rf "$PLAIN"
    for f in /data/* /data/.[!.]* /data/..?*; do
        [ -e "$f" ] || continue
        base=${f#/data/}
        case "$base" in
            .aaha-vault.enc|.aaha-locked) continue ;;
        esac
        rm -rf "$f"
    done
    mv "$TMP" /data/.aaha-vault.enc
    echo locked > /data/.aaha-locked
    unset PASS PASS2
    echo "persist encrypted -> /data/.aaha-vault.enc (openssl aes-256-cbc pbkdf2)"
}

cmd_unlock_persist() {
    if [ ! -f /data/.aaha-vault.enc ]; then
        echo "aaha unlock persist: no vault" >&2
        exit 1
    fi
    echo "Passphrase:"
    if [ -t 0 ]; then
        stty -echo 2>/dev/null || true
        read -r PASS
        stty echo 2>/dev/null || true
        echo
    else
        read -r PASS
    fi
    TMP=/run/aaha-plain.tar
    if ! openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$PASS" \
        -in /data/.aaha-vault.enc -out "$TMP"; then
        echo "decrypt failed" >&2
        rm -f "$TMP"
        unset PASS
        exit 1
    fi
    tar -C /data -xf "$TMP"
    rm -f "$TMP" /data/.aaha-vault.enc /data/.aaha-locked
    unset PASS
    echo "persist unlocked"
}

cmd_lab() {
    echo "AahaOS Lab"
    echo "----------"
    echo "PRETTY_NAME=$(grep ^PRETTY_NAME= /etc/os-release 2>/dev/null || echo unknown)"
    echo "variant    : $(variant)"
    echo
    echo "Extra applets (no exploit kits):"
    for t in hexdump od nc wget ping tcpdump strace; do
        if command -v "$t" >/dev/null 2>&1; then
            echo "  $t  yes"
        else
            echo "  $t  no"
        fi
    done
    echo
    echo "Try: hexdump -C /etc/aaha/version"
    echo "     od -An -tx1 /etc/aaha/variant"
    echo "Not a scanner. Not malware."
}

cmd_study() {
    echo "AahaOS Study"
    echo "------------"
    ethics
    echo "PRETTY_NAME=$(grep ^PRETTY_NAME= /etc/os-release 2>/dev/null || echo unknown)"
    echo "variant    : $(variant)"
    echo
    echo "Classroom applets (this guest only — not Kali, not an attack suite):"
    for t in hexdump od nc wget ping tcpdump strace sha256sum traceroute openssl; do
        if command -v "$t" >/dev/null 2>&1; then
            echo "  $t  yes"
        else
            echo "  $t  no"
        fi
    done
    echo
    echo "Lessons (run inside this guest, against this guest):"
    echo "  aaha lesson 1   identity / kernel / mounts"
    echo "  aaha lesson 2   hash a file you create"
    echo "  aaha lesson 3   loopback traffic (tcpdump or explain)"
    echo "  aaha lesson 4   read-only lock + persist encrypt reminder"
    echo
    echo "No nmap. No exploit kits. No wordlists. Not a Kali clone."
}

lesson1() {
    echo "Lesson 1 — who is this guest?"
    echo "Observe: PRETTY_NAME, kernel, mounts. This is YOUR VM."
    /usr/bin/aaha ident 2>/dev/null || cmd_ident
    echo
    echo "--- /proc/mounts (first lines) ---"
    head -n 8 /proc/mounts 2>/dev/null || true
    echo
    echo "What to notice: hostname aaha, our os-release, /data if persist mounted."
}

lesson2() {
    echo "Lesson 2 — hash a file you own"
    echo "Observe: SHA-256 of a file you just created. Not cracking. Not other machines."
    DIR=/tmp
    grep -q ' /data ' /proc/mounts 2>/dev/null && DIR=/data
    FN="$DIR/aaha-lesson2.txt"
    echo "AahaOS study note $(date +%s)" > "$FN"
    echo "created   : $FN"
    echo "contents  : $(cat "$FN")"
    if command -v openssl >/dev/null 2>&1; then
        echo -n "openssl   : "
        openssl dgst -sha256 "$FN"
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        echo -n "sha256sum : "
        sha256sum "$FN"
    fi
    echo
    echo "What to notice: same digest from openssl and sha256sum when both exist."
}

lesson3() {
    echo "Lesson 3 — loopback only"
    echo "Observe: packets on lo (127.0.0.1). Never point this at someone else's host."
    ip link set lo up 2>/dev/null || true
    echo "--- ping 127.0.0.1 ---"
    if command -v ping >/dev/null 2>&1; then
        ping -c 1 127.0.0.1 2>/dev/null || ping -c 1 -W 2 127.0.0.1 || true
    else
        echo "ping applet not in this image"
    fi
    if command -v tcpdump >/dev/null 2>&1; then
        echo "--- tcpdump -i lo -c 2 (localhost) ---"
        ping -c 2 127.0.0.1 >/dev/null 2>&1 &
        tcpdump -i lo -c 2 -n 2>/dev/null || tcpdump -i lo -c 2 2>/dev/null || \
            echo "tcpdump ran; if empty, lo produced no capture in this window."
        wait 2>/dev/null || true
    else
        echo "tcpdump not in this image. On Study/Lab it is bundled when size allows."
        echo "You would run: tcpdump -i lo -c 4   and ping 127.0.0.1"
    fi
    echo
    echo "What to notice: ICMP or any lo packets are this guest talking to itself."
}

lesson4() {
    echo "Lesson 4 — lock this guest's own root"
    echo "Observe: /proc/mounts flags change to ro. Then we unlock so you can keep working."
    cmd_lock
    echo
    echo "Persist encrypt is optional and local:"
    echo "  aaha lock persist    openssl-tar /data (passphrase you choose)"
    echo "  aaha unlock persist  decrypt that vault"
    echo "Not a backdoor. Not for other people's disks."
    echo
    cmd_unlock
    echo
    echo "What to notice: root flags went ro, then rw. Persist encrypt needs /data mounted."
}

cmd_lesson() {
    ethics
    n="${1:-}"
    case "$n" in
        1) lesson1 ;;
        2) lesson2 ;;
        3) lesson3 ;;
        4) lesson4 ;;
        ""|list|help)
            echo "aaha lesson 1|2|3|4"
            echo "  1 identity   2 hash own file   3 loopback   4 lock"
            ;;
        *)
            echo "aaha lesson: unknown '$n' (use 1-4)" >&2
            exit 1
            ;;
    esac
}

cmd="${1:-}"
sub="${2:-}"
case "$cmd" in
    status) cmd_status ;;
    ident) cmd_ident ;;
    mem) cmd_mem ;;
    net) cmd_net ;;
    lock)
        if [ "$sub" = "persist" ]; then
            cmd_lock_persist
        else
            cmd_lock
        fi
        ;;
    unlock)
        if [ "$sub" = "persist" ]; then
            cmd_unlock_persist
        else
            cmd_unlock
        fi
        ;;
    lab) cmd_lab ;;
    study) cmd_study ;;
    lesson) cmd_lesson "$sub" ;;
    help|-h|--help) usage ;;
    "") usage; exit 1 ;;
    *) echo "aaha: unknown command '$cmd'" >&2; usage; exit 1 ;;
esac
