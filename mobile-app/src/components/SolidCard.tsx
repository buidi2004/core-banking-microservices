import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { Colors, Radius, Shadows } from '../theme';

interface SolidCardProps {
  children: React.ReactNode;
  style?: ViewStyle;
}

export const SolidCard: React.FC<SolidCardProps> = ({ children, style }) => (
  <View style={[styles.container, style]}>{children}</View>
);

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    ...Shadows.card,
  },
});
