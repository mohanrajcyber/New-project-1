import * as Network from 'expo-network';
import * as Location from 'expo-location';
import NetInfo from '@react-native-community/netinfo';
import type { NetworkSnapshot } from '../types';

function subnetPrefixFromIp(ip: string | null): string | null {
  if (!ip) return null;
  const parts = ip.split('.');
  if (parts.length !== 4) return null;
  return `${parts[0]}.${parts[1]}.${parts[2]}`;
}

function gatewayGuessFromIp(ip: string | null): string | null {
  const prefix = subnetPrefixFromIp(ip);
  return prefix ? `${prefix}.1` : null;
}

export async function ensureLocationForWifi(): Promise<boolean> {
  const current = await Location.getForegroundPermissionsAsync();
  if (current.granted) return true;
  const asked = await Location.requestForegroundPermissionsAsync();
  return asked.granted;
}

export async function readNetworkSnapshot(): Promise<NetworkSnapshot> {
  await ensureLocationForWifi();

  const [ipAddress, netState, netInfo] = await Promise.all([
    Network.getIpAddressAsync().catch(() => null),
    Network.getNetworkStateAsync().catch(() => null),
    NetInfo.fetch().catch(() => null),
  ]);

  const details = netInfo?.details as
    | { ssid?: string | null; ipAddress?: string | null; subnet?: string | null }
    | undefined;

  const resolvedIp = ipAddress && ipAddress !== '0.0.0.0' ? ipAddress : details?.ipAddress ?? null;
  const type = netInfo?.type ?? (netState?.type ? String(netState.type) : 'unknown');
  const isWifi = type === 'wifi' || netState?.type === Network.NetworkStateType.WIFI;
  const isConnected = Boolean(netInfo?.isConnected ?? netState?.isConnected);

  return {
    ssid: details?.ssid ?? null,
    ipAddress: resolvedIp,
    subnetPrefix: subnetPrefixFromIp(resolvedIp),
    gatewayGuess: gatewayGuessFromIp(resolvedIp),
    connectionType: type,
    isWifi,
    isConnected,
  };
}
