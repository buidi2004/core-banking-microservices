import React from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

const { width } = Dimensions.get('window');

interface KycLevelScreenProps {
  navigation: any;
}

export default function KycLevelScreen({ navigation }: KycLevelScreenProps) {
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

        <AppText style={styles.headerTitle}>Mức định danh</AppText>

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
        {/* CURRENT KYC HERO CARD */}
        <View style={styles.heroCard}>
          <LinearGradient
            colors={['#FDF2F8', '#FCE7F3']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={StyleSheet.absoluteFill}
          />
          <View style={styles.heroIconWrapper}>
            <MaterialCommunityIcons name="shield-check" size={48} color="#10B981" />
          </View>

          <AppText style={styles.heroLevelTitle}>Định danh Cấp 2 (eKYC)</AppText>
          <AppText style={styles.heroSubtitle}>
            Tài khoản của bạn đã được xác thực danh tính đầy đủ trực tuyến qua sinh trắc học và CCCD gắn chip.
          </AppText>

          <View style={styles.activeBadge}>
            <View style={styles.greenDot} />
            <AppText style={styles.activeBadgeText}>Đang hoạt động đầy đủ tính năng</AppText>
          </View>
        </View>

        {/* VERIFIED ITEMS CARD */}
        <View style={styles.detailsCard}>
          <AppText style={styles.cardSectionTitle}>Hồ sơ đã xác thực</AppText>

          <View style={styles.kycRow}>
            <View style={styles.kycIconCircle}>
              <MaterialCommunityIcons name="face-recognition" size={22} color="#700F43" />
            </View>
            <View style={styles.kycInfoCol}>
              <AppText style={styles.kycItemTitle}>Khuôn mặt (FaceID / Sinh trắc học)</AppText>
              <AppText style={styles.kycItemSub}>Đã đối khớp với dữ liệu dân cư</AppText>
            </View>
            <Ionicons name="checkmark-circle" size={22} color="#10B981" />
          </View>

          <View style={styles.divider} />

          <View style={styles.kycRow}>
            <View style={styles.kycIconCircle}>
              <MaterialCommunityIcons name="card-account-details-outline" size={22} color="#700F43" />
            </View>
            <View style={styles.kycInfoCol}>
              <AppText style={styles.kycItemTitle}>CCCD Gắn Chip NFC</AppText>
              <AppText style={styles.kycItemSub}>079204012891 - Đã kích hoạt</AppText>
            </View>
            <Ionicons name="checkmark-circle" size={22} color="#10B981" />
          </View>

          <View style={styles.divider} />

          <View style={styles.kycRow}>
            <View style={styles.kycIconCircle}>
              <Ionicons name="call-outline" size={22} color="#700F43" />
            </View>
            <View style={styles.kycInfoCol}>
              <AppText style={styles.kycItemTitle}>Số điện thoại chính chủ</AppText>
              <AppText style={styles.kycItemSub}>0923158725 (Viettel)</AppText>
            </View>
            <Ionicons name="checkmark-circle" size={22} color="#10B981" />
          </View>
        </View>

        {/* BENEFITS CARD */}
        <View style={styles.detailsCard}>
          <AppText style={styles.cardSectionTitle}>Hạn mức & Quyền lợi của bạn</AppText>

          <View style={styles.benefitRow}>
            <Ionicons name="flash-outline" size={20} color="#D2519D" />
            <AppText style={styles.benefitText}>Chuyển tiền hạn mức lên tới 500,000,000 đ/ngày</AppText>
          </View>

          <View style={styles.benefitRow}>
            <MaterialCommunityIcons name="bank-outline" size={20} color="#D2519D" />
            <AppText style={styles.benefitText}>Mở tài khoản số đẹp & thẻ thanh toán quốc tế</AppText>
          </View>

          <View style={styles.benefitRow}>
            <MaterialCommunityIcons name="piggy-bank-outline" size={20} color="#D2519D" />
            <AppText style={styles.benefitText}>Gửi tiết kiệm trực tuyến & vay vốn tín chấp</AppText>
          </View>
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
  heroIconWrapper: {
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
  heroLevelTitle: {
    fontSize: 20,
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
    paddingHorizontal: 10,
  },
  activeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    gap: 6,
  },
  greenDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#10B981',
  },
  activeBadgeText: {
    fontSize: 12.5,
    fontWeight: '800',
    color: '#15803D',
  },
  detailsCard: {
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
  cardSectionTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 14,
  },
  kycRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    gap: 12,
  },
  kycIconCircle: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  kycInfoCol: {
    flex: 1,
  },
  kycItemTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  kycItemSub: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  divider: {
    height: 1,
    backgroundColor: '#F1F5F9',
  },
  benefitRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 8,
  },
  benefitText: {
    fontSize: 13.5,
    fontWeight: '600',
    color: '#334155',
    flex: 1,
  },
});
