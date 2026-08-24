import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

interface ForgotPasswordScreenProps {
  navigation: any;
}

export default function ForgotPasswordScreen({ navigation }: ForgotPasswordScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backText}>← Quay lại</Text>
        </TouchableOpacity>

        <View style={styles.iconWrapper}>
          <Text style={styles.icon}>🔒</Text>
        </View>

        <Text style={styles.title}>Quên mật khẩu?</Text>
        <Text style={styles.desc}>
          Nhập số điện thoại đăng ký để nhận mã xác thực và đặt lại mật khẩu.
        </Text>

        <View style={styles.field}>
          <Text style={styles.label}>Số điện thoại</Text>
          <View style={styles.inputWrapper}>
            <Text style={styles.countryCode}>+84</Text>
            <Text style={styles.placeholder}>901234567</Text>
          </View>
        </View>

        <PrimaryButton title="Gửi mã xác thực" onPress={() => navigation.navigate('OtpVerification')} />

        <SecondaryButton
          title="Nhớ mật khẩu? Đăng nhập"
          onPress={() => navigation.goBack()}
          style={styles.secondaryBtn}
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
    paddingTop: Spacing.xl,
  },
  backBtn: {
    marginBottom: Spacing.xxl,
  },
  backText: {
    
    color: Colors.primary,
    fontWeight: '600',
  },
  iconWrapper: {
    width: 80,
    height: 80,
    borderRadius: Radius.xxl,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center',
    marginBottom: Spacing.xxl,
  },
  icon: {
    fontSize: Typography.displayLarge.fontSize,
  },
  title: {
    fontSize: Typography.headingXl.fontSize,
    fontWeight: '800',
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  desc: {
    
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
    marginBottom: Spacing.xxl,
  },
  field: {
    marginBottom: Spacing.md,
    gap: Spacing.xs,
  },
  label: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    height: 52,
  },
  countryCode: {
    
    color: Colors.textPrimary,
    fontWeight: '600',
    marginRight: Spacing.sm,
  },
  placeholder: {
    
    color: Colors.textSecondary,
  },
  secondaryBtn: {
    marginTop: Spacing.md,
  },
});
