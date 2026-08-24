import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';

interface ProviderIconGridProps {
  providers: Array<{
    icon: string;
    label: string;
    onPress?: () => void;
  }>;
}

export const ProviderIconGrid: React.FC<ProviderIconGridProps> = ({ providers }) => (
  <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.container}>
    {providers.map((provider, i) => (
      <TouchableOpacity
        key={i}
        style={styles.providerItem}
        onPress={provider.onPress}
        activeOpacity={0.7}
      >
        <View style={styles.iconWrapper}>
          <AppIcon name={provider.icon as any} size="md" color={Colors.primary} />
        </View>
        <Text style={styles.providerLabel}>{provider.label}</Text>
      </TouchableOpacity>
    ))}
  </ScrollView>
);

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    paddingBottom: Spacing.sm,
  },
  providerItem: {
    alignItems: 'center',
    marginRight: Spacing.md,
    minWidth: 80,
  },
  iconWrapper: {
    width: 64,
    height: 64,
    borderRadius: Radius.xl,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  providerLabel: {
    fontSize: Typography.caption.fontSize,
    color: Colors.textPrimary,
    fontWeight: '500',
    textAlign: 'center',
  },
});