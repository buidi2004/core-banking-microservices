import React from 'react';
import { TouchableOpacity, StyleSheet, ViewStyle, TextStyle } from 'react-native';
import { Colors, Radius, Shadows, Opacity } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface SecondaryButtonProps {
  title: string;
  onPress?: () => void;
  style?: ViewStyle;
  textStyle?: TextStyle;
  disabled?: boolean;
}

export const SecondaryButton: React.FC<SecondaryButtonProps> = ({
  title,
  onPress,
  style,
  textStyle,
  disabled,
}) => (
  <TouchableOpacity
    style={[styles.container, disabled ? styles.disabled : null, style]}
    onPress={onPress}
    activeOpacity={0.8}
  >
    <AppText variant="body" style={[styles.text, textStyle]}>{title}</AppText>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  container: {
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.primary,
    paddingVertical: 12,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    color: Colors.primary,
    },
  disabled: {
    opacity: Opacity.disabled,
  },
});
