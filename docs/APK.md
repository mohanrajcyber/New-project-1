# PocketHost APK

Gradle project: `android/pockethost`  
package `app.pockethost` · minSdk 26 · versionName 0.3.0

## Build on a machine with Android SDK

```bash
cd android/pockethost
# create local.properties with:  sdk.dir=/path/to/Android/Sdk
./gradlew :app:assembleDebug
# unsigned debug APK:
#   app/build/outputs/apk/debug/app-debug.apk
./gradlew :app:bundleRelease
# AAB (needs a signing config you add locally):
#   app/build/outputs/bundle/release/app-release.aab
```

Sideload the debug APK (USB debugging or “install unknown apps”).

A debug APK from this environment is committed at
`dist/android/pockethost-debug.apk` (see `docs/APK-STATUS.txt`).

## This cloud VM

See the “SDK status” note written when 0.3 was built (`docs/APK-STATUS.txt` if present).
The wrapper and project are valid either way. Missing SDK is an environment limit,
not a broken Gradle tree.

## What Start does

1. Detects Termux (`com.termux`) via package queries.
2. Copies the boot command (RAM / disk / variant from Settings).
3. Tries `com.termux.RUN_COMMAND`, else launches Termux.
4. Status: **Ready** · **Starting** · **Handed to Termux** · **Unavailable**.
   Never **Running** — this APK does not embed QEMU.
