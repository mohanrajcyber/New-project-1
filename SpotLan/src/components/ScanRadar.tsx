import React, { useEffect, useRef } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';
import { colors } from '../theme';

type Props = {
  active: boolean;
  size?: number;
};

export function ScanRadar({ active, size = 120 }: Props) {
  const pulse = useRef(new Animated.Value(0)).current;
  const sweep = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!active) {
      pulse.setValue(0);
      sweep.setValue(0);
      return;
    }

    const pulseLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          toValue: 1,
          duration: 1600,
          easing: Easing.out(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulse, { toValue: 0, duration: 0, useNativeDriver: true }),
      ]),
    );

    const sweepLoop = Animated.loop(
      Animated.timing(sweep, {
        toValue: 1,
        duration: 2200,
        easing: Easing.linear,
        useNativeDriver: true,
      }),
    );

    pulseLoop.start();
    sweepLoop.start();
    return () => {
      pulseLoop.stop();
      sweepLoop.stop();
    };
  }, [active, pulse, sweep]);

  const scale = pulse.interpolate({ inputRange: [0, 1], outputRange: [0.55, 1.15] });
  const opacity = pulse.interpolate({ inputRange: [0, 1], outputRange: [0.45, 0] });
  const rotate = sweep.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '360deg'] });

  return (
    <View style={[styles.wrap, { width: size, height: size }]}>
      <View style={[styles.ring, { width: size * 0.92, height: size * 0.92, borderRadius: size }]} />
      <View style={[styles.ring, { width: size * 0.64, height: size * 0.64, borderRadius: size }]} />
      <Animated.View
        style={[
          styles.pulse,
          {
            width: size,
            height: size,
            borderRadius: size,
            opacity,
            transform: [{ scale }],
          },
        ]}
      />
      {active ? (
        <Animated.View
          style={[
            styles.sweepBox,
            { width: size, height: size, transform: [{ rotate }] },
          ]}
        >
          <View style={[styles.sweepArm, { width: size / 2, height: 2 }]} />
        </Animated.View>
      ) : null}
      <View style={styles.core} />
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
    borderWidth: 1,
    borderColor: 'rgba(15,122,110,0.22)',
  },
  pulse: {
    position: 'absolute',
    backgroundColor: 'rgba(15,122,110,0.16)',
  },
  sweepBox: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  sweepArm: {
    position: 'absolute',
    left: '50%',
    backgroundColor: 'rgba(15,122,110,0.35)',
    borderRadius: 2,
  },
  core: {
    width: 14,
    height: 14,
    borderRadius: 8,
    backgroundColor: colors.accent,
  },
});
