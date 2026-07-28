import React, { useEffect, useRef } from 'react';
import { Animated, Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, space } from '../theme';
import type { DiscoveredHost } from '../types';

type Props = {
  host: DiscoveredHost;
  index: number;
};

export function DeviceRow({ host, index }: Props) {
  const enter = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(enter, {
      toValue: 1,
      duration: 420,
      delay: Math.min(index * 70, 420),
      useNativeDriver: true,
    }).start();
  }, [enter, index]);

  return (
    <Animated.View
      style={[
        styles.wrap,
        {
          opacity: enter,
          transform: [
            {
              translateY: enter.interpolate({ inputRange: [0, 1], outputRange: [14, 0] }),
            },
          ],
        },
      ]}
    >
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
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: colors.surfaceSolid,
    borderRadius: 18,
    padding: space.md,
    borderWidth: 1,
    borderColor: colors.line,
    marginBottom: space.sm,
  },
  top: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    marginBottom: 12,
  },
  name: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 17,
    color: colors.ink,
  },
  ip: {
    marginTop: 2,
    fontFamily: 'IBMPlexMono_400Regular',
    fontSize: 13,
    color: colors.inkMuted,
  },
  badge: {
    backgroundColor: colors.accentSoft,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  badgeLive: {
    backgroundColor: '#E5F6EC',
  },
  badgeText: {
    fontFamily: 'DMSans_500Medium',
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
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 8,
    maxWidth: '100%',
  },
  portNum: {
    fontFamily: 'IBMPlexMono_500Medium',
    fontSize: 13,
    color: colors.ink,
  },
  portSvc: {
    fontFamily: 'DMSans_400Regular',
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
