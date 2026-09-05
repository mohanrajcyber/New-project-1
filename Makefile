# AahaOS + PocketHost
# Guest image: custom embedded Linux. Host UI: PocketHost (not VMware).

ARCH ?= x86_64
.PHONY: image run test-boot image-aarch64 run-aarch64 android help clean

help:
	@echo "AahaOS (guest) + PocketHost (host UI)"
	@echo
	@echo "  make image            build x86_64 bootable image"
	@echo "  make run              boot AahaOS in QEMU (serial)"
	@echo "  make test-boot        headless serial proof"
	@echo "  make image-aarch64    build phone-class image config"
	@echo "  make run-aarch64      boot aarch64 under TCG (slow)"
	@echo "  make android          print how to open the Gradle project"
	@echo "  make clean            remove build/ and images/"

image:
	./scripts/build-image.sh $(ARCH)

run: image
	./scripts/run-qemu.sh $(ARCH)

test-boot: image
	./scripts/test-boot.sh $(ARCH)

image-aarch64:
	./scripts/build-image.sh aarch64

run-aarch64: image-aarch64
	./scripts/run-qemu.sh aarch64

android:
	@echo "Open android/pockethost in Android Studio."
	@echo "If the Android SDK is installed:  cd android/pockethost && ./gradlew :app:assembleDebug"

clean:
	rm -rf build images
