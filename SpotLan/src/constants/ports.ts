/** Common LAN service ports people care about in a new place. */
export const COMMON_PORTS: { port: number; service: string }[] = [
  { port: 80, service: 'HTTP' },
  { port: 443, service: 'HTTPS' },
  { port: 8080, service: 'HTTP-Alt' },
  { port: 8443, service: 'HTTPS-Alt' },
  { port: 8000, service: 'Dev-HTTP' },
  { port: 3000, service: 'Node/Dev' },
  { port: 5000, service: 'App-HTTP' },
  { port: 8888, service: 'Alt-HTTP' },
  { port: 631, service: 'IPP/Print' },
  { port: 9100, service: 'Raw-Print' },
  { port: 548, service: 'AFP' },
  { port: 445, service: 'SMB' },
  { port: 139, service: 'NetBIOS' },
  { port: 22, service: 'SSH' },
  { port: 21, service: 'FTP' },
  { port: 23, service: 'Telnet' },
  { port: 53, service: 'DNS' },
  { port: 1883, service: 'MQTT' },
  { port: 5900, service: 'VNC' },
  { port: 3389, service: 'RDP' },
  { port: 554, service: 'RTSP' },
  { port: 8554, service: 'RTSP-Alt' },
];

/** Ports we can reliably probe from Expo (HTTP-style). */
export const HTTP_PROBE_PORTS = new Set([80, 443, 8080, 8443, 8000, 3000, 5000, 8888, 631]);
