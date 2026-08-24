import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, SafeAreaView, Modal } from 'react-native';
import { BlurView } from 'expo-blur';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { OtpBox } from '../components/OtpBox';
import { PrimaryButton } from '../components/PrimaryButton';

interface OtpVerificationScreenProps {
  navigation: any;
}

export default function OtpVerificationScreen({ navigation }: OtpVerificationScreenProps) {
  const [otp, setOtp] = useState<string[]>(['', '', '', '', '', '']);
  const [focusedIndex, setFocusedIndex] = useState<number>(-1);

  const handleChange = (text: string, index: number) => {
    const newOtp = [...otp];
    newOtp[index] = text;
    setOtp(newOtp);

    if (text && index < 5) {
      setFocusedIndex(index + 1);
    }

    if (newOtp.every(v => v !== '')) {
      setTimeout(() => navigation.navigate('Home'), 300);
    }
  };

  const handleBackspace = (index: number) => {
    if (otp[index] === '') {
      if (index > 0) {
        setFocusedIndex(index - 1);
      }
    } else {
      const newOtp = [...otp];
      newOtp[index] = '';
      setOtp(newOtp);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Backdrop blur */}
      <Modal visible transparent animationType="fade">
        <BlurView intensity={40} tint="light" style={styles.backdrop} />
        <View style={styles.modalContent}>
          <TouchableOpacity
            style={styles.closeBtn}
            onPress={() => navigation.goBack()}
          >
            <Text style={styles.closeText}>✕</Text>
          </TouchableOpacity>

          <Text style={styles.title}>Xác thực OTP</Text>
          <Text style={styles.subtitle}>
            Chúng tôi đã gửi mã 6 chữ số đến số điện thoại của bạn
          </Text>

          <View style={styles.otpContainer}>
            {otp.map((digit, index) => (
              <TouchableOpacity
                key={index}
                onPressIn={() => setFocusedIndex(index)}
                onLongPress={() => handleBackspace(index)}
              >
                <OtpBox
                  value={digit}
                  isActive={focusedIndex === index}
                />
              </TouchableOpacity>
            ))}
          </View>

          <TextInput
            style={styles.hiddenInput}
            value={otp.join('')}
            onChangeText={(text) => {
              const digits = text.split('').slice(0, 6);
              setOtp([...digits, ...Array(6 - digits.length).fill('')]);
            }}
            keyboardType="number-pad"
            maxLength={6}
            autoFocus
            onFocus={() => setFocusedIndex(otp.findIndex(v => v === ''))}
          />

          <PrimaryButton
            title="Xác nhận"
            onPress={() => navigation.navigate('Home')}
            disabled={!otp.every(v => v !== '')}
          />

          <TouchableOpacity style={styles.resendBtn}>
            <Text style={styles.resendText}>Gửi lại mã</Text>
          </TouchableOpacity>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  backdrop: {
    flex: 1,
  },
  modalContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing.xxl,
  },
  closeBtn: {
    position: 'absolute',
    top: Spacing.xl,
    right: Spacing.lg,
    width: 40,
    height: 40,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeText: {
    
    color: Colors.textPrimary,
  },
  title: {
    fontSize: Typography.headingXl.fontSize,
    fontWeight: '800',
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  subtitle: {
    
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.xxl,
    lineHeight: 22,
  },
  otpContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.xxl,
  },
  hiddenInput: {
    position: 'absolute',
    opacity: 0,
    width: 1,
    height: 1,
  },
  resendBtn: {
    marginTop: Spacing.xl,
  },
  resendText: {
    
    color: Colors.primary,
    fontWeight: '600',
  },
});
