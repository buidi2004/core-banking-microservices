import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { PinDot } from '../components/PinDot';
import { AppText } from '../components/typography/AppText';

interface SetPinScreenProps {
  navigation: any;
}

import { WalletApi } from '../services/api';

export default function SetPinScreen({ navigation }: SetPinScreenProps) {
  const [pin, setPin] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);

  const handlePress = async (num: string) => {
    if (pin.length < 6 && !isLoading) {
      const newPin = pin + num;
      setPin(newPin);
      
      if (newPin.length === 6) {
        try {
          setIsLoading(true);
          await WalletApi.setPin(newPin);
          setIsLoading(false);
          navigation.navigate('Home');
        } catch (error: any) {
          setIsLoading(false);
          setPin('');
          Alert.alert('Lỗi', error.message || 'Không thể thiết lập mã PIN');
        }
      }
    }
  };

  const handleDelete = () => {
    setPin(prev => prev.slice(0, -1));
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <AppText variant="headingLg" style={styles.title}>Thiết lập PIN</AppText>
        <AppText style={styles.subtitle}>Nhập PIN 6 chữ số mới</AppText>

        <View style={styles.pinContainer}>
          {[...Array(6)].map((_, i) => (
            <PinDot key={i} filled={i < pin.length} size={18} />
          ))}
        </View>

        <View style={styles.keypad}>
          {['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'].map((key, i) => (
            <TouchableOpacity
              key={i}
              style={[styles.key, key === '' && styles.emptyKey]}
              onPress={() => {
                if (key === 'del') handleDelete();
                else if (key) handlePress(key);
              }}
              activeOpacity={0.7}
            >
              {key === 'del' ? (
                <AppText variant="headingXl" style={styles.keyText}>⌫</AppText>
              ) : (
                <AppText variant="headingXl" style={styles.keyText}>{key}</AppText>
              )}
            </TouchableOpacity>
          ))}
        </View>

        <PrimaryButton
          title="Tiếp tục"
          onPress={() => navigation.navigate('Home')}
          disabled={pin.length !== 6}
          style={styles.continueBtn}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  content: {
    flex: 1,
    paddingHorizontal: Spacing.xxl,
    justifyContent: 'center',
  },
  title: {
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  subtitle: {
    
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.xxl,
  },
  pinContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.md,
    marginBottom: Spacing.xxl,
  },
  keypad: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.xxl,
  },
  key: {
    width: 72,
    height: 72,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyKey: {
    backgroundColor: 'transparent',
  },
  keyText: {
    color: Colors.textPrimary,
  },
  continueBtn: {
    marginTop: Spacing.md,
  },
});
