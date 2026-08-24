import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { Colors, Radius, ListDivider } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface GroupedListRowProps {
  icon?: React.ReactNode;
  title: string;
  subtitle?: string;
  amount?: string;
  amountColor?: string;
  date?: string;
  right?: React.ReactNode;
  onPress?: () => void;
  isFirst?: boolean;
  isLast?: boolean;
  hasBadge?: boolean;
}

export const GroupedListRow: React.FC<GroupedListRowProps> = ({
  icon,
  title,
  subtitle,
  amount,
  amountColor,
  date,
  right,
  onPress,
  isFirst = false,
  isLast = false,
  hasBadge = false,
}) => {
  const borderTopRadius = isFirst ? Radius.sm : 0;
  const borderBottomRadius = isLast ? Radius.sm : 0;

  return (
    <TouchableOpacity
      style={[
        styles.container,
        { borderTopLeftRadius: borderTopRadius, borderBottomLeftRadius: borderBottomRadius },
      ]}
      onPress={onPress}
      activeOpacity={0.7}
    >
      {/* Left section */}
      <View style={styles.leftSection}>
        {icon && <View style={styles.iconWrapper}>{icon}</View>}
        <View style={styles.textGroup}>
          <AppText variant="body" style={styles.title} numberOfLines={1}>{title}</AppText>
          {(subtitle || date) && (
            <AppText variant="caption" style={styles.meta}>
              {subtitle}
              {subtitle && date ? ' • ' : ''}
              {date}
            </AppText>
          )}
        </View>
      </View>

      {/* Right section */}
      <View style={styles.rightSection}>
        {amount ? (
          <AppText variant="body" style={[styles.amount, amountColor ? { color: amountColor } : null]}>
            {amount}
          </AppText>
        ) : null}
        {right ?? null}
        {hasBadge && <View style={styles.badge} />}
      </View>

      {/* Divider (except last row) */}
      {!isLast && (
        <View style={[styles.divider, { marginLeft: icon ? 60 : 16 }]} />
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.surface,
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  leftSection: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 12,
  },
  iconWrapper: {
    width: 36,
    height: 36,
    borderRadius: Radius.xs,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  textGroup: {
    flex: 1,
    gap: 2,
  },
  title: {
    color: Colors.textPrimary,
  },
  meta: {
    color: Colors.textSecondary,
  },
  rightSection: {
    alignItems: 'flex-end',
    gap: 4,
  },
  amount: {
    color: Colors.textPrimary,
  },
  divider: {
    position: 'absolute',
    bottom: 0,
    left: 60,
    right: 0,
    height: ListDivider.thickness,
    backgroundColor: ListDivider.color,
  },
  badge: {
    width: 8,
    height: 8,
    borderRadius: Radius.pill,
    backgroundColor: Colors.primary,
  },
});
