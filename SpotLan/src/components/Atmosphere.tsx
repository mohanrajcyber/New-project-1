import React, { useEffect } from 'react';
import { Dimensions, StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { colors } from '../theme';

const { width, height } = Dimensions.get('window');

function Orb({
  size,
  color,
  x,
  y,
  duration,
  drift,
}: {
  size: number;
  color: string;
  x: number;
  y: number;
  duration: number;
  drift: number;
}) {
  const t = useSharedValue(0);

  useEffect(() => {
    t.value = withRepeat(
      withTiming(1, { duration, easing: Easing.inOut(Easing.sin) }),
      -1,
      true,
    );
  }, [duration, t]);

  const style = useAnimatedStyle(() => ({
    transform: [
      { translateY: t.value * drift },
      { translateX: t.value * drift * 0.35 },
      { scale: 1 + t.value * 0.08 },
    ],
  }));

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        {
          position: 'absolute',
          left: x,
          top: y,
          width: size,
          height: size,
          borderRadius: size,
          backgroundColor: color,
        },
        style,
      ]}
    />
  );
}

export function Atmosphere() {
  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <LinearGradient
        colors={[colors.bgTop, colors.bgMid, colors.bgBottom]}
        locations={[0, 0.42, 1]}
        style={StyleSheet.absoluteFill}
      />
      <LinearGradient
        colors={['rgba(255,255,255,0.35)', 'transparent', 'rgba(12,110,99,0.06)']}
        locations={[0, 0.4, 1]}
        style={StyleSheet.absoluteFill}
      />
      <Orb size={220} color={colors.orbTeal} x={-60} y={80} duration={7000} drift={28} />
      <Orb size={180} color={colors.orbBlue} x={width - 120} y={160} duration={8200} drift={36} />
      <Orb size={260} color={colors.orbMint} x={width * 0.2} y={height * 0.55} duration={9600} drift={22} />
    </View>
  );
}
