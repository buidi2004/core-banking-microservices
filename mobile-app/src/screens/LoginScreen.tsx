import React from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { Colors, Radius, Spacing } from '../theme';
import { Typography } from '../theme';
import { AppIcon } from '../components/icons/AppIcon';
import { PrimaryButton } from '../components/PrimaryButton';
import { AppText } from '../components/typography/AppText';

interface LoginScreenProps {
  navigation: any;
}

export default function LoginScreen({ navigation }: LoginScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        <View style={styles.logoWrapper}>
          <AppIcon name="qr" size="lg" color={Colors.primary} />
        </View>
        <AppText variant="headingXl" style={styles.title}>Chào mừng đến với E-Wallet</AppText>
        <AppText style={styles.subtitle}>Đăng nhập để tiếp tục</AppText>

        <View style={styles.form}>
          <View style={styles.field}>
            <AppText style={styles.label}>Số điện thoại</AppText>
            <View style={styles.inputWrapper}>
              <AppText style={styles.countryCode}>+84</AppText>
              <AppText style={styles.inputPlaceholder}>901234567</AppText>
            </View>
          </View>

          <View style={styles.field}>
            <AppText style={styles.label}>Mật khẩu</AppText>
            <View style={styles.inputWrapper}>
              <AppText style={styles.inputPlaceholder}>••••••••</AppText>
              <TouchableOpacity>
                <AppIcon name="eye" size="sm" color={Colors.textSecondary} />
              </TouchableOpacity>
            </View>
          </View>
        </View>

        <PrimaryButton title="Đăng nhập" onPress={() => navigation.navigate('MainTabs')} />

        <TouchableOpacity style={styles.forgotLink}>
          <AppText style={styles.forgotText}>Quên mật khẩu?</AppText>
        </TouchableOpacity>

        <TouchableOpacity style={styles.registerLink}>
          <AppText style={styles.registerText}>Chưa có tài khoản? Đăng ký</AppText>
        </TouchableOpacity>
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
    paddingTop: Spacing.xxxl,
    alignItems: 'center',
  },
  logoWrapper: {
    width: 100,
    height: 100,
    borderRadius: Radius.xxl,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.xxl,
  },
  title: {
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.sm,
  },
  subtitle: {
    
    color: Colors.textSecondary,
    marginBottom: Spacing.xxl,
  },
  form: {
    width: '100%',
    gap: Spacing.md,
    marginBottom: Spacing.xxl,
  },
  field: {
    gap: Spacing.xs,
  },
  label: {
    
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
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
  inputPlaceholder: {
    flex: 1,
    
    color: Colors.textSecondary,
  },
  forgotLink: {
    alignSelf: 'center',
    marginBottom: Spacing.sm,
  },
  forgotText: {
    
    color: Colors.primary,
    },
  registerLink: {
    alignSelf: 'center',
  },
  registerText: {
    
    color: Colors.textSecondary,
  },
});
