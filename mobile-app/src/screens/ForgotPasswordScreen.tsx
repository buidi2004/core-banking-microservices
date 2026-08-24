import React from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';
import { AppText } from '../components/typography/AppText';

interface ForgotPasswordScreenProps {
  navigation: any;
}

export default function ForgotPasswordScreen({ navigation }: ForgotPasswordScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <AppText style={styles.backText}>← Quay lại</AppText>
        </TouchableOpacity>

        <View style={styles.iconWrapper}>
          <AppText variant="displayLarge" style={styles.icon}>🔒</AppText>
        </View>

        <AppText variant="headingXl" style={styles.title}>Quên mật khẩu?</AppText>
        <AppText style={styles.desc}>
          Nhập số điện thoại đăng ký để nhận mã xác thực và đặt lại mật khẩu.
        </AppText>

        <View style={styles.field}>
          <AppText style={styles.label}>Số điện thoại</AppText>
          <View style={styles.inputWrapper}>
            <AppText style={styles.countryCode}>+84</AppText>
            <AppText style={styles.placeholder}>901234567</AppText>
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
    },
  title: {
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
    marginRight: Spacing.sm,
  },
  placeholder: {
    
    color: Colors.textSecondary,
  },
  secondaryBtn: {
    marginTop: Spacing.md,
  },
});
