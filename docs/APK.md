# PocketHost APK

Gradle: `android/pockethost` · `app.pockethost` · minSdk 26 · versionName **0.4.0**

## DEV release (this repo)

`dev-keystore.jks` is a **clearly labeled development key**, password `aahaosdev`.
Not a Play Store key.

```bash
cd android/pockethost
echo "sdk.dir=/path/to/Android/Sdk" > local.properties
./gradlew :app:assembleRelease
# app/build/outputs/apk/release/app-release.apk
```

Sideload copy in git: `dist/android/pockethost-debug.apk` (updated on each ship).

## What Start does

Hands off to Termux. Status Ready / Starting / Handed off / Unavailable.
Never Running unless this process owns QEMU (it does not).
