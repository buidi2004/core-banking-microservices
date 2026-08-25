import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Image,
  Dimensions,
  StatusBar,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import Svg, { Path, Rect, Circle, G, Defs, RadialGradient, Stop } from 'react-native-svg';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { SideMenuDrawer } from '../components/SideMenuDrawer';

const { width } = Dimensions.get('window');

// 1. Hot Deal 3D Center Graphics with Gift Boxes & Lightning
function HotDealGraphic({ width: bannerW = width - 32, height: bannerH = 140 }: { width?: number; height?: number }) {
  return (
    <Svg width={bannerW} height={bannerH} viewBox="0 0 340 140" fill="none">
      <Defs>
        <RadialGradient id="glow" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor="#F472B6" stopOpacity="0.8" />
          <Stop offset="100%" stopColor="#D2519D" stopOpacity="0" />
        </RadialGradient>
      </Defs>

      <Circle cx="170" cy="70" r="60" fill="url(#glow)" />

      {/* Left Gift Box */}
      <G transform="translate(40, 25) rotate(-15)">
        <Rect x="0" y="15" width="48" height="42" rx="6" fill="#FFFFFF" />
        <Rect x="-2" y="10" width="52" height="12" rx="3" fill="#FDF2F8" />
        <Rect x="20" y="10" width="8" height="47" fill="#E11D48" />
        <Rect x="-2" y="30" width="52" height="8" fill="#E11D48" />
        <Circle cx="18" cy="8" r="6" stroke="#E11D48" strokeWidth="3" fill="none" />
        <Circle cx="30" cy="8" r="6" stroke="#E11D48" strokeWidth="3" fill="none" />
      </G>

      {/* Right Gift Box */}
      <G transform="translate(250, 30) rotate(18)">
        <Rect x="0" y="15" width="44" height="38" rx="6" fill="#FFFFFF" />
        <Rect x="-2" y="10" width="48" height="10" rx="3" fill="#FDF2F8" />
        <Rect x="18" y="10" width="8" height="43" fill="#E11D48" />
        <Rect x="-2" y="28" width="48" height="8" fill="#E11D48" />
        <Circle cx="16" cy="8" r="5" stroke="#E11D48" strokeWidth="3" fill="none" />
        <Circle cx="28" cy="8" r="5" stroke="#E11D48" strokeWidth="3" fill="none" />
      </G>

      {/* Center 3D Burst Circle */}
      <Circle cx="170" cy="70" r="38" fill="#700F43" stroke="#D2519D" strokeWidth="3" />
      <Path
        d="M170 30L175 42L188 38L180 50L194 54L178 68L205 70L178 78L190 92L176 90L174 104L165 92L152 98L160 84L144 80L160 70L135 68L160 58L148 46L164 48Z"
        fill="#D2519D"
        opacity="0.4"
      />
    </Svg>
  );
}

// 2. Hero Visual Art for Cashback Plus Modal
function CashbackHeroArt() {
  return (
    <Svg width={140} height={110} viewBox="0 0 140 110" fill="none">
      {/* 3D Shopping Bag Lotus Pink */}
      <G transform="translate(35, 12)">
        <Path d="M10 25h45l-5 50H15L10 25z" fill="#D2519D" />
        <Path d="M15 75h35l-3-48H18l-3 48z" fill="#700F43" />
        <Path d="M24 25V14a8 8 0 0 1 16 0v11" stroke="#FFFFFF" strokeWidth="3.5" strokeLinecap="round" />
        <G transform="translate(0, 30) rotate(-15)">
          <Rect x="0" y="0" width="26" height="34" rx="4" fill="#10B981" />
          <Circle cx="13" cy="6" r="2" fill="#FFFFFF" />
          <AppText style={{ fontSize: 13, color: '#FFFFFF', fontWeight: '900', textAlign: 'center', marginTop: 10 }}>%</AppText>
        </G>
      </G>

      {/* 3D Smartphone Cashback Mockup */}
      <G transform="translate(85, 25) rotate(10)">
        <Rect x="0" y="0" width="38" height="65" rx="6" fill="#FFFFFF" stroke="#FBCFE8" strokeWidth="1.5" />
        <Rect x="4" y="6" width="30" height="53" rx="4" fill="#FDF2F8" />
        <Circle cx="19" cy="30" r="10" fill="#700F43" />
        <Path d="M19 24v12M15 30h8" stroke="#FFFFFF" strokeWidth="1.5" strokeLinecap="round" />
      </G>

      {/* 3D Green Gift Box */}
      <G transform="translate(60, 60)">
        <Rect x="0" y="6" width="30" height="26" rx="4" fill="#34D399" />
        <Rect x="-2" y="2" width="34" height="6" rx="2" fill="#6EE7B7" />
        <Rect x="12" y="2" width="6" height="30" fill="#FFFFFF" opacity="0.8" />
      </G>

      {/* Gold Coin */}
      <G transform="translate(38, 68)">
        <Circle cx="13" cy="13" r="13" fill="#FBBF24" stroke="#F59E0B" strokeWidth="1.5" />
        <AppText style={{ fontSize: 12, fontWeight: '900', color: '#B45309', textAlign: 'center', marginTop: 3 }}>₫</AppText>
      </G>
    </Svg>
  );
}

