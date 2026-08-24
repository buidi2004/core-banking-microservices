import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface QuickAmountChipProps {
  value: string;
  onPress: (value: string) => void;
}

export const QuickAmountChip: React.FC<QuickAmountChipProps> = ({ value, onPress }) => (
  <TouchableOpacity style={styles.chip} onPress={() => onPress(value)}>
    <AppText variant="caption" style={styles.chipText}>{value}</AppText>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  chip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.pill,
  },
  chipText: {
    color: Colors.primaryDeep,
  },
});
