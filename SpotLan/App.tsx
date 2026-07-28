import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  View,
  RefreshControl,
  Platform,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  useFonts,
  Syne_700Bold,
  Syne_800ExtraBold,
} from '@expo-google-fonts/syne';
import {
  SpaceGrotesk_400Regular,
  SpaceGrotesk_500Medium,
} from '@expo-google-fonts/space-grotesk';
import {
  IBMPlexMono_400Regular,
  IBMPlexMono_500Medium,
} from '@expo-google-fonts/ibm-plex-mono';

import { Atmosphere } from './src/components/Atmosphere';
import { Hero } from './src/components/Hero';
import { NetworkPanel } from './src/components/NetworkPanel';
import { ScanControls } from './src/components/ScanControls';
import { DeviceRow } from './src/components/DeviceRow';
import { FadeIn, MotionWords } from './src/components/motion';
import { colors, space } from './src/theme';
import type { DiscoveredHost, NetworkSnapshot, ScanProgress } from './src/types';
import { readNetworkSnapshot } from './src/utils/network';
import { scanSubnet } from './src/utils/scanner';

export default function App() {
  const [fontsLoaded] = useFonts({
    Syne_700Bold,
    Syne_800ExtraBold,
    SpaceGrotesk_400Regular,
    SpaceGrotesk_500Medium,
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
        onHost: (host) =>
          setHosts((prev) => {
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
      <Atmosphere />
      <StatusBar style="dark" />
      <SafeAreaView style={styles.safe} edges={['top', 'left', 'right']}>
        <ScrollView
          contentContainerStyle={styles.content}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl refreshing={loadingNetwork && !scanning} onRefresh={refreshNetwork} />
          }
        >
          <Hero scanning={scanning} />

          <NetworkPanel network={network} loading={loadingNetwork} />

          <View style={{ height: space.lg }} />

          <ScanControls
            scanning={scanning}
            progress={progress}
            disabled={!canScan}
            onScan={startScan}
            onStop={stopScan}
          />

          {error ? (
            <FadeIn>
              <Text style={styles.error}>{error}</Text>
            </FadeIn>
          ) : null}

          {!canScan && !loadingNetwork ? (
            <FadeIn delay={100}>
              <Text style={styles.hint}>
                Wi‑Fi / LAN connection தேவை. Phone-ஐ network-ஓட connect பண்ணி pull-to-refresh
                பண்ணு.
              </Text>
            </FadeIn>
          ) : null}

          <View style={styles.resultsHeader}>
            <MotionWords text="Devices found" style={styles.resultsTitle} delay={0} stagger={40} />
            <Text style={styles.resultsCount}>{String(hosts.length).padStart(2, '0')}</Text>
          </View>

          {hosts.length === 0 && !scanning ? (
            <FadeIn delay={80}>
              <View style={styles.empty}>
                <Text style={styles.emptyTitle}>Inga innum onnum illa</Text>
                <Text style={styles.emptyBody}>
                  Scan this place — router, printers, cameras, NAS, web UIs with open ports show up
                  with motion as they answer.
                </Text>
              </View>
            </FadeIn>
          ) : (
            hosts.map((host, index) => <DeviceRow key={host.ip} host={host} index={index} />)
          )}

          <Text style={styles.footnote}>
            SpotLan probes your current LAN only. Use it on networks you own or have permission to
            inspect.{' '}
            {Platform.OS === 'ios'
              ? 'SSID needs location permission on iOS.'
              : 'SSID needs location permission on Android.'}
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
    paddingTop: space.md,
    paddingBottom: 56,
  },
  error: {
    marginTop: space.sm,
    fontFamily: 'SpaceGrotesk_500Medium',
    color: colors.warn,
    fontSize: 14,
  },
  hint: {
    marginTop: space.sm,
    fontFamily: 'SpaceGrotesk_400Regular',
    color: colors.inkMuted,
    fontSize: 14,
    lineHeight: 21,
  },
  resultsHeader: {
    marginTop: space.xxl,
    marginBottom: space.md,
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    gap: 12,
  },
  resultsTitle: {
    fontFamily: 'Syne_700Bold',
    fontSize: 26,
    color: colors.ink,
    letterSpacing: -0.5,
  },
  resultsCount: {
    fontFamily: 'IBMPlexMono_500Medium',
    fontSize: 18,
    color: colors.accentDeep,
  },
  empty: {
    paddingVertical: space.md,
  },
  emptyTitle: {
    fontFamily: 'Syne_700Bold',
    fontSize: 17,
    color: colors.ink,
    marginBottom: 6,
  },
  emptyBody: {
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 14,
    lineHeight: 22,
    color: colors.inkMuted,
  },
  footnote: {
    marginTop: space.xl,
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 12,
    lineHeight: 18,
    color: colors.inkFaint,
  },
});
