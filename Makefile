# AahaOS + PocketHost
ARCH ?= x86_64
VARIANT ?= core
.PHONY: image run test test-boot test-features image-aarch64 image-aarch64-net image-aarch64-lab image-aarch64-study run-aarch64 image-net image-lab image-study test-net publish-dist android web share help clean

help:
	@echo "AahaOS (guest) + PocketHost (host UI)"
	@echo "  make test            core/net/lab/study boots + persist/lock proofs"
	@echo "  make test-features   persist survive, lock, lab, study (this QEMU)"
	@echo "  make publish-dist    aarch64 core+net+lab+study -> dist/"
	@echo "  make share           LAN HTTP for dist/aarch64"

image:
	./scripts/build-image.sh $(ARCH) $(VARIANT)

run: image
	./scripts/run-qemu.sh $(ARCH) $(VARIANT)

test:
	./scripts/test.sh

test-boot: image
	./scripts/test-boot.sh $(ARCH) $(VARIANT)

test-features:
	./scripts/test-features.sh $(ARCH)

image-aarch64:
	./scripts/build-image.sh aarch64 core

image-aarch64-net:
	./scripts/build-image.sh aarch64 net

image-aarch64-lab:
	./scripts/build-image.sh aarch64 lab

image-aarch64-study:
	./scripts/build-image.sh aarch64 study

run-aarch64: image-aarch64
	./scripts/run-qemu.sh aarch64 core

image-net:
	./scripts/build-image.sh x86_64 net

image-lab:
	./scripts/build-image.sh x86_64 lab

image-study:
	./scripts/build-image.sh x86_64 study

test-net: image-net
	./scripts/test-boot.sh x86_64 net

publish-dist:
	./scripts/publish-dist.sh

share:
	./scripts/share-aahaos.sh

android:
	@echo "cd android/pockethost && ./gradlew :app:assembleRelease"
	@echo "DEV-signed APK -> dist/android/pockethost-debug.apk (see docs/APK.md)"

web:
	python3 -m http.server 8765 --bind 127.0.0.1 --directory web

clean:
	rm -rf build images/*/vmlinuz images/*/initramfs.cpio.gz images/*/manifest.json images/*-net images/*-lab images/*-study
