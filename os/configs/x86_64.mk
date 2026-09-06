# AahaOS x86_64 guest (QEMU proof target)
ARCH := x86_64
QEMU := qemu-system-x86_64
QEMU_MACHINE := q35
QEMU_CPU := max
CONSOLE := ttyS0
KERNEL_CMDLINE := console=ttyS0,115200 rdinit=/sbin/init panic=5
KERNEL_URL := https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/netboot/vmlinuz-virt
KERNEL_SHA256 := 26bf81ada3e8fc30fd4d81805fe6c8c60be5c7fb18a43563c707e49117e624ca
# Linux kernel only (Alpine virt build). Userspace is AahaOS, not Alpine.
BUSYBOX_SRC := host
