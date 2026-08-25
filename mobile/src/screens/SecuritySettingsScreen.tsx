import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Switch,
  StatusBar,
  Dimensions,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

const { width } = Dimensions.get('window');

interface SecuritySettingsScreenProps {
  navigation: any;
}

export default function SecuritySettingsScreen({ navigation }: SecuritySettingsScreenProps) {
  const [isBiometricEnabled, setIsBiometricEnabled] = useState(true);
  const [isHideBalanceDefault, setIsHideBalanceDefault] = useState(false);

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

        <AppText style={styles.headerTitle}>Bảo mật & Xác thực</AppText>

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
        {/* HERO STATUS CARD */}
        <View style={styles.heroCard}>
          <LinearGradient
            colors={['#FDF2F8', '#FCE7F3']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={StyleSheet.absoluteFill}
          />
          <View style={styles.heroIconCircle}>
            <MaterialCommunityIcons name="shield-check" size={44} color="#10B981" />
          </View>

          <AppText style={styles.heroTitle}>Tài khoản đang được bảo vệ</AppText>
          <AppText style={styles.heroSubtitle}>
            Hệ thống giám sát bảo mật đa lớp 24/7 của MBBank bảo vệ an toàn cho mọi giao dịch thanh toán của bạn.
          </AppText>

          <View style={styles.securityScoreBadge}>
            <Ionicons name="checkmark-circle" size={16} color="#10B981" />
            <AppText style={styles.securityScoreText}>Mức độ an toàn: Tối đa (100%)</AppText>
          </View>
        </View>

        {/* AUTHENTICATION METHODS */}
        <View style={styles.groupCard}>
          <AppText style={styles.groupCardTitle}>Phương thức xác thực</AppText>

          {/* 1. Biometric Fingerprint / FaceID */}
          <View style={styles.menuRow}>
            <View style={styles.menuLeft}>
              <View style={styles.iconCircle}>
                <MaterialCommunityIcons name="fingerprint" size={22} color="#700F43" />
              </View>
              <View style={{ flex: 1 }}>
                <AppText style={styles.menuTitle}>Đăng nhập sinh trắc học</AppText>
                <AppText style={styles.menuSub}>Vân tay / Nhận diện khuôn mặt</AppText>
              </View>
            </View>
            <Switch
              value={isBiometricEnabled}
              onValueChange={setIsBiometricEnabled}
              trackColor={{ false: '#CBD5E1', true: '#D2519D' }}
              thumbColor="#FFFFFF"
            />
          </View>

          <View style={styles.divider} />

          {/* 2. Digital OTP */}
          <TouchableOpacity
            style={styles.menuRow}
            activeOpacity={0.7}
            onPress={() => Alert.alert('Digital OTP', 'Mã PIN Digital OTP của bạn đang hoạt động bình thường.')}
          >
            <View style={styles.menuLeft}>
              <View style={styles.iconCircle}>
                <MaterialCommunityIcons name="shield-key-outline" size={22} color="#700F43" />
              </View>
              <View style={{ flex: 1 }}>
                <AppText style={styles.menuTitle}>Quản lý Digital OTP</AppText>
                <AppText style={styles.menuSub}>Đổi mã PIN / Đăng ký lại thiết bị</AppText>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>

          <View style={styles.divider} />

          {/* 3. Đổi mật khẩu đăng nhập */}
          <TouchableOpacity
            style={styles.menuRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('ForgotPassword')}
          >
            <View style={styles.menuLeft}>
              <View style={styles.iconCircle}>
                <MaterialCommunityIcons name="lock-reset" size={22} color="#700F43" />
              </View>
              <View style={{ flex: 1 }}>
                <AppText style={styles.menuTitle}>Đổi mật khẩu đăng nhập</AppText>
                <AppText style={styles.menuSub}>Cập nhật định kỳ để tăng tính an toàn</AppText>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>
        </View>

        {/* PRIVACY & DEVICES */}
        <View style={styles.groupCard}>
          <AppText style={styles.groupCardTitle}>Quyền riêng tư & Thiết bị</AppText>

          {/* Ẩn số dư mặc định */}
          <View style={styles.menuRow}>
            <View style={styles.menuLeft}>
              <View style={styles.iconCircle}>
                <Ionicons name="eye-off-outline" size={22} color="#700F43" />
              </View>
              <View style={{ flex: 1 }}>
                <AppText style={styles.menuTitle}>Ẩn số dư khi mở ứng dụng</AppText>
                <AppText style={styles.menuSub}>Bảo vệ số dư khỏi người xung quanh</AppText>
              </View>
            </View>
            <Switch
              value={isHideBalanceDefault}
              onValueChange={setIsHideBalanceDefault}
              trackColor={{ false: '#CBD5E1', true: '#D2519D' }}
              thumbColor="#FFFFFF"
            />
          </View>

          <View style={styles.divider} />

          {/* Quản lý thiết bị */}
          <TouchableOpacity
            style={styles.menuRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('DeviceManagement')}
          >
            <View style={styles.menuLeft}>
              <View style={styles.iconCircle}>
                <MaterialCommunityIcons name="cellphone-link" size={22} color="#700F43" />
              </View>
              <View style={{ flex: 1 }}>
                <AppText style={styles.menuTitle}>Quản lý thiết bị đăng nhập</AppText>
                <AppText style={styles.menuSub}>1 thiết bị đang tin cậy</AppText>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>
        </View>
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
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 40,
  },
  heroCard: {
    borderRadius: 20,
    padding: 20,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    marginBottom: 16,
    overflow: 'hidden',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 10,
    elevation: 3,
  },
  heroIconCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
    borderWidth: 2,
    borderColor: '#DCFCE7',
    shadowColor: '#10B981',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 2,
  },
  heroTitle: {
    fontSize: 19,
    fontWeight: '900',
    color: '#700F43',
    marginBottom: 6,
  },
  heroSubtitle: {
    fontSize: 13,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 14,
    paddingHorizontal: 6,
  },
  securityScoreBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    gap: 6,
  },
  securityScoreText: {
    fontSize: 12.5,
    fontWeight: '800',
    color: '#15803D',
  },
  groupCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginBottom: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  groupCardTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  menuRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
  },
  menuLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
    paddingRight: 10,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  menuTitle: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  menuSub: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '600',
  },
  divider: {
    height: 1,
    backgroundColor: '#F1F5F9',
    marginVertical: 4,
  },
});
