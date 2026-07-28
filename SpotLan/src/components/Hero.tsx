import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { colors, space } from '../theme';
import { FadeIn, MotionWords, TypeLine } from './motion';
import { ScanRadar } from './ScanRadar';

const HEADLINES = [
  'See the network at this place',
  'Wi‑Fi, hosts, ports — one scan',
  'New room. New LAN. Clear map.',
];

type Props = {
  scanning: boolean;
};

export function Hero({ scanning }: Props) {
  const [headlineIndex, setHeadlineIndex] = useState(0);

  useEffect(() => {
    if (scanning) return;
    const id = setInterval(() => {
      setHeadlineIndex((i) => (i + 1) % HEADLINES.length);
    }, 4200);
    return () => clearInterval(id);
  }, [scanning]);

  const headline = scanning ? 'Scanning every corner of this LAN' : HEADLINES[headlineIndex];

  return (
    <View style={styles.hero}>
      <FadeIn>
        <Text style={styles.brand}>SpotLan</Text>
      </FadeIn>

      <View style={styles.headlineWrap}>
        <MotionWords
          key={headline}
          text={headline}
          style={styles.headline}
          delay={120}
          stagger={55}
        />
      </View>

      <FadeIn delay={420}>
        <TypeLine
          text="Arrive somewhere new. Tap scan. Watch devices, servers & open ports appear."
          style={styles.support}
          charMs={16}
        />
      </FadeIn>

      <FadeIn delay={520} style={styles.radarBlock}>
        <ScanRadar active={scanning} size={160} />
        <View style={styles.radarCopy}>
          <Text style={styles.radarTitle}>{scanning ? 'Live sweep' : 'Ready'}</Text>
          <Text style={styles.radarSub}>
            {scanning
              ? 'Probing hosts & reading banners as they answer.'
              : 'Atmospheric, website-grade UI — built for your phone.'}
          </Text>
        </View>
      </FadeIn>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: {
    paddingTop: space.sm,
    marginBottom: space.lg,
  },
  brand: {
    fontFamily: 'Syne_800ExtraBold',
    fontSize: 52,
    lineHeight: 54,
    color: colors.ink,
    letterSpacing: -2,
  },
  headlineWrap: {
    marginTop: space.md,
    minHeight: 72,
  },
  headline: {
    fontFamily: 'Syne_700Bold',
    fontSize: 28,
    lineHeight: 34,
    color: colors.ink,
    letterSpacing: -0.6,
  },
  support: {
    marginTop: space.sm,
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 16,
    lineHeight: 24,
    color: colors.inkMuted,
    maxWidth: 360,
  },
  radarBlock: {
    marginTop: space.xl,
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
  },
  radarCopy: {
    flex: 1,
  },
  radarTitle: {
    fontFamily: 'Syne_700Bold',
    fontSize: 18,
    color: colors.ink,
    marginBottom: 4,
  },
  radarSub: {
    fontFamily: 'SpaceGrotesk_400Regular',
    fontSize: 13,
    lineHeight: 19,
    color: colors.inkMuted,
  },
});
