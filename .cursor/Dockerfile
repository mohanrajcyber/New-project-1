# AahaOS + PocketHost — Cloud Agent base image.
# Provides the toolchain the "Proof on a Linux PC" flow needs:
# QEMU (x86_64 + aarch64), a static busybox for the guest rootfs, and the
# standard build utilities (gcc, make, cpio, gzip, curl, file).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gcc \
        make \
        cpio \
        gzip \
        file \
        binutils \
        qemu-system-x86 \
        qemu-system-arm \
        busybox-static \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# The official ubuntu:24.04 image ships a non-root "ubuntu" user (uid 1000);
# Cloud Agent runs as that user.
USER ubuntu
