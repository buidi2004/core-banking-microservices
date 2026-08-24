import React from 'react';
import { TouchableOpacity, StyleSheet, ViewStyle, TextStyle } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Opacity } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

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
    <AppText variant="body" style={[styles.text, textStyle]}>{title}</AppText>
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
    },
  disabled: {
    opacity: Opacity.disabled,
  },
});
