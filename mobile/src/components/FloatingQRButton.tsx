import React from 'react';
import { TouchableOpacity, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { AppIcon } from './icons/AppIcon';
import { Colors, Radius, Shadows } from '../theme';

interface FloatingQRButtonProps {
  onPress?: () => void;
}

export const FloatingQRButton: React.FC<FloatingQRButtonProps> = ({ onPress }) => (
  <TouchableOpacity style={styles.touchable} onPress={onPress} activeOpacity={0.85}>
    <LinearGradient
      colors={[Colors.primary, Colors.heroGradMid]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.button}
    >
      <AppIcon name="qr" size="lg" color={Colors.white} />
    </LinearGradient>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  touchable: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  button: {
    width: 64,
    height: 64,
    borderRadius: Radius.lg,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.hero,
  },
});