import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Dimensions,
  StatusBar,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import Svg, { Rect, G, Defs, LinearGradient as SvgLinearGradient, Stop, Path } from 'react-native-svg';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';
import { ActivityIndicator, Alert } from 'react-native';

const { width } = Dimensions.get('window');

// 3D Floating Stadium Capsules Background (Atmosphere)
function Floating3DCapsules() {
  return (
    <Svg width={width} height={520} viewBox="0 0 380 520" fill="none" style={StyleSheet.absoluteFill}>
      <Defs>
        <SvgLinearGradient id="capsuleGrad1" x1="0" y1="0" x2="1" y2="1">
          <Stop offset="0%" stopColor="#F472B6" stopOpacity="0.4" />
          <Stop offset="50%" stopColor="#D2519D" stopOpacity="0.3" />
          <Stop offset="100%" stopColor="#700F43" stopOpacity="0.15" />
        </SvgLinearGradient>
        <SvgLinearGradient id="capsuleGrad2" x1="0" y1="0" x2="1" y2="1">
          <Stop offset="0%" stopColor="#E4ACB2" stopOpacity="0.3" />
          <Stop offset="100%" stopColor="#700F43" stopOpacity="0.12" />
        </SvgLinearGradient>
      </Defs>

      {/* Upper Tilted Stadium Shape */}
      <G transform="translate(100, 110) rotate(-16)">
        <Rect x="0" y="0" width="300" height="75" rx="37.5" fill="url(#capsuleGrad1)" stroke="rgba(255,255,255,0.2)" strokeWidth="1.5" />
        <Path d="M37.5 12h225" stroke="rgba(255,255,255,0.3)" strokeWidth="3" strokeLinecap="round" />
      </G>

      {/* Lower Tilted Stadium Shape */}
      <G transform="translate(110, 260) rotate(-16)">
        <Rect x="0" y="0" width="280" height="70" rx="35" fill="url(#capsuleGrad2)" stroke="rgba(255,255,255,0.16)" strokeWidth="1.5" />
        <Path d="M35 10h210" stroke="rgba(255,255,255,0.25)" strokeWidth="2.5" strokeLinecap="round" />
      </G>
    </Svg>
  );
}

