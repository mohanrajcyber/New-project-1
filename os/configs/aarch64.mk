# AahaOS aarch64 guest (phone-class later; TCG works on x86 hosts)
ARCH := aarch64
QEMU := qemu-system-aarch64
QEMU_MACHINE := virt
QEMU_CPU := max
CONSOLE := ttyAMA0
KERNEL_CMDLINE := console=ttyAMA0 rdinit=/sbin/init panic=5
KERNEL_URL := https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/netboot/vmlinuz-virt
KERNEL_SHA256 := 749eb77d8c0a887868166c220e36411400b9bed5df6443b201c96950faf0f8ac
BUSYBOX_SRC := alpine-static
BUSYBOX_URL := https://dl-cdn.alpinelinux.org/alpine/v3.21/main/aarch64/busybox-static-1.37.0-r14.apk
BUSYBOX_SHA256 := 6fd7ea97062beb51fa785ba858f823e1dfe4daf6bfa91ff4d5359b1061988c69
