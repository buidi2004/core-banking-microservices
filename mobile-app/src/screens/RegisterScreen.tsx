import React from 'react';
import { View, StyleSheet, TextInput, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { AppText } from '../components/typography/AppText';

interface RegisterScreenProps {
  navigation: any;
}

export default function RegisterScreen({ navigation }: RegisterScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppText variant="headingXl" style={styles.backBtn}>←</AppText>
          </TouchableOpacity>
          <AppText style={styles.headerTitle}>Đăng ký tài khoản</AppText>
          <View style={styles.spacer} />
        </View>

        <View style={styles.form}>
          <View style={styles.field}>
            <AppText style={styles.label}>Họ và tên</AppText>
            <TextInput
              style={styles.input}
              placeholder="Nhập họ tên"
              placeholderTextColor={Colors.textSecondary}
            />
          </View>

          <View style={styles.field}>
            <AppText style={styles.label}>Số điện thoại</AppText>
            <TextInput
              style={styles.input}
              placeholder="901234567"
              placeholderTextColor={Colors.textSecondary}
              keyboardType="phone-pad"
            />
          </View>

          <View style={styles.field}>
            <AppText style={styles.label}>Email</AppText>
            <TextInput
              style={styles.input}
              placeholder="example@email.com"
              placeholderTextColor={Colors.textSecondary}
              keyboardType="email-address"
            />
          </View>

          <View style={styles.field}>
            <AppText style={styles.label}>Mật khẩu</AppText>
            <TextInput
              style={styles.input}
              placeholder="••••••••"
              placeholderTextColor={Colors.textSecondary}
              secureTextEntry
            />
          </View>

          <PrimaryButton title="Tiếp tục" onPress={() => navigation.navigate('OtpVerification')} />

          <View style={styles.divider}>
            <View style={styles.line} />
            <AppText style={styles.dividerText}>hoặc</AppText>
            <View style={styles.line} />
          </View>

          <PrimaryButton
            title="Đăng ký qua SMS"
            onPress={() => navigation.navigate('OtpVerification')}
            style={styles.secondaryBtn}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },
  backBtn: {
    color: Colors.textPrimary,
  },
  headerTitle: {
    
    color: Colors.textPrimary,
  },
  spacer: {
    width: 40,
  },
  form: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
    paddingBottom: Spacing.xxl,
  },
  field: {
    gap: Spacing.xs,
  },
  label: {
    
    color: Colors.textPrimary,
  },
  input: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    height: 52,
    
    color: Colors.textPrimary,
    ...Shadows.card,
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    marginTop: Spacing.md,
  },
  line: {
    flex: 1,
    height: 1,
    backgroundColor: Colors.primarySoft,
  },
  dividerText: {
    
    color: Colors.textSecondary,
  },
  secondaryBtn: {
    marginTop: Spacing.md,
  },
});
