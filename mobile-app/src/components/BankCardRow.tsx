import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';

interface BankCardRowProps {
  bankName: string;
  accountNumber: string;
  isDefault?: boolean;
  onPress?: () => void;
}

export const BankCardRow: React.FC<BankCardRowProps> = ({
  bankName,
  accountNumber,
  isDefault,
  onPress,
}) => (
  <TouchableOpacity style={styles.container} onPress={onPress} activeOpacity={0.7}>
    <View style={styles.leftSection}>
      <View style={styles.bankIcon}>
        <AppIcon name="bank" size="sm" color={Colors.primary} />
      </View>
      <View style={styles.info}>
        <Text style={styles.bankName}>{bankName}</Text>
        <Text style={styles.accountNumber}>{accountNumber}</Text>
      </View>
    </View>
    <View style={styles.rightSection}>
      {isDefault && (
        <View style={styles.defaultBadge}>
          <Text style={styles.defaultBadgeText}>Mặc định</Text>
        </View>
      )}
      <AppIcon name="chevronRight" size="sm" color={Colors.textSecondary} />
    </View>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.md,
  },
  leftSection: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    flex: 1,
  },
  bankIcon: {
    width: 40,
    height: 40,
    borderRadius: Radius.sm,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  info: {
    flex: 1,
    gap: 4,
  },
  bankName: {
    fontSize: Typography.body.fontSize,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  accountNumber: {
    fontSize: Typography.bodySm.fontSize,
    color: Colors.textSecondary,
  },
  rightSection: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  defaultBadge: {
    backgroundColor: Colors.primarySoft,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
  },
  defaultBadgeText: {
    fontSize: Typography.captionSm.fontSize,
    fontWeight: '600',
    color: Colors.primary,
  },
});