export default function PromotionsScreen({ navigation }: any) {
  const [isSideMenuVisible, setIsSideMenuVisible] = useState(false);
  const [isPromoModalVisible, setIsPromoModalVisible] = useState(true);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#700F43" />

      {/* 1. TOP CURVED LOTUS PINK HEADER */}
      <View style={styles.headerContainer}>
        <LinearGradient
          colors={['#E4ACB2', '#D2519D', '#700F43']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={StyleSheet.absoluteFill}
        />

        <SafeAreaView edges={['top']}>
          <View style={styles.headerContent}>
            {/* Logo MB with Star */}
            <View style={styles.logoContainer}>
              <View style={styles.starIconWrapper}>
                <AppText style={styles.starText}>★</AppText>
              </View>
              <AppText style={styles.logoText}>MB</AppText>
            </View>

            {/* Center Mascot Bee Avatar */}
            <View style={styles.beeAvatarContainer}>
              <View style={styles.beeAvatarCircle}>
                <AppText style={{ fontSize: 24 }}>🐝</AppText>
              </View>
            </View>

            {/* 3 Right Action Icons (Real Vector Icons) */}
            <View style={styles.headerActions}>
              <TouchableOpacity style={styles.headerIconBtn} activeOpacity={0.7} onPress={() => navigation.navigate('Search')}>
                <Ionicons name="sparkles-outline" size={20} color="#FFFFFF" />
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.headerIconBtn}
                activeOpacity={0.7}
                onPress={() => navigation.navigate('Notifications')}
              >
                <Ionicons name="notifications-outline" size={20} color="#FFFFFF" />
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.headerIconBtn}
                activeOpacity={0.7}
                onPress={() => setIsSideMenuVisible(true)}
              >
                <Ionicons name="menu-outline" size={24} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
          </View>
        </SafeAreaView>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* 2. PAGE TITLE */}
        <AppText style={styles.pageTitle}>Ưu đãi</AppText>

        {/* 3. TOP 2 CARDS IN 2-COLUMN ROW */}
        <View style={styles.twoCardsRow}>
          {/* Card 1: Điểm Loyalty */}
          <TouchableOpacity
            style={styles.loyaltyCard}
            activeOpacity={0.85}
            onPress={() => setIsPromoModalVisible(true)}
          >
            <LinearGradient
              colors={['#FFFBEB', '#FDF2F8']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />
            <View style={styles.cardHeaderRow}>
              <AppText style={styles.loyaltyHeaderTitle}>ĐIỂM LOYALTY</AppText>
              <Ionicons name="chevron-forward" size={15} color="#D2519D" />
            </View>

            <View style={styles.loyaltyBottomRow}>
              <AppText style={styles.loyaltyScore}>0</AppText>
              <View style={styles.crownShieldWrapper}>
                <FontAwesome5 name="crown" size={30} color="#F59E0B" />
              </View>
            </View>
          </TouchableOpacity>

          {/* Card 2: Mua sắm hoàn tiền */}
          <TouchableOpacity
            style={styles.cashbackCard}
            activeOpacity={0.85}
            onPress={() => setIsPromoModalVisible(true)}
          >
            <LinearGradient
              colors={['#FDF2F8', '#FCE7F3']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />

            {/* Top-Right Badge: HOÀN TỚI 50% */}
            <View style={styles.cashbackBadge}>
              <AppText style={styles.cashbackBadgeText}>HOÀN TỚI 50%</AppText>
            </View>

            <View style={styles.cashbackHeaderRow}>
              <AppText style={styles.cashbackTitle}>Mua sắm{'\n'}hoàn tiền</AppText>
              <Ionicons name="chevron-forward" size={15} color="#700F43" style={{ marginTop: 2 }} />
            </View>

            {/* Bottom-Right Brand Logos (Shopee, Lazada, TikTok) */}
            <View style={styles.cashbackLogosRow}>
              <View style={[styles.appLogoSquare, { backgroundColor: '#EA580C' }]}>
                <Ionicons name="bag-handle" size={14} color="#FFFFFF" />
              </View>

              <View style={[styles.appLogoSquare, { backgroundColor: '#1E1B4B' }]}>
                <AppText style={{ fontSize: 8, fontWeight: '900', color: '#F43F5E' }}>Laz</AppText>
              </View>

              <View style={[styles.appLogoSquare, { backgroundColor: '#000000', borderRadius: 13 }]}>
                <Ionicons name="musical-notes" size={13} color="#FFFFFF" />
              </View>
            </View>
          </TouchableOpacity>
        </View>

        {/* 4. SECTION: ĐẶC QUYỀN CỦA TÔI */}
        <View style={styles.sectionHeader}>
          <AppText style={styles.sectionTitle}>Đặc quyền của tôi</AppText>
          <TouchableOpacity style={styles.seeAllPill} activeOpacity={0.7}>
            <AppText style={styles.seeAllText}>Tất cả</AppText>
          </TouchableOpacity>
        </View>

        {/* Privilege Voucher Card */}
        <TouchableOpacity style={styles.voucherCard} activeOpacity={0.9}>
          <View style={styles.voucherTopRow}>
            {/* Left Promo Image Banner */}
            <Image
              source={{ uri: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&auto=format&fit=crop&q=80' }}
              style={styles.voucherImage}
            />

            {/* Middle & Right Details */}
            <View style={styles.voucherInfo}>
              <View style={styles.voucherBrandRow}>
                <View style={styles.miniMbStar}>
                  <AppText style={{ color: '#FFFFFF', fontSize: 9, fontWeight: '900' }}>★</AppText>
                </View>
                <AppText style={styles.voucherCategory}>Thẻ</AppText>

                <View style={{ flex: 1 }} />

                <View style={styles.badge99}>
                  <AppText style={styles.badge99Text}>99+</AppText>
                </View>
              </View>

              <AppText style={styles.voucherTitle} numberOfLines={2}>
                Giảm 20% phí trả góp
              </AppText>
            </View>
          </View>

          {/* Bottom Progress & Expiry Row */}
          <View style={styles.voucherBottomRow}>
            <AppText style={styles.voucherExpiry}>HSD: 31/08/2026</AppText>

            <View style={styles.voucherProgressContainer}>
              <AppText style={styles.progressLabel}>ĐÃ DÙNG 99%</AppText>
              <View style={styles.progressBarTrack}>
                <View style={styles.progressBarFill} />
              </View>
            </View>
          </View>
        </TouchableOpacity>

        {/* 5. SECTION: ƯU ĐÃI (HOT DEAL BANNER) */}
        <View style={[styles.sectionHeader, { marginTop: 24 }]}>
          <AppText style={styles.sectionTitle}>Ưu đãi</AppText>
        </View>

        {/* Hot Deal Banner Card */}
        <TouchableOpacity style={styles.hotDealCard} activeOpacity={0.9}>
          <LinearGradient
            colors={['#FCE7F3', '#FDF2F8', '#E9D5FF']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={StyleSheet.absoluteFill}
          />

          <HotDealGraphic />

          <View style={styles.hotDealCenterBox}>
            <AppText style={styles.hotDealWordHot}>HOT</AppText>
            <AppText style={styles.hotDealWordDeal}>DEAL</AppText>
          </View>
        </TouchableOpacity>
      </ScrollView>

      {/* 6. POPUP QUẢNG CÁO CASHBACK PLUS */}
      <Modal
        visible={isPromoModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setIsPromoModalVisible(false)}
      >
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            {/* Top Bar: Logo MB + Close X Button */}
            <View style={styles.modalTopRow}>
              <View style={styles.modalLogoRow}>
                <View style={styles.modalStarIcon}>
                  <AppText style={{ color: '#FFFFFF', fontSize: 13, fontWeight: '900' }}>★</AppText>
                </View>
                <AppText style={styles.modalLogoText}>MB</AppText>
              </View>

              <TouchableOpacity
                style={styles.modalCloseBtn}
                activeOpacity={0.7}
                onPress={() => setIsPromoModalVisible(false)}
              >
                <Ionicons name="close" size={18} color="#FFFFFF" />
              </TouchableOpacity>
            </View>

            {/* Hero Title & 3D Illustration Area */}
            <View style={styles.modalHeroRow}>
              <View style={styles.modalHeroLeft}>
                <AppText style={styles.cashbackPlusWord1}>CASHBACK</AppText>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <AppText style={styles.cashbackPlusWord2}>PLUS</AppText>
                  <AppText style={styles.cashbackPlusGreen}>+</AppText>
                </View>

                <View style={styles.mua1Nhan3Pill}>
                  <AppText style={styles.mua1Nhan3Text}>
                    MUA 1, NHẬN <AppText style={{ color: '#059669', fontWeight: '900' }}>3</AppText> LỢI ÍCH
                  </AppText>
                </View>
              </View>

              <CashbackHeroArt />
            </View>

            {/* 3 BENEFIT BLOCKS */}
            <View style={styles.benefitsContainer}>
              {/* BENEFIT 1: 100% ĐƯỢC HOÀN TIỀN */}
              <View style={styles.benefitBox1}>
                <View style={styles.benefit1HeaderRow}>
                  <View style={styles.numberBadgePink}>
                    <AppText style={styles.numberBadgeText}>1</AppText>
                  </View>
                  <AppText style={styles.benefit1Title}>100% ĐƯỢC HOÀN TIỀN</AppText>
                </View>

                <View style={styles.benefit1ContentRow}>
                  <View style={styles.benefit1LeftCol}>
                    <View style={styles.brandTagsRow}>
                      <View style={[styles.brandPill, { borderColor: '#FDBA74', backgroundColor: '#FFF7ED' }]}>
                        <Ionicons name="bag-handle" size={11} color="#EA580C" />
                        <View style={{ marginLeft: 3 }}>
                          <AppText style={{ fontSize: 7.5, fontWeight: '800', color: '#EA580C' }}>Shopee</AppText>
                          <AppText style={{ fontSize: 7, fontWeight: '700', color: '#EA580C' }}>đến 30%</AppText>
                        </View>
                      </View>

                      <View style={[styles.brandPill, { borderColor: '#CBD5E1', backgroundColor: '#F8FAFC' }]}>
                        <Ionicons name="musical-notes" size={11} color="#0F172A" />
                        <View style={{ marginLeft: 3 }}>
                          <AppText style={{ fontSize: 7.5, fontWeight: '800', color: '#0F172A' }}>TikTok Shop</AppText>
                          <AppText style={{ fontSize: 7, fontWeight: '700', color: '#0F172A' }}>đến 20%</AppText>
                        </View>
                      </View>
                    </View>

                    <View style={styles.otherBrandsRow}>
                      <Ionicons name="star" size={10} color="#D2519D" />
                      <AppText style={styles.otherBrandsText}> Hơn <AppText style={{ fontWeight: '800' }}>1000</AppText> thương hiệu khác</AppText>
                    </View>

                    <View style={styles.partnerLogosStrip}>
                      <AppText style={styles.partnerLogoSmall}>Trip.com</AppText>
                      <AppText style={[styles.partnerLogoSmall, { color: '#059669' }]}>agoda</AppText>
                      <AppText style={[styles.partnerLogoSmall, { color: '#1E1B4B' }]}>Lazada</AppText>
                      <AppText style={[styles.partnerLogoSmall, { color: '#EC4899' }]}>concung</AppText>
                      <AppText style={[styles.partnerLogoSmall, { color: '#D2519D' }]}>KidsPlaza</AppText>
                      <AppText style={[styles.partnerLogoSmall, { color: '#0F172A' }]}>Nike</AppText>
                      <AppText style={styles.partnerLogoSmall}>...</AppText>
                    </View>
                  </View>

                  <View style={styles.benefit1Art}>
                    <View style={styles.miniPhoneMock}>
                      <View style={styles.mini100Badge}>
                        <AppText style={{ color: '#FFFFFF', fontSize: 7, fontWeight: '900' }}>100%</AppText>
                      </View>
                      <Ionicons name="cart" size={18} color="#0284C7" />
                    </View>
                  </View>
                </View>
              </View>

              {/* BENEFIT 2: HOÀN THEO ĐƠN VỀ VÍ TIẾT KIỆM TIỀN LẺ */}
              <View style={styles.benefitBox2}>
                <View style={styles.benefitRowLeft}>
                  <View style={styles.numberBadgePlum}>
                    <AppText style={styles.numberBadgeText}>2</AppText>
                  </View>
                  <AppText style={styles.benefit2Title}>
                    HOÀN THEO ĐƠN{'\n'}VỀ VÍ TIẾT KIỆM TIỀN LẺ
                  </AppText>
                </View>

                <View style={styles.benefit2RightArt}>
                  <View style={styles.purpleWallet}>
                    <Ionicons name="wallet" size={18} color="#FFFFFF" />
                  </View>

                  <View style={styles.orderVerifiedTag}>
                    <AppText style={styles.orderVerifiedText}>Đơn hàng{'\n'}đã xác nhận</AppText>
                    <View style={styles.checkCirclePink}>
                      <Ionicons name="checkmark" size={9} color="#FFFFFF" />
                    </View>
                  </View>
                </View>
              </View>

              {/* BENEFIT 3: SINH LỜI TRÊN TIỀN HOÀN VỚI LÃI SUẤT CAO */}
              <View style={styles.benefitBox3}>
                <View style={styles.benefitRowLeft}>
                  <View style={styles.numberBadgeGreen}>
                    <AppText style={styles.numberBadgeText}>3</AppText>
                  </View>
                  <AppText style={styles.benefit3Title}>
                    SINH LỜI TRÊN{'\n'}TIỀN HOÀN VỚI{'\n'}LÃI SUẤT CAO
                  </AppText>
                </View>

                <View style={styles.benefit3RightArt}>
                  <MaterialCommunityIcons name="trending-up" size={28} color="#10B981" />

                  <View style={styles.interestShield}>
                    <AppText style={styles.interestShieldText}>LÃI SUẤT{'\n'}CAO</AppText>
                  </View>
                </View>
              </View>
            </View>
          </View>

          {/* Bottom Floating CTA Button */}
          <TouchableOpacity
            style={styles.modalCtaBtn}
            activeOpacity={0.85}
            onPress={() => setIsPromoModalVisible(false)}
          >
            <LinearGradient
              colors={['#D2519D', '#700F43']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={StyleSheet.absoluteFill}
            />
            <AppText style={styles.modalCtaText}>Mua sắm hoàn tiền ngay</AppText>
          </TouchableOpacity>
        </View>
      </Modal>

      {/* Slide-In Side Menu Drawer */}
      <SideMenuDrawer
        visible={isSideMenuVisible}
        onClose={() => setIsSideMenuVisible(false)}
        navigation={navigation}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  headerContainer: {
    paddingBottom: 14,
    borderBottomLeftRadius: 36,
    overflow: 'hidden',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 10,
    elevation: 8,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 6,
  },
  logoContainer: {
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
  beeAvatarContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  beeAvatarCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255, 255, 255, 0.25)',
    borderWidth: 1.5,
    borderColor: 'rgba(255, 255, 255, 0.6)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  headerIconBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 18,
    paddingBottom: 100,
  },
  pageTitle: {
    fontSize: 26,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: -0.5,
    marginBottom: 16,
  },
  twoCardsRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  loyaltyCard: {
    flex: 1,
    height: 110,
    borderRadius: 18,
    padding: 14,
    overflow: 'hidden',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 3,
  },
  cardHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  loyaltyHeaderTitle: {
    fontSize: 12,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: 0.3,
  },
  loyaltyBottomRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
  },
  loyaltyScore: {
    fontSize: 26,
    fontWeight: '900',
    color: '#700F43',
  },
  crownShieldWrapper: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: '#FEF3C7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cashbackCard: {
    flex: 1,
    height: 110,
    borderRadius: 18,
    padding: 14,
    overflow: 'hidden',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#FBCFE8',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 3,
    position: 'relative',
  },
  cashbackBadge: {
    position: 'absolute',
    top: 0,
    right: 0,
    backgroundColor: '#700F43',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderBottomLeftRadius: 10,
    borderTopRightRadius: 18,
  },
  cashbackBadgeText: {
    color: '#FFFFFF',
    fontSize: 9,
    fontWeight: '900',
    letterSpacing: 0.2,
  },
  cashbackHeaderRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    paddingRight: 60,
  },
  cashbackTitle: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#700F43',
    lineHeight: 18,
  },
  cashbackLogosRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 6,
  },
  appLogoSquare: {
    width: 26,
    height: 26,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 19,
    fontWeight: '800',
    color: '#700F43',
  },
  seeAllPill: {
    borderWidth: 1.5,
    borderColor: '#D2519D',
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 4,
  },
  seeAllText: {
    color: '#D2519D',
    fontSize: 13,
    fontWeight: '700',
  },
  voucherCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 14,
    borderWidth: 1,
    borderColor: '#FCE7F3',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  voucherTopRow: {
    flexDirection: 'row',
    gap: 12,
  },
  voucherImage: {
    width: 90,
    height: 60,
    borderRadius: 10,
    backgroundColor: '#FDF2F8',
  },
  voucherInfo: {
    flex: 1,
    justifyContent: 'center',
  },
  voucherBrandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    marginBottom: 4,
  },
  miniMbStar: {
    width: 16,
    height: 16,
    borderRadius: 4,
    backgroundColor: '#E11D48',
    justifyContent: 'center',
    alignItems: 'center',
  },
  voucherCategory: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#D2519D',
  },
  badge99: {
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 6,
    paddingHorizontal: 5,
    paddingVertical: 1,
  },
  badge99Text: {
    fontSize: 10,
    fontWeight: '700',
    color: '#64748B',
  },
  voucherTitle: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  voucherBottomRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 14,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  voucherExpiry: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  voucherProgressContainer: {
    alignItems: 'flex-end',
    width: 140,
  },
  progressLabel: {
    fontSize: 10.5,
    fontWeight: '800',
    color: '#D97706',
    marginBottom: 4,
  },
  progressBarTrack: {
    width: '100%',
    height: 5,
    backgroundColor: '#FEF3C7',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressBarFill: {
    width: '99%',
    height: '100%',
    backgroundColor: '#F59E0B',
    borderRadius: 3,
  },
  hotDealCard: {
    height: 140,
    borderRadius: 18,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 10,
    elevation: 4,
  },
  hotDealCenterBox: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  hotDealWordHot: {
    fontSize: 18,
    fontWeight: '900',
    color: '#FFFFFF',
    letterSpacing: 1,
    lineHeight: 20,
    textShadowColor: 'rgba(0, 0, 0, 0.4)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  hotDealWordDeal: {
    fontSize: 16,
    fontWeight: '900',
    color: '#FDE047',
    letterSpacing: 1,
    lineHeight: 18,
    textShadowColor: 'rgba(0, 0, 0, 0.4)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },

  // ===== POPUP QUẢNG CÁO CASHBACK PLUS STYLES =====
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(59, 7, 36, 0.75)',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  modalCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 15,
  },
  modalTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  modalLogoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  modalStarIcon: {
    width: 22,
    height: 22,
    borderRadius: 5,
    backgroundColor: '#E11D48',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalLogoText: {
    fontSize: 18,
    fontWeight: '900',
    color: '#700F43',
    letterSpacing: 0.5,
  },
  modalCloseBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#D2519D',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalHeroRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  modalHeroLeft: {
    flex: 1,
  },
  cashbackPlusWord1: {
    fontSize: 22,
    fontWeight: '900',
    color: '#700F43',
    letterSpacing: -0.5,
  },
  cashbackPlusWord2: {
    fontSize: 28,
    fontWeight: '900',
    color: '#D2519D',
    letterSpacing: -0.5,
  },
  cashbackPlusGreen: {
    fontSize: 28,
    fontWeight: '900',
    color: '#10B981',
    marginLeft: 2,
  },
  mua1Nhan3Pill: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    borderRadius: 20,
    paddingHorizontal: 8,
    paddingVertical: 3,
    alignSelf: 'flex-start',
    marginTop: 4,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 1,
  },
  mua1Nhan3Text: {
    fontSize: 10.5,
    fontWeight: '800',
    color: '#700F43',
  },
  benefitsContainer: {
    gap: 8,
  },
  benefitBox1: {
    backgroundColor: '#FDF2F8',
    borderRadius: 14,
    padding: 10,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  benefit1HeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 6,
  },
  numberBadgePink: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#D2519D',
    justifyContent: 'center',
    alignItems: 'center',
  },
  numberBadgePlum: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#700F43',
    justifyContent: 'center',
    alignItems: 'center',
  },
  numberBadgeGreen: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#059669',
    justifyContent: 'center',
    alignItems: 'center',
  },
  numberBadgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '900',
  },
  benefit1Title: {
    fontSize: 13.5,
    fontWeight: '900',
    color: '#700F43',
  },
  benefit1ContentRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  benefit1LeftCol: {
    flex: 1,
  },
  brandTagsRow: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: 6,
  },
  brandPill: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 5,
    paddingVertical: 2,
  },
  otherBrandsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  otherBrandsText: {
    fontSize: 9,
    color: '#D2519D',
    fontWeight: '600',
  },
  partnerLogosStrip: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 4,
  },
  partnerLogoSmall: {
    fontSize: 7.5,
    fontWeight: '700',
    color: '#64748B',
  },
  benefit1Art: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 50,
  },
  miniPhoneMock: {
    width: 44,
    height: 44,
    borderRadius: 10,
    backgroundColor: '#FFFFFF',
    borderWidth: 1.2,
    borderColor: '#FBCFE8',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  mini100Badge: {
    position: 'absolute',
    top: -5,
    left: -8,
    backgroundColor: '#10B981',
    borderRadius: 4,
    paddingHorizontal: 3,
    paddingVertical: 1,
  },
  benefitBox2: {
    backgroundColor: '#FDF4FF',
    borderRadius: 14,
    padding: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#F5D0FE',
  },
  benefitRowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  benefit2Title: {
    fontSize: 12.5,
    fontWeight: '900',
    color: '#700F43',
    lineHeight: 16,
  },
  benefit2RightArt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  purpleWallet: {
    width: 34,
    height: 28,
    borderRadius: 8,
    backgroundColor: '#700F43',
    justifyContent: 'center',
    alignItems: 'center',
  },
  orderVerifiedTag: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    paddingHorizontal: 6,
    paddingVertical: 3,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  orderVerifiedText: {
    fontSize: 7.5,
    fontWeight: '800',
    color: '#700F43',
    lineHeight: 9,
  },
  checkCirclePink: {
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: '#D2519D',
    justifyContent: 'center',
    alignItems: 'center',
  },
  benefitBox3: {
    backgroundColor: '#F0FDF4',
    borderRadius: 14,
    padding: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#DCFCE7',
  },
  benefit3Title: {
    fontSize: 12.5,
    fontWeight: '900',
    color: '#700F43',
    lineHeight: 16,
  },
  benefit3RightArt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  interestShield: {
    backgroundColor: '#700F43',
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 4,
  },
  interestShieldText: {
    color: '#FFFFFF',
    fontSize: 7.5,
    fontWeight: '900',
    textAlign: 'center',
    lineHeight: 9,
  },
  modalCtaBtn: {
    width: '100%',
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 12,
    overflow: 'hidden',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 6,
  },
  modalCtaText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '800',
  },
});
