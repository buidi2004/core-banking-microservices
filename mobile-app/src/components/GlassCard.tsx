import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { BlurView } from 'expo-blur';
import { Colors, Radius, Shadows } from '../theme';

interface GlassCardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  intensity?: number;
  tint?: 'light' | 'dark' | 'regular';
}

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  style,
  intensity = 70,
  tint = 'light',
}) => (
  <BlurView
    intensity={intensity}
    tint={tint}
    style={[styles.container, style]}
  >
    <View style={styles.inner}>{children}</View>
  </BlurView>
);

const styles = StyleSheet.create({
  container: {
    borderRadius: Radius.lg,
    overflow: 'hidden',
    ...Shadows.hero,
  },
  inner: {
    flex: 1,
  },
});
