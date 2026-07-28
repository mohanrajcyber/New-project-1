import React, { useEffect, useState } from 'react';
import { StyleProp, TextStyle, ViewStyle } from 'react-native';
import Animated, { Easing, FadeInDown, FadeInUp } from 'react-native-reanimated';

type FadeProps = {
  children: React.ReactNode;
  delay?: number;
  style?: StyleProp<ViewStyle>;
  from?: 'up' | 'down';
};

export function FadeIn({ children, delay = 0, style, from = 'up' }: FadeProps) {
  const entering = from === 'up' ? FadeInUp : FadeInDown;
  return (
    <Animated.View
      entering={entering.delay(delay).duration(650).easing(Easing.out(Easing.cubic))}
      style={style}
    >
      {children}
    </Animated.View>
  );
}

type MotionWordProps = {
  text: string;
  style?: StyleProp<TextStyle>;
  delay?: number;
  stagger?: number;
};

/** Word-by-word rise — website hero motion text. */
export function MotionWords({ text, style, delay = 0, stagger = 70 }: MotionWordProps) {
  const words = text.split(' ');
  return (
    <Animated.View style={{ flexDirection: 'row', flexWrap: 'wrap' }}>
      {words.map((word, i) => (
        <Animated.Text
          key={`${word}-${i}`}
          entering={FadeInUp.delay(delay + i * stagger)
            .duration(520)
            .easing(Easing.out(Easing.cubic))}
          style={style}
        >
          {word}
          {i < words.length - 1 ? ' ' : ''}
        </Animated.Text>
      ))}
    </Animated.View>
  );
}

type TypeLineProps = {
  text: string;
  style?: StyleProp<TextStyle>;
  active?: boolean;
  charMs?: number;
};

/** Typewriter status line for scan / live feedback. */
export function TypeLine({ text, style, active = true, charMs = 28 }: TypeLineProps) {
  const [shown, setShown] = useState(active ? '' : text);

  useEffect(() => {
    if (!active) {
      setShown(text);
      return;
    }
    setShown('');
    let i = 0;
    const id = setInterval(() => {
      i += 1;
      setShown(text.slice(0, i));
      if (i >= text.length) clearInterval(id);
    }, charMs);
    return () => clearInterval(id);
  }, [text, active, charMs]);

  return (
    <Animated.Text style={style}>
      {shown}
      {active && shown.length < text.length ? '|' : ''}
    </Animated.Text>
  );
}
