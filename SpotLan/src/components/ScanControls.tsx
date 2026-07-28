import React from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, space } from '../theme';
import type { ScanProgress } from '../types';

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

  return (
    <View style={styles.wrap}>
      <Pressable
        accessibilityRole="button"
        onPress={scanning ? onStop : onScan}
        disabled={!scanning && disabled}
        style={({ pressed }) => [
          styles.button,
          scanning && styles.buttonStop,
          pressed && { opacity: 0.88 },
          disabled && !scanning && styles.buttonDisabled,
        ]}
      >
        {scanning ? <ActivityIndicator color="#fff" style={{ marginRight: 10 }} /> : null}
        <Text style={styles.buttonText}>{scanning ? 'Stop scan' : 'Scan this place'}</Text>
      </Pressable>

      {scanning && progress ? (
        <View style={styles.progressBlock}>
          <View style={styles.track}>
            <View style={[styles.fill, { width: `${percent}%` }]} />
          </View>
          <Text style={styles.progressText}>
            {progress.checked}/{progress.total} hosts · {progress.found} found
            {progress.currentIp ? ` · ${progress.currentIp}` : ''}
          </Text>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: space.sm,
  },
  button: {
    minHeight: 54,
    borderRadius: 16,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    paddingHorizontal: space.lg,
  },
  buttonStop: {
    backgroundColor: colors.warn,
  },
  buttonDisabled: {
    opacity: 0.45,
  },
  buttonText: {
    fontFamily: 'DMSans_700Bold',
    fontSize: 17,
    color: '#fff',
  },
  progressBlock: {
    gap: 8,
  },
  track: {
    height: 6,
    borderRadius: 4,
    backgroundColor: 'rgba(15,122,110,0.15)',
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    backgroundColor: colors.accent,
    borderRadius: 4,
  },
  progressText: {
    fontFamily: 'IBMPlexMono_400Regular',
    fontSize: 12,
    color: colors.inkMuted,
  },
});
