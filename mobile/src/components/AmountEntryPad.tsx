import React from 'react';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Spacing, Shadows } from '../theme';
import { Typography } from '../theme';
import { AppText } from './typography/AppText';

interface AmountEntryPadProps {
  onInputChange?: (value: string) => void;
}

export const AmountEntryPad: React.FC<AmountEntryPadProps> = ({ onInputChange }) => {
  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];

  const handlePress = (key: string) => {
    if (key === 'del') {
      onInputChange?.('');
    } else if (key) {
      onInputChange?.(key);
    }
  };

  return (
    <View style={styles.container}>
      {keys.map((key, i) => (
        <TouchableOpacity
          key={i}
          style={[styles.key, key === '' && styles.emptyKey]}
          onPress={() => handlePress(key)}
          activeOpacity={0.7}
        >
          {key === 'del' ? (
            <AppIcon name="close" size="sm" color={Colors.textPrimary} />
          ) : (
            <AppText variant="headingXl" style={styles.keyText}>{key}</AppText>
          )}
        </TouchableOpacity>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: Spacing.sm,
    padding: Spacing.md,
  },
  key: {
    width: 72,
    height: 56,
    borderRadius: Radius.sm,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.card,
  },
  emptyKey: {
    backgroundColor: 'transparent',
    shadowColor: 'transparent',
  },
  keyText: {
    color: Colors.textPrimary,
  },
});