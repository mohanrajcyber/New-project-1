import React, { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, {
  Easing,
  interpolate,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { colors } from '../theme';

type Props = {
  active: boolean;
  size?: number;
};

export function ScanRadar({ active, size = 148 }: Props) {
  const pulse = useSharedValue(0);
  const sweep = useSharedValue(0);
  const idle = useSharedValue(0);

  useEffect(() => {
    idle.value = withRepeat(
      withTiming(1, { duration: 3200, easing: Easing.inOut(Easing.sin) }),
      -1,
      true,
    );
  }, [idle]);

  useEffect(() => {
    if (!active) {
      pulse.value = withTiming(0, { duration: 300 });
      return;
    }
    pulse.value = withRepeat(
      withTiming(1, { duration: 1500, easing: Easing.out(Easing.quad) }),
      -1,
      false,
    );
    sweep.value = withRepeat(
      withTiming(1, { duration: 2400, easing: Easing.linear }),
      -1,
      false,
    );
  }, [active, pulse, sweep]);

  const pulseStyle = useAnimatedStyle(() => ({
    opacity: active ? interpolate(pulse.value, [0, 1], [0.5, 0]) : 0.12,
    transform: [{ scale: interpolate(pulse.value, [0, 1], [0.45, 1.2]) }],
  }));

  const sweepStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: `${sweep.value * 360}deg` }],
    opacity: active ? 1 : 0,
  }));

  const coreStyle = useAnimatedStyle(() => ({
    transform: [{ scale: 1 + idle.value * 0.08 }],
  }));

  return (
    <View style={[styles.wrap, { width: size, height: size }]}>
      <View style={[styles.ring, { width: size * 0.95, height: size * 0.95, borderRadius: size }]} />
      <View style={[styles.ring, { width: size * 0.7, height: size * 0.7, borderRadius: size }]} />
      <View style={[styles.ringSoft, { width: size * 0.42, height: size * 0.42, borderRadius: size }]} />
      <Animated.View
        style={[
          styles.pulse,
          { width: size, height: size, borderRadius: size },
          pulseStyle,
        ]}
      />
      <Animated.View style={[styles.sweepBox, { width: size, height: size }, sweepStyle]}>
        <View style={[styles.sweepArm, { width: size * 0.48 }]} />
      </Animated.View>
      <Animated.View style={[styles.core, coreStyle]} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  ring: {
    position: 'absolute',
    borderWidth: 1.5,
    borderColor: 'rgba(12,110,99,0.2)',
  },
  ringSoft: {
    position: 'absolute',
    backgroundColor: 'rgba(12,110,99,0.08)',
  },
  pulse: {
    position: 'absolute',
    backgroundColor: 'rgba(12,110,99,0.2)',
  },
  sweepBox: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  sweepArm: {
    position: 'absolute',
    left: '50%',
    height: 2,
    backgroundColor: 'rgba(12,110,99,0.45)',
    borderRadius: 2,
  },
  core: {
    width: 16,
    height: 16,
    borderRadius: 10,
    backgroundColor: colors.accent,
  },
});
