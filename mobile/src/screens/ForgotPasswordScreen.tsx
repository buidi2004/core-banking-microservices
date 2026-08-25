import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  StatusBar,
  ScrollView,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { WalletApi } from '../services/api';

interface ForgotPasswordScreenProps {
  navigation: any;
}

export default function ForgotPasswordScreen({ navigation }: ForgotPasswordScreenProps) {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async () => {
    if (!phoneNumber) return;
    try {
      setIsLoading(true);
      // Assuming WalletApi is imported from api.ts
      await WalletApi.sendPasswordResetOtp(phoneNumber);
      setIsLoading(false);
      navigation.navigate('OtpVerification', { phone: phoneNumber });
    } catch (error: any) {
      setIsLoading(false);
      Alert.alert('Lỗi', error.message || 'Không thể gửi mã OTP');
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

        <AppText style={styles.headerTitle}>Đổi / Quên mật khẩu</AppText>

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
          <MaterialCommunityIcons name="lock-reset" size={48} color="#700F43" />
        </View>

        <AppText style={styles.title}>Thiết lập lại mật khẩu</AppText>
        <AppText style={styles.desc}>
          Vui lòng nhập số điện thoại đã đăng ký tài khoản MBBank để nhận mã OTP xác thực và đặt mật khẩu mới.
        </AppText>

        {/* PHONE NUMBER INPUT CARD */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Số điện thoại đăng ký</AppText>
          <View style={styles.inputRow}>
            <MaterialCommunityIcons name="phone-outline" size={22} color="#700F43" style={{ marginRight: 10 }} />
            <TextInput
              style={styles.phoneInput}
              value={phoneNumber}
              onChangeText={setPhoneNumber}
              keyboardType="phone-pad"
              placeholder="Nhập số điện thoại"
              placeholderTextColor="#94A3B8"
            />
          </View>
        </View>

        {/* SUBMIT BUTTON */}
        <TouchableOpacity
          style={styles.submitBtn}
          activeOpacity={0.9}
          onPress={handleSubmit}
          disabled={isLoading}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <AppText style={styles.submitBtnText}>
            {isLoading ? 'Đang gửi...' : 'Gửi mã xác thực OTP'}
          </AppText>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.backLoginBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <AppText style={styles.backLoginText}>Quay lại</AppText>
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
    paddingTop: 30,
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
  title: {
    fontSize: 20,
    fontWeight: '900',
    color: '#0F172A',
    marginBottom: 8,
    textAlign: 'center',
  },
  desc: {
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
    marginBottom: 24,
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
  phoneInput: {
    flex: 1,
    fontSize: 17,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: 0.5,
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
    marginBottom: 16,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
  backLoginBtn: {
    paddingVertical: 8,
    paddingHorizontal: 16,
  },
  backLoginText: {
    fontSize: 14.5,
    fontWeight: '700',
    color: '#700F43',
  },
});