export default function LoginScreen({ navigation }: any) {
  const { login, isLoading, lastError, clearError } = useApp();
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('0839888823');
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async () => {
    if (!password) {
      Alert.alert('Lỗi', 'Vui lòng nhập mật khẩu');
      return;
    }
    try {
      await login(phone, password);
      navigation.navigate('MainTabs');
    } catch (e: any) {
      Alert.alert('Đăng nhập thất bại', lastError || e.message);
      clearError();
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1F0413" translucent />

      {/* 3D LOTUS PINK & PLUM GRADIENT BACKGROUND */}
      <LinearGradient
        colors={['#1F0413', '#700F43', '#3B0724']}
        start={{ x: 0.1, y: 0 }}
        end={{ x: 0.9, y: 1 }}
        style={StyleSheet.absoluteFill}
      />

      {/* 3D FLOATING CAPSULES ATMOSPHERE */}
      <Floating3DCapsules />

      <SafeAreaView style={styles.safeArea} edges={['top', 'bottom']}>
        {/* 1. TOP HEADER ROW */}
        <View style={styles.topHeader}>
          {/* Logo MB with Star */}
          <View style={styles.logoRow}>
            <View style={styles.starIconWrapper}>
              <AppText style={styles.starText}>★</AppText>
            </View>
            <AppText style={styles.logoText}>MB</AppText>
          </View>

          {/* Right Action Icons (Flag 🇻🇳, Bell 🔔, Bee 🐝 Hỗ trợ) */}
          <View style={styles.rightHeaderActions}>
            <TouchableOpacity style={styles.flagBtn} activeOpacity={0.8}>
              <AppText style={{ fontSize: 20 }}>🇻🇳</AppText>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.circleHeaderBtn}
              activeOpacity={0.8}
              onPress={() => navigation.navigate('Notifications')}
            >
              <Ionicons name="notifications-outline" size={20} color="#FFFFFF" />
            </TouchableOpacity>

            <TouchableOpacity style={styles.supportBeeBtn} activeOpacity={0.8}>
              <AppText style={{ fontSize: 22 }}>🐝</AppText>
              <View style={styles.supportPillBadge}>
                <AppText style={styles.supportPillText}>HỖ TRỢ</AppText>
              </View>
            </TouchableOpacity>
          </View>
        </View>

        <ScrollView
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.scrollContent}
        >
          <View style={{ height: 40 }} />

          {/* 2. MAIN FROSTED GLASS LOGIN CARD */}
          <View style={styles.glassLoginCard}>
            <LinearGradient
              colors={['rgba(255, 255, 255, 0.18)', 'rgba(255, 255, 255, 0.08)']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />

            <View style={styles.cardInnerPadding}>
              {/* Top Row: Shield Check + Real Fingerprint Icon */}
              <View style={styles.cardTopRow}>
                <MaterialCommunityIcons name="shield-check" size={32} color="#10B981" />

                {/* Fingerprint Button */}
                <TouchableOpacity
                  style={styles.biometricBtn}
                  activeOpacity={0.8}
                  onPress={() => navigation.navigate('MainTabs')}
                >
                  <MaterialCommunityIcons name="fingerprint" size={32} color="#F472B6" />
                </TouchableOpacity>
              </View>

              {/* Greeting & Name */}
              <AppText style={styles.greetingText}>Xin chào,</AppText>
              <View style={styles.formContainer}>
                <AppText style={styles.label}>Số điện thoại</AppText>
                <View style={[styles.inputWrapper, { marginBottom: 20 }]}>
                  <Ionicons name="call-outline" size={20} color="#700F43" style={styles.inputIcon} />
                  <TextInput
                    style={styles.input}
                    placeholder="Nhập số điện thoại"
                    placeholderTextColor="#94A3B8"
                    value={phone}
                    onChangeText={setPhone}
                    keyboardType="numeric"
                  />
                </View>

                <AppText style={styles.label}>Mật khẩu</AppText>
                <View style={styles.inputWrapper}>
                  <Ionicons name="lock-closed-outline" size={20} color="#700F43" style={styles.inputIcon} />
                  <TextInput
                    style={styles.input}
                    placeholder="Nhập mật khẩu"
                    placeholderTextColor="#94A3B8"
                    secureTextEntry={!showPassword}
                    value={password}
                    onChangeText={setPassword}
                  />
                  <TouchableOpacity onPress={() => setShowPassword(!showPassword)} style={styles.eyeIcon}>
                    <Ionicons name={showPassword ? 'eye-outline' : 'eye-off-outline'} size={20} color="#64748B" />
                  </TouchableOpacity>
                </View>
              </View>

              {/* Links Row */}
              <View style={styles.linksRow}>
                <TouchableOpacity activeOpacity={0.7} onPress={() => {}}>
                  <AppText style={styles.linkText}>Tài khoản khác</AppText>
                </TouchableOpacity>

                <TouchableOpacity activeOpacity={0.7} onPress={() => navigation.navigate('ForgotPassword')}>
                  <AppText style={styles.linkText}>Quên mật khẩu?</AppText>
                </TouchableOpacity>
              </View>
            </View>

            {/* Bottom Attached Login Button */}
            <TouchableOpacity
              style={styles.loginBtnAttached}
              activeOpacity={0.9}
              onPress={handleLogin}
              disabled={isLoading}
            >
              <LinearGradient
                colors={['#D2519D', '#E11D48']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                style={StyleSheet.absoluteFill}
              />
              {isLoading ? (
                <ActivityIndicator color="#FFF" />
              ) : (
                <AppText style={styles.loginBtnText}>Đăng nhập</AppText>
              )}
            </TouchableOpacity>
          </View>
        </ScrollView>

        {/* 3. BOTTOM 3 ACTION ITEMS (REAL VECTOR ICONS) */}
        <View style={styles.bottomFooterContainer}>
          <View style={styles.bottomActionsRow}>
            {/* Quét QR */}
            <TouchableOpacity
              style={styles.bottomActionItem}
              activeOpacity={0.8}
              onPress={() => navigation.navigate('QR')}
            >
              <MaterialCommunityIcons name="qrcode-scan" size={24} color="#E4ACB2" />
              <AppText style={styles.bottomActionLabel}>Quét QR</AppText>
            </TouchableOpacity>

            {/* Xác thực D-OTP */}
            <TouchableOpacity
              style={styles.bottomActionItem}
              activeOpacity={0.8}
              onPress={() => navigation.navigate('OtpVerification')}
            >
              <MaterialCommunityIcons name="shield-key-outline" size={25} color="#E4ACB2" />
              <AppText style={styles.bottomActionLabel}>Xác thực D-OTP</AppText>
            </TouchableOpacity>

            {/* Thay ảnh nền */}
            <TouchableOpacity
              style={styles.bottomActionItem}
              activeOpacity={0.8}
              onPress={() => {}}
            >
              <View style={styles.iconWithBadgeWrap}>
                <Ionicons name="images-outline" size={24} color="#E4ACB2" />
                <View style={styles.newBadgePill}>
                  <AppText style={styles.newBadgeText}>NEW</AppText>
                </View>
              </View>
              <AppText style={styles.bottomActionLabel}>Thay ảnh nền</AppText>
            </TouchableOpacity>
          </View>

          {/* Bottom Expand Arrow Chevron */}
          <TouchableOpacity style={styles.bottomExpandArrow} activeOpacity={0.7}>
            <MaterialCommunityIcons name="chevron-double-up" size={24} color="#E4ACB2" />
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1F0413',
  },
  safeArea: {
    flex: 1,
  },
  topHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 10,
    zIndex: 10,
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  starIconWrapper: {
    width: 28,
    height: 28,
    borderRadius: 7,
    backgroundColor: '#E11D48',
    justifyContent: 'center',
    alignItems: 'center',
  },
  starText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '900',
  },
  logoText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#FFFFFF',
    letterSpacing: 0.5,
  },
  rightHeaderActions: {
    flexDirection: 'column',
    alignItems: 'center',
    gap: 12,
  },
  flagBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  circleHeaderBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  supportBeeBtn: {
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.25)',
    borderRadius: 18,
    paddingHorizontal: 4,
    paddingVertical: 2,
  },
  supportPillBadge: {
    backgroundColor: '#D2519D',
    borderRadius: 8,
    paddingHorizontal: 4,
    paddingVertical: 1,
    marginTop: -4,
  },
  supportPillText: {
    fontSize: 8,
    fontWeight: '900',
    color: '#FFFFFF',
    letterSpacing: 0.2,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingBottom: 20,
    justifyContent: 'center',
    flexGrow: 1,
  },
  glassLoginCard: {
    backgroundColor: 'rgba(112, 15, 67, 0.65)',
    borderRadius: 24,
    borderWidth: 1.5,
    borderColor: 'rgba(255, 255, 255, 0.25)',
    overflow: 'hidden',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 10,
  },
  cardInnerPadding: {
    padding: 22,
  },
  cardTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  biometricBtn: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: 'rgba(255, 255, 255, 0.12)',
    borderWidth: 1.2,
    borderColor: 'rgba(244, 114, 182, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#F472B6',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 6,
    elevation: 4,
  },
  greetingText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#E4ACB2',
    marginBottom: 4,
  },
  userNameLine1: {
    fontSize: 32,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.5,
    lineHeight: 36,
  },
  userNameLine2: {
    fontSize: 32,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.5,
    lineHeight: 36,
    marginBottom: 26,
  },
  inputContainer: {
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255, 255, 255, 0.3)',
    paddingBottom: 6,
    marginBottom: 16,
  },
  passwordInput: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    paddingVertical: 4,
  },
  formContainer: {
    width: '100%',
    paddingHorizontal: 10,
  },
  label: {
    color: '#CBD5E1',
    fontSize: 14,
    marginBottom: 8,
    marginLeft: 4,
    fontWeight: '500',
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderRadius: 16,
    paddingHorizontal: 16,
    height: 56,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  inputIcon: {
    marginRight: 12,
    color: '#F472B6',
  },
  input: {
    flex: 1,
    color: '#FFF',
    fontSize: 16,
    fontFamily: 'Inter_400Regular',
  },
  eyeIcon: {
    padding: 8,
  },
  linksRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  linkText: {
    fontSize: 13.5,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  loginBtnAttached: {
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderBottomLeftRadius: 22,
    borderBottomRightRadius: 22,
    overflow: 'hidden',
  },
  loginBtnText: {
    fontSize: 16.5,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.2,
  },
  bottomFooterContainer: {
    paddingBottom: 10,
    alignItems: 'center',
  },
  bottomActionsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    width: '100%',
    paddingHorizontal: 16,
    marginBottom: 14,
  },
  bottomActionItem: {
    alignItems: 'center',
    gap: 6,
  },
  iconWithBadgeWrap: {
    position: 'relative',
  },
  newBadgePill: {
    position: 'absolute',
    top: -6,
    right: -14,
    backgroundColor: '#EF4444',
    borderRadius: 6,
    paddingHorizontal: 4,
    paddingVertical: 1,
  },
  newBadgeText: {
    fontSize: 8,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  bottomActionLabel: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  bottomExpandArrow: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4,
  },
});
