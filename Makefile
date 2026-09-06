# AahaOS + PocketHost
# Guest image: custom embedded Linux. Host UI: PocketHost.

ARCH ?= x86_64
VARIANT ?= core
.PHONY: image run test test-boot image-aarch64 run-aarch64 image-net test-net android web help clean

help:
	@echo "AahaOS (guest) + PocketHost (host UI)"
	@echo
	@echo "  make image            build $(ARCH) $(VARIANT) bootable image"
	@echo "  make run              boot AahaOS in QEMU (serial)"
	@echo "  make test             banner grep: x86_64 + aarch64 + Net"
	@echo "  make test-boot        headless serial proof (one arch)"
	@echo "  make image-aarch64    phone-class Core image"
	@echo "  make image-net        AahaOS Net (DHCP applets) for x86_64"
	@echo "  make android          how to open the Gradle project"
	@echo "  make web              serve web/ on http://127.0.0.1:8765"
	@echo "  make clean            remove build/ and generated images"

image:
	./scripts/build-image.sh $(ARCH) $(VARIANT)

run: image
	./scripts/run-qemu.sh $(ARCH) $(VARIANT)

test:
	./scripts/test.sh

test-boot: image
	./scripts/test-boot.sh $(ARCH) $(VARIANT)

image-aarch64:
	./scripts/build-image.sh aarch64 core

run-aarch64: image-aarch64
	./scripts/run-qemu.sh aarch64 core

image-net:
	./scripts/build-image.sh x86_64 net

test-net: image-net
	./scripts/test-boot.sh x86_64 net

android:
	@echo "Open android/pockethost in Android Studio."
	@echo "If the Android SDK is installed:  cd android/pockethost && ./gradlew :app:assembleDebug"

web:
	@echo "Phone page: http://127.0.0.1:8765/"
	python3 -m http.server 8765 --bind 127.0.0.1 --directory web

clean:
	rm -rf build images/*/vmlinuz images/*/initramfs.cpio.gz images/*/manifest.json images/*-net
