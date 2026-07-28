# Install SpotLan on your phone

## Fastest — Expo Go (same Wi‑Fi as your laptop)

1. Phone-ல **Expo Go** install பண்ணு  
   - Android: [Play Store](https://play.google.com/store/apps/details?id=host.exp.exponent)  
   - iOS: [App Store](https://apps.apple.com/app/expo-go/id982107779)
2. Laptop-ல:
   ```bash
   cd SpotLan
   npm install
   npm run phone
   ```
3. Terminal-ல வரும் **QR code**-ஐ Expo Go-ல scan பண்ணு (iOS: Camera app).
4. App open ஆகும் — home Wi‑Fi-ல connect பண்ணி **Scan this place** tap பண்ணு.

Laptop ↔ phone different network / cloud machine ஆனா:

```bash
npm run phone:tunnel
```

Tunnel QR use பண்ணு (internet வேணும்).

## Own installable APK (Android, no Expo Go)

Expo account + EAS:

```bash
cd SpotLan
npm i -g eas-cli
eas login
eas build -p android --profile preview
```

Build முடிஞ்சா download link வரும் — phone-ல APK install பண்ணிக்கலாம்.

## Notes

- Location permission allow பண்ணு (SSID காட்ட).
- Local network / Wi‑Fi permission allow பண்ணு (iOS).
- உங்க network / permission உள்ள network-ல மட்டும் scan பண்ணு.
