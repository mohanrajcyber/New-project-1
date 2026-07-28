# SpotLan

Phone app for a new place: see the Wi‑Fi you’re on, discover live LAN hosts, and list open service ports / server banners — with website-grade motion UI.

## What it shows

- **Wi‑Fi SSID** (needs location permission on Android/iOS)
- **Your IP**, subnet, gateway guess
- **Live devices** on the current `/24`
- **Open ports** with service names
- **Server banners / page titles** when a web service answers

## Install on your phone

See **[INSTALL.md](./INSTALL.md)** — Expo Go (fast) or EAS APK (own install).

```bash
cd SpotLan
npm install
npm run phone
```

## Notes

- SpotLan only probes the LAN you are connected to.
- Discovery is strongest for devices that expose HTTP(S) / web UIs.
- Use only on networks you own or have permission to inspect.
