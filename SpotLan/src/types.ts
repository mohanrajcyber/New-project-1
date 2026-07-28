export type OpenPort = {
  port: number;
  service: string;
  banner?: string;
};

export type DiscoveredHost = {
  ip: string;
  hostname: string;
  isGateway: boolean;
  openPorts: OpenPort[];
  latencyMs?: number;
};

export type NetworkSnapshot = {
  ssid: string | null;
  ipAddress: string | null;
  subnetPrefix: string | null;
  gatewayGuess: string | null;
  connectionType: string;
  isWifi: boolean;
  isConnected: boolean;
};

export type ScanProgress = {
  checked: number;
  total: number;
  found: number;
  currentIp?: string;
};
