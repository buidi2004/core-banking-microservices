import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ViewStyle, TextStyle } from 'react-native';
import { Colors, Radius, Shadows } from '../theme';
import { Typography } from '../theme';

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
    <Text style={[styles.text, textStyle]}>{title}</Text>
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
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
  },
  disabled: {
    opacity: 0.5,
  },
});
