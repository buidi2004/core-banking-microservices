import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Colors, Radius } from '../theme';

interface OtpBoxProps {
  value?: string;
  isActive?: boolean;
}

export const OtpBox: React.FC<OtpBoxProps> = ({ value, isActive }) => (
  <View
    style={[
      styles.container,
      {
        borderColor: isActive ? Colors.primary : Colors.primarySoft,
        backgroundColor: isActive ? Colors.primarySoft : Colors.surface,
      },
    ]}
  >
    <View
      style={[
        styles.dot,
        {
          width: 8,
          height: 8,
          borderRadius: Radius.xs,
          backgroundColor: value ? Colors.primary : 'transparent',
        },
      ]}
    />
  </View>
);

const styles = StyleSheet.create({
  container: {
    width: 48,
    height: 56,
    borderRadius: Radius.xs,
    borderWidth: 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  dot: {
    borderRadius: Radius.xs,
  },
});
