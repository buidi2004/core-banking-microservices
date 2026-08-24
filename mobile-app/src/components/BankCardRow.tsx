import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

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
        <AppText variant="body" style={styles.bankName}>{bankName}</AppText>
        <AppText variant="bodySm" style={styles.accountNumber}>{accountNumber}</AppText>
      </View>
    </View>
    <View style={styles.rightSection}>
      {isDefault && (
        <View style={styles.defaultBadge}>
          <AppText variant="captionSm" style={styles.defaultBadgeText}>Mặc định</AppText>
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
    color: Colors.textPrimary,
  },
  accountNumber: {
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
    color: Colors.primary,
  },
});