import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  StatusBar,
  Dimensions,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

import { WalletApi } from '../services/api';

const { width } = Dimensions.get('window');

interface ResetPasswordScreenProps {
  route?: any;
  navigation: any;
}

export default function ResetPasswordScreen({ route, navigation }: ResetPasswordScreenProps) {
  const { phone = '', otp = '' } = route?.params || {};
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [showConfirmPass, setShowConfirmPass] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const hasLength = newPassword.length >= 8;
  const hasUpper = /[A-Z]/.test(newPassword);
  const hasLower = /[a-z]/.test(newPassword);
  const hasNumber = /[0-9]/.test(newPassword);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(newPassword);
  const isMatch = newPassword.length > 0 && newPassword === confirmPassword;

  const isFormValid = hasLength && hasUpper && hasLower && hasNumber && isMatch;

  const handleResetPassword = async () => {
    if (!isFormValid) {
      Alert.alert('Thông báo', 'Vui lòng đáp ứng đầy đủ tiêu chuẩn bảo mật mật khẩu của MBBank.');
      return;
    }
    try {
      setIsLoading(true);
      await WalletApi.resetPassword(phone, otp, newPassword);
      setIsLoading(false);
      Alert.alert(
        'Thành công',
        'Mật khẩu tài khoản MBBank của bạn đã được thay đổi thành công!',
        [
          {
            text: 'Đăng nhập ngay',
            onPress: () => navigation.navigate('Login'),
          },
        ]
      );
    } catch (error: any) {
      setIsLoading(false);
      Alert.alert('Lỗi', error.message || 'Không thể đặt lại mật khẩu');
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* TOP HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Đặt lại mật khẩu</AppText>

        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.navigate('Home')}
        >
          <Ionicons name="home-outline" size={22} color="#700F43" />
        </TouchableOpacity>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* HERO ICON */}
        <View style={styles.heroIconWrapper}>
          <MaterialCommunityIcons name="shield-lock-outline" size={48} color="#700F43" />
        </View>

        <AppText style={styles.headingTitle}>Tạo mật khẩu mới</AppText>
        <AppText style={styles.headingSubtitle}>
          Vui lòng thiết lập mật khẩu mới cho tài khoản của bạn theo tiêu chuẩn an ninh ngân hàng.
        </AppText>

        {/* INPUT 1: MẬT KHẨU MỚI */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Mật khẩu mới</AppText>
          <View style={styles.inputRow}>
            <MaterialCommunityIcons name="lock-outline" size={22} color="#700F43" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.textInput}
              value={newPassword}
              onChangeText={setNewPassword}
              secureTextEntry={!showPass}
              placeholder="Nhập mật khẩu mới"
              placeholderTextColor="#94A3B8"
            />
            <TouchableOpacity
              onPress={() => setShowPass(!showPass)}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            >
              <Ionicons
                name={showPass ? "eye-off-outline" : "eye-outline"}
                size={20}
                color="#64748B"
              />
            </TouchableOpacity>
          </View>
        </View>

        {/* INPUT 2: XÁC NHẬN MẬT KHẨU MỚI */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Xác nhận mật khẩu mới</AppText>
          <View style={styles.inputRow}>
            <MaterialCommunityIcons name="lock-check-outline" size={22} color="#700F43" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.textInput}
              value={confirmPassword}
              onChangeText={setConfirmPassword}
              secureTextEntry={!showConfirmPass}
              placeholder="Nhập lại mật khẩu mới"
              placeholderTextColor="#94A3B8"
            />
            <TouchableOpacity
              onPress={() => setShowConfirmPass(!showConfirmPass)}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            >
              <Ionicons
                name={showConfirmPass ? "eye-off-outline" : "eye-outline"}
                size={20}
                color="#64748B"
              />
            </TouchableOpacity>
          </View>
        </View>

        {/* PASSWORD CRITERIA CHECKLIST */}
        <View style={styles.criteriaCard}>
          <AppText style={styles.criteriaHeader}>Tiêu chuẩn mật khẩu an toàn:</AppText>

          <View style={styles.checkItem}>
            <Ionicons
              name={hasLength ? "checkmark-circle" : "ellipse-outline"}
              size={18}
              color={hasLength ? "#10B981" : "#94A3B8"}
            />
            <AppText style={[styles.checkText, hasLength && styles.checkTextPass]}>
              Tối thiểu 8 ký tự
            </AppText>
          </View>

          <View style={styles.checkItem}>
            <Ionicons
              name={hasUpper && hasLower ? "checkmark-circle" : "ellipse-outline"}
              size={18}
              color={hasUpper && hasLower ? "#10B981" : "#94A3B8"}
            />
            <AppText style={[styles.checkText, hasUpper && hasLower && styles.checkTextPass]}>
              Chứa cả chữ hoa (A-Z) và chữ thường (a-z)
            </AppText>
          </View>

          <View style={styles.checkItem}>
            <Ionicons
              name={hasNumber ? "checkmark-circle" : "ellipse-outline"}
              size={18}
              color={hasNumber ? "#10B981" : "#94A3B8"}
            />
            <AppText style={[styles.checkText, hasNumber && styles.checkTextPass]}>
              Chứa ít nhất 1 chữ số (0-9)
            </AppText>
          </View>

          <View style={styles.checkItem}>
            <Ionicons
              name={isMatch ? "checkmark-circle" : "ellipse-outline"}
              size={18}
              color={isMatch ? "#10B981" : "#94A3B8"}
            />
            <AppText style={[styles.checkText, isMatch && styles.checkTextPass]}>
              Mật khẩu xác nhận trùng khớp
            </AppText>
          </View>
        </View>

        {/* SUBMIT BUTTON */}
        <TouchableOpacity
          style={[styles.submitBtn, (!isFormValid || isLoading) && styles.submitBtnDisabled]}
          activeOpacity={0.9}
          onPress={handleResetPassword}
          disabled={!isFormValid || isLoading}
        >
          <LinearGradient
            colors={isFormValid ? ['#D2519D', '#700F43'] : ['#CBD5E1', '#94A3B8']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <AppText style={styles.submitBtnText}>
            {isLoading ? 'Đang xử lý...' : 'Xác nhận đổi mật khẩu'}
          </AppText>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  headerBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: -0.3,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 40,
    alignItems: 'center',
  },
  heroIconWrapper: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#FCE7F3',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 2,
  },
  headingTitle: {
    fontSize: 20,
    fontWeight: '900',
    color: '#0F172A',
    marginBottom: 6,
  },
  headingSubtitle: {
    fontSize: 13.5,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 19,
    marginBottom: 24,
    paddingHorizontal: 10,
  },
  inputCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 14,
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#64748B',
    marginBottom: 8,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1.5,
    borderBottomColor: '#D2519D',
    paddingBottom: 6,
  },
  textInput: {
    flex: 1,
    fontSize: 16,
    fontWeight: '700',
    color: '#0F172A',
  },
  criteriaCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 24,
    gap: 10,
  },
  criteriaHeader: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 4,
  },
  checkItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  checkText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#64748B',
  },
  checkTextPass: {
    color: '#15803D',
    fontWeight: '700',
  },
  submitBtn: {
    width: '100%',
    height: 50,
    borderRadius: 25,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 4,
  },
  submitBtnDisabled: {
    shadowOpacity: 0,
    elevation: 0,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
