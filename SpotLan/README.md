# SpotLan

Phone app for a new place: see the Wi‑Fi you’re on, discover live LAN hosts, and list open service ports / server banners.

## What it shows

- **Wi‑Fi SSID** (needs location permission on Android/iOS)
- **Your IP**, subnet, gateway guess
- **Live devices** on the current `/24`
- **Open ports** with service names (HTTP(S), printer, SSH-ish probes, etc.)
- **Server banners / page titles** when a web service answers

## Run on your phone

```bash
cd SpotLan
npm install
npx expo start
```

Scan the QR code with **Expo Go** (Android) or the Camera app (iOS).

## Notes

- SpotLan only probes the LAN you are connected to.
- Discovery is strongest for devices that expose HTTP(S) / web UIs (routers, printers, NAS, cameras).
- Use only on networks you own or have permission to inspect.
