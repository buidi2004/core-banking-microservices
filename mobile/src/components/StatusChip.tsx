import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Colors, Radius } from '../theme';
import { AppText } from './typography/AppText';

type StatusType = 'success' | 'danger' | 'warning';

interface StatusChipProps {
  text: string;
  type?: StatusType;
  size?: 'sm' | 'md';
}

export const StatusChip: React.FC<StatusChipProps> = ({
  text,
  type = 'warning',
  size = 'md',
}) => {
  const config = {
    success: { bg: Colors.success, bgSoft: Colors.successSoft, color: Colors.successText },
    danger: { bg: Colors.danger, bgSoft: Colors.dangerSoft, color: Colors.dangerText },
    warning: { bg: Colors.warning, bgSoft: Colors.warningSoft, color: Colors.warningText },
  }[type];

  return (
    <View
      style={[
        styles.chip,
        size === 'md' ? styles.chipMd : styles.chipSm,
        { backgroundColor: config.bgSoft },
      ]}
    >
      <View
        style={[
          styles.dot,
          size === 'md' ? styles.dotMd : styles.dotSm,
          { backgroundColor: config.bg },
        ]}
      />
      <AppText variant="caption" style={[styles.text, size === 'md' ? styles.textMd : styles.textSm, { color: config.color }]}>
        {text}
      </AppText>
    </View>
  );
};

const styles = StyleSheet.create({
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: Radius.pill,
    paddingHorizontal: 12,
    paddingVertical: 6,
    gap: 6,
  },
  chipMd: { paddingVertical: 8, paddingHorizontal: 14 },
  chipSm: { paddingVertical: 4, paddingHorizontal: 8 },
  dot: {
    borderRadius: Radius.pill,
  },
  dotMd: { width: 8, height: 8 },
  dotSm: { width: 6, height: 6 },
  text: { letterSpacing: 0.3 },
  textMd: { },
  textSm: { },
});
