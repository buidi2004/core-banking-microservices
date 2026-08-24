import React from 'react';
import { View, TextInput, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface SearchBarProps {
  value?: string;
  onChangeText?: (text: string) => void;
  placeholder?: string;
  showCancel?: boolean;
  onCancel?: () => void;
}

export const SearchBar: React.FC<SearchBarProps> = ({
  value,
  onChangeText,
  placeholder = 'Tìm kiếm...',
  showCancel,
  onCancel,
}) => (
  <View style={styles.container}>
    <AppIcon name="search" size="sm" color={Colors.textSecondary} />
    <TextInput style={styles.input}
      value={value}
      onChangeText={onChangeText}
      placeholder={placeholder}
      placeholderTextColor={Colors.textSecondary}
    />
    {showCancel && (
      <TouchableOpacity onPress={onCancel} style={styles.cancelBtn}>
        <AppText variant="body" style={styles.cancelText}>Huỷ</AppText>
      </TouchableOpacity>
    )}
  </View>
);

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: Radius.pill,
    paddingHorizontal: Spacing.md,
    height: 48,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  input: {
    flex: 1,
    color: Colors.textPrimary,
    marginLeft: Spacing.sm,
  },
  cancelBtn: {
    marginLeft: Spacing.sm,
  },
  cancelText: {
    color: Colors.primary,
    },
});