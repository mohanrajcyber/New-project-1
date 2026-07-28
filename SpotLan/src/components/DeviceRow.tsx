import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, { FadeInRight } from 'react-native-reanimated';
import { colors, space } from '../theme';
import type { DiscoveredHost } from '../types';

type Props = {
  host: DiscoveredHost;
  index: number;
};

export function DeviceRow({ host, index }: Props) {
  return (
    <Animated.View
      entering={FadeInRight.delay(Math.min(index * 80, 480))
        .duration(520)
        .springify()
        .damping(18)}
      style={styles.wrap}
    >
      <View style={styles.accentBar} />
      <View style={styles.body}>
        <View style={styles.top}>
          <View style={{ flex: 1 }}>
            <Text style={styles.name} numberOfLines={1}>
              {host.hostname}
            </Text>
            <Text style={styles.ip}>{host.ip}</Text>
          </View>
          {host.isGateway ? (
            <View style={styles.badge}>
              <Text style={styles.badgeText}>Gateway</Text>
            </View>
          ) : (
            <View style={[styles.badge, styles.badgeLive]}>
              <View style={styles.liveDot} />
              <Text style={[styles.badgeText, styles.badgeLiveText]}>Live</Text>
            </View>
          )}
        </View>

        <View style={styles.ports}>
          {host.openPorts.map((port) => (
            <Pressable key={`${host.ip}-${port.port}`} style={styles.portChip}>
              <Text style={styles.portNum}>{port.port}</Text>
              <Text style={styles.portSvc}>{port.service}</Text>
              {port.banner ? (
                <Text style={styles.portBanner} numberOfLines={1}>
                  {port.banner}
                </Text>
              ) : null}
            </Pressable>
          ))}
        </View>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: colors.surfaceSolid,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.line,
    marginBottom: space.sm,
    overflow: 'hidden',
    flexDirection: 'row',
  },
  accentBar: {
    width: 4,
    backgroundColor: colors.accent,
  },
  body: {
    flex: 1,
    padding: space.md,
  },
  top: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    marginBottom: 12,
  },
  name: {
    fontFamily: 'Syne_700Bold',
    fontSize: 18,
    color: colors.ink,
    letterSpacing: -0.3,
  },
  ip: {
    marginTop: 3,
    fontFamily: 'IBMPlexMono_400Regular',
    fontSize: 13,
    color: colors.inkMuted,
  },
  badge: {
    backgroundColor: colors.accentSoft,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 9,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  badgeLive: {
    backgroundColor: '#E4F6EB',
  },
  liveDot: {
    width: 6,
    height: 6,
    borderRadius: 4,
    backgroundColor: colors.live,
  },
  badgeText: {
    fontFamily: 'SpaceGrotesk_500Medium',
    fontSize: 12,
    color: colors.accentDeep,
  },
  badgeLiveText: {
    color: colors.live,
  },
  ports: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  portChip: {
    backgroundColor: colors.portBg,
    borderRadius: 12,
    paddingHorizontal: 11,
    paddingVertical: 9,
    maxWidth: '100%',
  },
  portNum: {
    fontFamily: 'IBMPlexMono_500Medium',
    fontSize: 13,
    color: colors.ink,
  },
  portSvc: {
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 12,
    color: colors.inkMuted,
    marginTop: 1,
  },
  portBanner: {
    fontFamily: 'IBMPlexMono_400Regular',
    fontSize: 11,
    color: colors.inkFaint,
    marginTop: 3,
    maxWidth: 180,
  },
});
