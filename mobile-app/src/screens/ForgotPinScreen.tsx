import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { Colors, Radius, Spacing, Shadows } from '../theme';
import { Typography } from '../theme';
import { PinDot } from '../components/PinDot';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

interface ForgotPinScreenProps {
  navigation: any;
}

export default function ForgotPinScreen({ navigation }: ForgotPinScreenProps) {
  const [step, setStep] = useState(1); // 1: verify OTP, 2: set new pin, 3: confirm pin
  const [otp, setOtp] = useState<string[]>(['', '', '', '', '', '']);
  const [newPin, setNewPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [error, setError] = useState('');

  const handleOtpChange = (text: string, index: number) => {
    const newOtp = [...otp];
    newOtp[index] = text;
    setOtp(newOtp);
    if (newOtp.every(v => v !== '') && step === 1) {
      setTimeout(() => setStep(2), 300);
    }
  };

  const handlePinPress = (num: string, setter: React.Dispatch<React.SetStateAction<string>>) => {
    setter(prev => prev + num);
  };

  const handleDelete = (setter: React.Dispatch<React.SetStateAction<string>>) => {
    setter(prev => prev.slice(0, -1));
  };

  if (step === 2 && newPin.length === 6) {
    setStep(3);
  }

  if (step === 3 && confirmPin.length === 6) {
    if (newPin === confirmPin) {
      navigation.navigate('Home');
    } else {
      setError('PIN không khớp. Vui lòng thử lại.');
    }
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Step indicator */}
        <View style={styles.stepIndicator}>
          {[1, 2, 3].map((s) => (
            <View key={s} style={[styles.stepDot, step >= s && styles.stepDotActive]} />
          ))}
        </View>

        {/* Title */}
        <Text style={styles.title}>
          {step === 1 ? 'Xác thực OTP' : step === 2 ? 'Đặt PIN mới' : 'Xác nhận PIN'}
        </Text>
        <Text style={styles.subtitle}>
          {step === 1
            ? 'Nhập mã OTP gửi đến SĐT của bạn'
            : step === 2
            ? 'Nhập PIN 6 chữ số mới'
            : 'Nhập lại PIN để xác nhận'}
        </Text>

        {/* OTP input */}
        {step === 1 && (
          <View style={styles.otpContainer}>
            {otp.map((digit, index) => (
              <TouchableOpacity
                key={index}
                onPressIn={() => {}}
                onLongPress={() => {
                  const newOtp = [...otp];
                  newOtp[index] = '';
                  setOtp(newOtp);
                }}
              >
                <PinDot filled={digit !== ''} size="sm" masked />
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* PIN input */}
        {(step === 2 || step === 3) && (
          <>
            <View style={styles.pinContainer}>
              {[...Array(6)].map((_, i) => (
                <PinDot
                  key={i}
                  filled={(step === 2 ? newPin : confirmPin).length > i}
                  size="sm"
                  masked
                />
              ))}
            </View>

            {error ? <Text style={styles.errorText}>{error}</Text> : null}

            {/* Keypad */}
            <View style={styles.keypad}>
              {['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'].map((key, i) => (
                <TouchableOpacity
                  key={i}
                  style={[styles.key, key === '' && styles.emptyKey]}
                  onPress={() => {
                    if (key === 'del') {
                      handleDelete(step === 2 ? setNewPin : setConfirmPin);
                    } else if (key) {
                      handlePinPress(key, step === 2 ? setNewPin : setConfirmPin);
                    }
                  }}
                  activeOpacity={0.7}
                >
                  <Text style={styles.keyText}>{key === 'del' ? '⌫' : key}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </>
        )}

        {/* Actions */}
        {step === 1 && (
          <View style={styles.actions}>
            <PrimaryButton
              title="Tiếp tục"
              onPress={() => setStep(2)}
              disabled={!otp.every(v => v !== '')}
            />
            <TouchableOpacity style={styles.resendBtn}>
              <Text style={styles.resendText}>Gửi lại mã</Text>
            </TouchableOpacity>
          </View>
        )}

        {step === 3 && (
          <PrimaryButton
            title="Hoàn tất"
            onPress={() => navigation.navigate('Home')}
            disabled={newPin !== confirmPin}
          />
        )}

        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
          <Text style={styles.backText}>← Quay lại</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  scrollView: {
    flex: 1,
    paddingHorizontal: Spacing.xxl,
    paddingTop: Spacing.xxl,
  },
  stepIndicator: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.xxl,
  },
  stepDot: {
    width: 8,
    height: 8,
    borderRadius: Radius.xs,
    backgroundColor: Colors.primarySoft,
  },
  stepDotActive: {
    backgroundColor: Colors.primary,
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
  },
  otpContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.md,
    marginBottom: Spacing.xxl,
  },
  pinContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: Spacing.md,
    marginBottom: Spacing.lg,
  },
  errorText: {
    
    color: Colors.danger,
    textAlign: 'center',
    marginBottom: Spacing.md,
  },
  keypad: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.xl,
  },
  key: {
    width: 72,
    height: 72,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.card,
  },
  emptyKey: {
    backgroundColor: 'transparent',
    shadowColor: Colors.shadowTransparent,
  },
  keyText: {
    fontSize: Typography.headingXl.fontSize,
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  actions: {
    gap: Spacing.md,
    marginTop: Spacing.xl,
  },
  resendBtn: {
    alignSelf: 'center',
    paddingVertical: Spacing.sm,
  },
  resendText: {
    
    color: Colors.primary,
    fontWeight: '600',
  },
  backBtn: {
    alignSelf: 'center',
    paddingVertical: Spacing.md,
    marginTop: Spacing.lg,
  },
  backText: {
    
    color: Colors.textSecondary,
    fontWeight: '500',
  },
});
