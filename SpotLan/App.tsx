import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
  RefreshControl,
  Platform,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { LinearGradient } from 'expo-linear-gradient';
import {
  useFonts,
  DMSans_400Regular,
  DMSans_500Medium,
  DMSans_700Bold,
} from '@expo-google-fonts/dm-sans';
import {
  IBMPlexMono_400Regular,
  IBMPlexMono_500Medium,
} from '@expo-google-fonts/ibm-plex-mono';

import { NetworkPanel } from './src/components/NetworkPanel';
import { ScanControls } from './src/components/ScanControls';
import { ScanRadar } from './src/components/ScanRadar';
import { DeviceRow } from './src/components/DeviceRow';
import { colors, space } from './src/theme';
import type { DiscoveredHost, NetworkSnapshot, ScanProgress } from './src/types';
import { readNetworkSnapshot } from './src/utils/network';
import { scanSubnet } from './src/utils/scanner';

export default function App() {
  const [fontsLoaded] = useFonts({
    DMSans_400Regular,
    DMSans_500Medium,
    DMSans_700Bold,
    IBMPlexMono_400Regular,
    IBMPlexMono_500Medium,
  });

  const [network, setNetwork] = useState<NetworkSnapshot | null>(null);
  const [loadingNetwork, setLoadingNetwork] = useState(true);
  const [scanning, setScanning] = useState(false);
  const [progress, setProgress] = useState<ScanProgress | null>(null);
  const [hosts, setHosts] = useState<DiscoveredHost[]>([]);
  const [error, setError] = useState<string | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  const refreshNetwork = useCallback(async () => {
    setLoadingNetwork(true);
    setError(null);
    try {
      const snapshot = await readNetworkSnapshot();
      setNetwork(snapshot);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not read network');
    } finally {
      setLoadingNetwork(false);
    }
  }, []);

  useEffect(() => {
    refreshNetwork();
  }, [refreshNetwork]);

  const canScan = useMemo(() => {
    return Boolean(network?.isConnected && network.subnetPrefix);
  }, [network]);

  const stopScan = useCallback(() => {
    abortRef.current?.abort();
    abortRef.current = null;
    setScanning(false);
  }, []);

  const startScan = useCallback(async () => {
    if (!network?.subnetPrefix) return;

    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;

    setScanning(true);
    setHosts([]);
    setProgress({ checked: 0, total: 254, found: 0 });
    setError(null);

    try {
      await scanSubnet({
        subnetPrefix: network.subnetPrefix,
        gatewayIp: network.gatewayGuess,
        selfIp: network.ipAddress,
        signal: controller.signal,
        onProgress: (p) => setProgress({ ...p }),
        onHost: (host) => setHosts((prev) => {
          const without = prev.filter((h) => h.ip !== host.ip);
          return [...without, host].sort((a, b) => {
            const aa = Number(a.ip.split('.')[3]);
            const bb = Number(b.ip.split('.')[3]);
            return aa - bb;
          });
        }),
      });
    } catch (e) {
      if (!controller.signal.aborted) {
        setError(e instanceof Error ? e.message : 'Scan failed');
      }
    } finally {
      if (abortRef.current === controller) {
        abortRef.current = null;
        setScanning(false);
      }
    }
  }, [network]);

  if (!fontsLoaded) {
    return <View style={styles.boot} />;
  }

  return (
    <View style={styles.root}>
      <LinearGradient
        colors={[colors.bgTop, colors.bgMid, colors.bgBottom]}
        locations={[0, 0.45, 1]}
        style={StyleSheet.absoluteFill}
      />
      <StatusBar style="dark" />
      <SafeAreaView style={styles.safe}>
        <ScrollView
          contentContainerStyle={styles.content}
          refreshControl={
            <RefreshControl refreshing={loadingNetwork && !scanning} onRefresh={refreshNetwork} />
          }
        >
          <View style={styles.brandBlock}>
            <Text style={styles.brand}>SpotLan</Text>
            <Text style={styles.tagline}>
              New place-la Wi‑Fi, hosts, servers, open ports — oru scan-la.
            </Text>
          </View>

          <View style={styles.radarRow}>
            <ScanRadar active={scanning} size={108} />
            <View style={styles.radarCopy}>
              <Text style={styles.radarTitle}>
                {scanning ? 'Scanning the LAN…' : 'Ready when you are'}
              </Text>
              <Text style={styles.radarSub}>
                Looks for live devices on your current subnet and reads service banners where
                possible.
              </Text>
            </View>
          </View>

          <NetworkPanel network={network} loading={loadingNetwork} />

          <View style={{ height: space.md }} />

          <ScanControls
            scanning={scanning}
            progress={progress}
            disabled={!canScan}
            onScan={startScan}
            onStop={stopScan}
          />

          {error ? <Text style={styles.error}>{error}</Text> : null}

          {!canScan && !loadingNetwork ? (
            <Text style={styles.hint}>
              Wi‑Fi / LAN connection தேவை. Phone-ஐ network-ஓட connect பண்ணி refresh பண்ணு.
            </Text>
          ) : null}

          <View style={styles.resultsHeader}>
            <Text style={styles.resultsTitle}>Devices</Text>
            <Text style={styles.resultsCount}>{hosts.length}</Text>
          </View>

          {hosts.length === 0 && !scanning ? (
            <View style={styles.empty}>
              <Text style={styles.emptyTitle}>Inga innum onnum illa</Text>
              <Text style={styles.emptyBody}>
                Scan this place — router, printers, cameras, NAS, web UIs with open ports will show
                up here.
              </Text>
            </View>
          ) : (
            hosts.map((host, index) => <DeviceRow key={host.ip} host={host} index={index} />)
          )}

          <Text style={styles.footnote}>
            SpotLan probes your current LAN only. Use it on networks you own or have permission to
            inspect. {Platform.OS === 'ios' ? 'SSID needs location permission on iOS.' : 'SSID needs location permission on Android.'}
          </Text>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.bgBottom,
  },
  boot: {
    flex: 1,
    backgroundColor: colors.bgTop,
  },
  safe: {
    flex: 1,
  },
  content: {
    paddingHorizontal: space.lg,
    paddingTop: space.lg,
    paddingBottom: 48,
  },
  brandBlock: {
    marginBottom: space.lg,
  },
  brand: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 42,
    lineHeight: 46,
    color: colors.ink,
    letterSpacing: -1,
  },
  tagline: {
    marginTop: 8,
    fontFamily: 'DMSans_400Regular',
    fontSize: 16,
    lineHeight: 24,
    color: colors.inkMuted,
    maxWidth: 340,
  },
  radarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
    marginBottom: space.lg,
  },
  radarCopy: {
    flex: 1,
  },
  radarTitle: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 18,
    color: colors.ink,
    marginBottom: 4,
  },
  radarSub: {
    fontFamily: 'DMSans_400Regular',
    fontSize: 13,
    lineHeight: 19,
    color: colors.inkMuted,
  },
  error: {
    marginTop: space.sm,
    fontFamily: 'DMSans_500Medium',
    color: colors.warn,
    fontSize: 14,
  },
  hint: {
    marginTop: space.sm,
    fontFamily: 'DMSans_400Regular',
    color: colors.inkMuted,
    fontSize: 14,
    lineHeight: 20,
  },
  resultsHeader: {
    marginTop: space.xl,
    marginBottom: space.sm,
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
  },
  resultsTitle: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 22,
    color: colors.ink,
  },
  resultsCount: {
    fontFamily: 'IBMPlexMono_500Medium',
    fontSize: 16,
    color: colors.accentDeep,
  },
  empty: {
    paddingVertical: space.lg,
  },
  emptyTitle: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 16,
    color: colors.ink,
    marginBottom: 6,
  },
  emptyBody: {
    fontFamily: 'DMSans_400Regular',
    fontSize: 14,
    lineHeight: 21,
    color: colors.inkMuted,
  },
  footnote: {
    marginTop: space.xl,
    fontFamily: 'DMSans_400Regular',
    fontSize: 12,
    lineHeight: 18,
    color: colors.inkFaint,
  },
});
