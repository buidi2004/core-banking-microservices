import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface EmptyStateProps {
  icon?: string;
  title: string;
  subtitle?: string;
  actionLabel?: string;
  onAction?: () => void;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  icon = 'scanFrame',
  title,
  subtitle,
  actionLabel,
  onAction,
}) => (
  <View style={styles.container}>
    <View style={styles.iconWrapper}>
      <AppIcon name={icon as any} size="lg" color={Colors.primarySoft} />
    </View>
    <AppText variant="heading" style={styles.title}>{title}</AppText>
    {subtitle && <AppText variant="caption" style={styles.subtitle}>{subtitle}</AppText>}
    {actionLabel && onAction && (
      <TouchableOpacity style={styles.actionBtn} onPress={onAction}>
        <AppText variant="body" style={styles.actionText}>{actionLabel}</AppText>
      </TouchableOpacity>
    )}
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: Spacing.xxl,
  },
  iconWrapper: {
    width: 96,
    height: 96,
    borderRadius: Radius.lg,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  title: {
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  subtitle: {
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: Spacing.lg,
  },
  actionBtn: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.pill,
  },
  actionText: {
    color: Colors.primary,
  },
});