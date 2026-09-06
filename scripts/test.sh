#!/usr/bin/env bash
# Full guest proof: CLI smoke + both arches + Net variant on x86_64.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== compile aaha CLI (host smoke)"
mkdir -p build/host
gcc -static -Os -Wall -Wextra -o build/host/aaha os/aaha.c
./build/host/aaha help | grep -q ident
./build/host/aaha mem | grep -q MemTotal
./build/host/aaha ident | grep -q AahaOS
echo "PASS: host aaha CLI"

echo "== boot x86_64 core"
./scripts/build-image.sh x86_64 core
./scripts/test-boot.sh x86_64 core

echo "== boot aarch64 core"
./scripts/build-image.sh aarch64 core
./scripts/test-boot.sh aarch64 core

echo "== boot x86_64 net (our Net variant + virtio-net)"
./scripts/build-image.sh x86_64 net
./scripts/test-boot.sh x86_64 net

echo "== boot aarch64 net (phone-class Net image)"
./scripts/build-image.sh aarch64 net
./scripts/test-boot.sh aarch64 net

echo
echo "PASS: make test (x86_64/aarch64 core + x86_64/aarch64 net)"
