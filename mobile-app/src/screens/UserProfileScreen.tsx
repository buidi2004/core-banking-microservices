import React from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Image,
  StatusBar,
  Dimensions,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';

const { width } = Dimensions.get('window');

interface UserProfileScreenProps {
  navigation: any;
}

export default function UserProfileScreen({ navigation }: UserProfileScreenProps) {
  const { user } = useApp();
  const handleEditAvatar = () => {
    Alert.alert('Cập nhật ảnh đại diện', 'Chọn ảnh từ thư viện hoặc chụp ảnh mới.');
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* 1. TOP HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Hồ sơ người dùng</AppText>

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
        {/* 2. MAIN USER CARD (AVATAR + NAME + ID + 2 SUB-CARDS + LOYALTY) */}
        <View style={styles.userMainCard}>
          {/* Avatar with Edit Pencil */}
          <View style={styles.avatarContainer}>
            <Image
              source={{ uri: 'https://i.pravatar.cc/300?img=11' }}
              style={styles.avatarImage}
            />
            <TouchableOpacity
              style={styles.editPencilBtn}
              activeOpacity={0.8}
              onPress={handleEditAvatar}
            >
              <Ionicons name="pencil-outline" size={15} color="#0F172A" />
            </TouchableOpacity>
          </View>

          {/* User Name & User ID */}
          <AppText style={styles.userNameText}>{user?.name || 'Tên người dùng'}</AppText>
          <AppText style={styles.userIdText}>
            User ID: <AppText style={{ color: '#700F43', fontWeight: '800' }}>{user?.phoneNumber || '0000000000'}</AppText>
          </AppText>

          {/* 2 Sub-Cards Row */}
          <View style={styles.twoSubCardsRow}>
            {/* Left Card: Đang được bảo vệ */}
            <TouchableOpacity
              style={styles.subCard}
              activeOpacity={0.8}
              onPress={() => navigation.navigate('SecuritySettings')}
            >
              <MaterialCommunityIcons name="shield-check" size={26} color="#10B981" />
              <AppText style={styles.subCardText}>
                Đang được{'\n'}bảo vệ
              </AppText>
            </TouchableOpacity>

            {/* Right Card: Gói hội viên MB Basic */}
            <TouchableOpacity
              style={styles.subCard}
              activeOpacity={0.8}
              onPress={() => navigation.navigate('KycLevel')}
            >
              <FontAwesome5 name="crown" size={22} color="#94A3B8" />
              <View>
                <AppText style={styles.subCardLabel}>Gói hội viên MB</AppText>
                <AppText style={styles.subCardValue}>Basic</AppText>
              </View>
            </TouchableOpacity>
          </View>

          {/* Loyalty Score Card Inside Main Container */}
          <View style={styles.loyaltyBox}>
            <View style={styles.loyaltyLeftCol}>
              <AppText style={styles.loyaltySmallLabel}>ĐIỂM LOYALTY</AppText>
              <View style={styles.loyaltyScoreRow}>
                <AppText style={styles.loyaltyScoreNumber}>0</AppText>
                <FontAwesome5 name="crown" size={16} color="#F59E0B" style={{ marginLeft: 6 }} />
              </View>

              <TouchableOpacity
                style={styles.collectPointsRow}
                activeOpacity={0.7}
                onPress={() => navigation.navigate('Promotions')}
              >
                <AppText style={styles.collectPointsText}>Tích điểm</AppText>
                <Ionicons name="chevron-forward" size={13} color="#700F43" />
              </TouchableOpacity>
            </View>

            {/* Nút Đổi Quà */}
            <TouchableOpacity
              style={styles.redeemGiftBtn}
              activeOpacity={0.9}
              onPress={() => navigation.navigate('Promotions')}
            >
              <LinearGradient
                colors={['#D2519D', '#700F43']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                style={StyleSheet.absoluteFill}
              />
              <AppText style={styles.redeemGiftText}>Đổi quà</AppText>
            </TouchableOpacity>
          </View>
        </View>

        {/* 3. SETTINGS & KYC GROUPED MENU LIST */}
        <View style={styles.menuGroupCard}>
          {/* Item 1: Mức định danh */}
          <TouchableOpacity
            style={styles.menuItemRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('KycLevel')}
          >
            <View style={styles.menuItemLeft}>
              <MaterialCommunityIcons name="face-recognition" size={22} color="#700F43" />
              <AppText style={styles.menuItemTitle}>Mức định danh</AppText>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>

          <View style={styles.menuDivider} />

          {/* Item 2: Chữ ký số */}
          <TouchableOpacity
            style={styles.menuItemRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('DigitalSignature')}
          >
            <View style={styles.menuItemLeft}>
              <MaterialCommunityIcons name="draw-pen" size={22} color="#700F43" />
              <AppText style={styles.menuItemTitle}>Chữ ký số</AppText>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>

          <View style={styles.menuDivider} />

          {/* Item 3: Giấy tờ tùy thân */}
          <TouchableOpacity
            style={styles.menuItemRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('IdentityDocument')}
          >
            <View style={styles.menuItemLeft}>
              <MaterialCommunityIcons name="card-account-details-outline" size={22} color="#700F43" />
              <AppText style={styles.menuItemTitle}>Giấy tờ tùy thân</AppText>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>

          <View style={styles.menuDivider} />

          {/* Item 4: Email */}
          <TouchableOpacity
            style={styles.menuItemRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('EmailSettings')}
          >
            <View style={styles.menuItemLeft}>
              <Ionicons name="mail-outline" size={22} color="#700F43" />
              <AppText style={styles.menuItemTitle}>Email</AppText>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#700F43" />
          </TouchableOpacity>

          <View style={styles.menuDivider} />

          {/* Item 5: Đổi mật khẩu */}
          <TouchableOpacity
            style={styles.menuItemRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('ForgotPassword')}
          >
            <View style={styles.menuItemLeft}>
              <MaterialCommunityIcons name="lock-reset" size={22} color="#700F43" />
              <AppText style={styles.menuItemTitle}>Đổi mật khẩu</AppText>
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
  userMainCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 18,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 3,
    marginBottom: 16,
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: 12,
  },
  avatarImage: {
    width: 96,
    height: 96,
    borderRadius: 48,
    borderWidth: 3,
    borderColor: '#FCE7F3',
  },
  editPencilBtn: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  userNameText: {
    fontSize: 20,
    fontWeight: '900',
    color: '#0F172A',
    marginBottom: 4,
  },
  userIdText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
    marginBottom: 16,
  },
  twoSubCardsRow: {
    flexDirection: 'row',
    gap: 12,
    width: '100%',
    marginBottom: 16,
  },
  subCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingVertical: 12,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  subCardText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0F172A',
    lineHeight: 16,
  },
  subCardLabel: {
    fontSize: 11.5,
    fontWeight: '600',
    color: '#64748B',
  },
  subCardValue: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  loyaltyBox: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#FCE7F3',
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  loyaltyLeftCol: {
    gap: 2,
  },
  loyaltySmallLabel: {
    fontSize: 11,
    fontWeight: '800',
    color: '#64748B',
    letterSpacing: 0.3,
  },
  loyaltyScoreRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  loyaltyScoreNumber: {
    fontSize: 22,
    fontWeight: '900',
    color: '#0F172A',
  },
  collectPointsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    marginTop: 2,
  },
  collectPointsText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#700F43',
  },
  redeemGiftBtn: {
    borderRadius: 20,
    overflow: 'hidden',
    paddingHorizontal: 18,
    paddingVertical: 9,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.25,
    shadowRadius: 6,
    elevation: 4,
  },
  redeemGiftText: {
    color: '#FFFFFF',
    fontSize: 13.5,
    fontWeight: '800',
  },
  menuGroupCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingHorizontal: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  menuItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  menuItemTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#0F172A',
  },
  menuDivider: {
    height: 1,
    backgroundColor: '#F1F5F9',
  },
});
