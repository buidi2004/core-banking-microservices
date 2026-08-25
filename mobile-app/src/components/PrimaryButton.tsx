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
    style={[styles.container, disabled && styles.disabled, style]}
  >
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled}
      style={styles.touchable}
      activeOpacity={0.8}
    >
      <AppText variant="body" style={[styles.text, textStyle]}>{title}</AppText>
    </TouchableOpacity>
  </LinearGradient>
);

const styles = StyleSheet.create({
  container: {
    borderRadius: Radius.pill,
    width: '100%',
    height: 52,
    ...Shadows.elevated,
  },
  touchable: {
    flex: 1,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    color: Colors.white,
    fontWeight: '700',
  },
  disabled: {
    opacity: Opacity.disabled,
  },
});
