import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';

interface QuickAmountChipProps {
  value: string;
  onPress: (value: string) => void;
}

export const QuickAmountChip: React.FC<QuickAmountChipProps> = ({ value, onPress }) => (
  <TouchableOpacity style={styles.chip} onPress={() => onPress(value)}>
    <Text style={styles.chipText}>{value}</Text>
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
    fontSize: Typography.caption.fontSize,
    fontWeight: '600',
    color: Colors.primaryDeep,
  },
});
