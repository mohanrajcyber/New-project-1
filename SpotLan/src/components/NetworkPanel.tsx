import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors, space } from '../theme';
import type { NetworkSnapshot } from '../types';

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

export function NetworkPanel({ network, loading }: Props) {
  if (loading || !network) {
    return (
      <View style={styles.panel}>
        <Text style={styles.kicker}>This place</Text>
        <Text style={styles.title}>Reading network…</Text>
      </View>
    );
  }

  const ssid = network.ssid?.trim() || (network.isWifi ? 'Hidden / unavailable' : 'Not on Wi‑Fi');
  const ip = network.ipAddress ?? '—';
  const subnet = network.subnetPrefix ? `${network.subnetPrefix}.0/24` : '—';
  const gateway = network.gatewayGuess ?? '—';

  return (
    <View style={styles.panel}>
      <Text style={styles.kicker}>This place</Text>
      <Text style={styles.title} numberOfLines={1}>
        {ssid}
      </Text>
      <Text style={styles.sub}>
        {network.isConnected ? 'Connected' : 'Offline'} · {network.connectionType}
      </Text>
      <View style={styles.divider} />
      <Row label="Your IP" value={ip} mono />
      <Row label="Subnet" value={subnet} mono />
      <Row label="Gateway" value={gateway} mono />
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    backgroundColor: colors.surface,
    borderRadius: 20,
    padding: space.lg,
    borderWidth: 1,
    borderColor: colors.line,
  },
  kicker: {
    fontFamily: 'DMSans_500Medium',
    fontSize: 12,
    letterSpacing: 1.4,
    textTransform: 'uppercase',
    color: colors.accentDeep,
    marginBottom: 6,
  },
  title: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 28,
    lineHeight: 32,
    color: colors.ink,
  },
  sub: {
    marginTop: 6,
    fontFamily: 'DMSans_400Regular',
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
    paddingVertical: 6,
    gap: 12,
  },
  label: {
    fontFamily: 'DMSans_400Regular',
    fontSize: 14,
    color: colors.inkMuted,
  },
  value: {
    flexShrink: 1,
    fontFamily: 'DMSans_500Medium',
    fontSize: 14,
    color: colors.ink,
    textAlign: 'right',
  },
  mono: {
    fontFamily: 'IBMPlexMono_500Medium',
    fontSize: 13,
  },
});
