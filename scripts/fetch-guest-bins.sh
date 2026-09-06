#!/usr/bin/env bash
# Fetch Alpine-built binaries we need (dropbear, openssl, musl).
# Userspace identity stays AahaOS. These are extra tools, not a distro.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${1:-x86_64}"
WANT_LAB="${2:-}"
DEST="$ROOT/build/${ARCH}/guest-bins"
MIRROR="https://dl-cdn.alpinelinux.org/alpine/v3.21/main/${ARCH}"
mkdir -p "$DEST/root" "$ROOT/build/${ARCH}"

html=$(curl -fsSL "$MIRROR/")
pick() {
    printf '%s\n' "$html" | grep -oE "$1" | head -n1 || true
}

apk_get() {
    local name="$1"
    [[ -n "$name" ]] || return 0
    local cache="$ROOT/build/${ARCH}/apk-${name}"
    if [[ ! -f "$cache" ]]; then
        echo "fetch $name"
        curl -fL --retry 4 --retry-delay 2 -o "$cache" "$MIRROR/$name"
    fi
    tar -xzf "$cache" -C "$DEST/root"
}

rm -rf "$DEST/root"
mkdir -p "$DEST/root"

musl=$(pick 'musl-1\.[0-9.]+-r[0-9]+\.apk')
drop=$(pick 'dropbear-2024\.[0-9]+-r[0-9]+\.apk')
crypto=$(pick 'libcrypto3-3\.[0-9.]+-r[0-9]+\.apk')
ssl3=$(pick 'libssl3-3\.[0-9.]+-r[0-9]+\.apk')
ssl=$(pick 'openssl-3\.[0-9.]+-r[0-9]+\.apk')
z=$(pick 'zlib-1\.[0-9.]+-r[0-9]+\.apk')
ut=$(pick 'utmps-libs-[0-9][^"<]*\.apk')
ska=$(pick 'skalibs-libs-[0-9][^"<]*\.apk')
dos=$(pick 'dosfstools-[0-9][^"<]*\.apk')
echo "pkgs musl=$musl dropbear=$drop openssl=$ssl zlib=$z utmps=$ut skalibs=$ska dosfstools=$dos"
apk_get "$musl"
apk_get "$drop"
apk_get "$crypto"
apk_get "$ssl3"
apk_get "$ssl"
apk_get "$z"
apk_get "$ut"
apk_get "$ska"
apk_get "$dos"
if [[ "$WANT_LAB" == "lab" || "$WANT_LAB" == "study" ]]; then
    st=$(pick 'strace-6\.[0-9.]+-r[0-9]+\.apk')
    td=$(pick 'tcpdump-[0-9][^"<]*\.apk')
    pc=$(pick 'libpcap-[0-9][^"<]*\.apk')
    echo "strace=$st tcpdump=$td libpcap=$pc"
    apk_get "$st"
    apk_get "$pc"
    apk_get "$td"
fi
rm -f "$DEST/root"/.PKGINFO "$DEST/root"/.SIGN* 2>/dev/null || true
echo "guest bins staged under $DEST/root"
find "$DEST/root" -type f \( -name dropbear -o -name openssl -o -name strace -o -name 'ld-musl*' \) | head
