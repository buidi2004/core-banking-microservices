import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ViewStyle, TextStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows } from '../theme';
import { Typography } from '../theme';

interface PrimaryButtonProps {
  title: string;
  onPress?: () => void;
  style?: ViewStyle;
  textStyle?: TextStyle;
  disabled?: boolean;
}

export const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  title,
  onPress,
  style,
  textStyle,
  disabled,
}) => (
  <LinearGradient
    colors={[Colors.primary, Colors.heroGradMid]}
    start={{ x: 0, y: 0 }}
    end={{ x: 1, y: 0 }}
    style={[styles.container, disabled ? styles.disabled : null, style]}
    pointerEvents={disabled ? 'none' : 'auto'}
  >
    <Text style={[styles.text, textStyle]}>{title}</Text>
  </LinearGradient>
);

const styles = StyleSheet.create({
  container: {
    borderRadius: Radius.pill,
    paddingVertical: 14,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
    ...Shadows.elevated,
  },
  text: {
    color: Colors.white,
    fontSize: Typography.body.fontSize,
    fontWeight: '700',
  },
  disabled: {
    opacity: 0.5,
  },
});
