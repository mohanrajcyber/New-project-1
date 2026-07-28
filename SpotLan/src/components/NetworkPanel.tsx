import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { BlurView } from 'expo-blur';
import { Platform } from 'react-native';
import { colors, space } from '../theme';
import type { NetworkSnapshot } from '../types';
import { FadeIn, TypeLine } from './motion';

type Props = {
  network: NetworkSnapshot | null;
  loading?: boolean;
};

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <View style={styles.row}>
      <Text style={styles.label}>{label}</Text>
      <Text style={[styles.value, mono && styles.mono]} numberOfLines={1}>
        {value}
      </Text>
    </View>
  );
}

function PanelShell({ children }: { children: React.ReactNode }) {
  if (Platform.OS === 'web') {
    return <View style={[styles.panel, styles.panelFallback]}>{children}</View>;
  }
  return (
    <BlurView intensity={28} tint="light" style={styles.panel}>
      {children}
    </BlurView>
  );
}

export function NetworkPanel({ network, loading }: Props) {
  if (loading || !network) {
    return (
      <FadeIn delay={280}>
        <PanelShell>
          <Text style={styles.kicker}>This place</Text>
          <TypeLine text="Reading your network…" style={styles.title} />
        </PanelShell>
      </FadeIn>
    );
  }

  const ssid = network.ssid?.trim() || (network.isWifi ? 'Hidden / unavailable' : 'Not on Wi‑Fi');
  const ip = network.ipAddress ?? '—';
  const subnet = network.subnetPrefix ? `${network.subnetPrefix}.0/24` : '—';
  const gateway = network.gatewayGuess ?? '—';

  return (
    <FadeIn delay={280}>
      <PanelShell>
        <Text style={styles.kicker}>This place</Text>
        <TypeLine key={ssid} text={ssid} style={styles.title} charMs={22} />
        <Text style={styles.sub}>
          {network.isConnected ? 'Connected' : 'Offline'} · {network.connectionType}
        </Text>
        <View style={styles.divider} />
        <Row label="Your IP" value={ip} mono />
        <Row label="Subnet" value={subnet} mono />
        <Row label="Gateway" value={gateway} mono />
      </PanelShell>
    </FadeIn>
  );
}

const styles = StyleSheet.create({
  panel: {
    borderRadius: 24,
    padding: space.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.surface,
  },
  panelFallback: {
    backgroundColor: colors.surfaceStrong,
  },
  kicker: {
    fontFamily: 'SpaceGrotesk_500Medium',
    fontSize: 12,
    letterSpacing: 2,
    textTransform: 'uppercase',
    color: colors.accentDeep,
    marginBottom: 8,
  },
  title: {
    fontFamily: 'Syne_700Bold',
    fontSize: 30,
    lineHeight: 34,
    color: colors.ink,
    letterSpacing: -0.5,
  },
  sub: {
    marginTop: 8,
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 14,
    color: colors.inkMuted,
  },
  divider: {
    height: 1,
    backgroundColor: colors.line,
    marginVertical: space.md,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 7,
    gap: 12,
  },
  label: {
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 14,
    color: colors.inkMuted,
  },
  value: {
    flexShrink: 1,
    fontFamily: 'SpaceGrotesk_500Medium',
    fontSize: 14,
    color: colors.ink,
    textAlign: 'right',
  },
  mono: {
    fontFamily: 'IBMPlexMono_500Medium',
    fontSize: 13,
  },
});
