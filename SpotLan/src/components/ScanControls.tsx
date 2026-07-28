import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import * as Haptics from 'expo-haptics';
import { colors, space } from '../theme';
import type { ScanProgress } from '../types';
import { FadeIn, TypeLine } from './motion';

type Props = {
  scanning: boolean;
  progress: ScanProgress | null;
  disabled?: boolean;
  onScan: () => void;
  onStop: () => void;
};

export function ScanControls({ scanning, progress, disabled, onScan, onStop }: Props) {
  const percent =
    progress && progress.total > 0 ? Math.round((progress.checked / progress.total) * 100) : 0;

  const handlePress = async () => {
    try {
      await Haptics.impactAsync(
        scanning ? Haptics.ImpactFeedbackStyle.Medium : Haptics.ImpactFeedbackStyle.Light,
      );
    } catch {
      // haptics optional
    }
    if (scanning) onStop();
    else onScan();
  };

  return (
    <FadeIn delay={360}>
      <View style={styles.wrap}>
        <Pressable
          accessibilityRole="button"
          onPress={handlePress}
          disabled={!scanning && disabled}
          style={({ pressed }) => [
            styles.button,
            scanning && styles.buttonStop,
            pressed && { transform: [{ scale: 0.985 }] },
            disabled && !scanning && styles.buttonDisabled,
          ]}
        >
          <Text style={styles.buttonText}>{scanning ? 'Stop scan' : 'Scan this place'}</Text>
          <Text style={styles.buttonSub}>
            {scanning ? 'Tap to cancel' : 'Hosts · ports · banners'}
          </Text>
        </Pressable>

        {scanning && progress ? (
          <View style={styles.progressBlock}>
            <View style={styles.track}>
              <View style={[styles.fill, { width: `${percent}%` }]} />
            </View>
            <TypeLine
              key={`${progress.checked}-${progress.found}`}
              text={`${progress.checked}/${progress.total} hosts · ${progress.found} found${
                progress.currentIp ? ` · ${progress.currentIp}` : ''
              }`}
              style={styles.progressText}
              charMs={8}
              active={false}
            />
          </View>
        ) : null}
      </View>
    </FadeIn>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: space.md,
  },
  button: {
    minHeight: 72,
    borderRadius: 20,
    backgroundColor: colors.accent,
    justifyContent: 'center',
    paddingHorizontal: space.lg,
    paddingVertical: 14,
  },
  buttonStop: {
    backgroundColor: colors.warn,
  },
  buttonDisabled: {
    opacity: 0.42,
  },
  buttonText: {
    fontFamily: 'Syne_700Bold',
    fontSize: 20,
    color: '#fff',
    letterSpacing: -0.3,
  },
  buttonSub: {
    marginTop: 2,
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 13,
    color: 'rgba(255,255,255,0.78)',
  },
  progressBlock: {
    gap: 10,
  },
  track: {
    height: 7,
    borderRadius: 6,
    backgroundColor: 'rgba(12,110,99,0.14)',
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    backgroundColor: colors.accent,
    borderRadius: 6,
  },
  progressText: {
    fontFamily: 'IBMPlexMono_400Regular',
    fontSize: 12,
    color: colors.inkMuted,
  },
});
