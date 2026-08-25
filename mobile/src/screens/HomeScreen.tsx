import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  StyleSheet,
  Image,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Animated,
  FlatList,
  Platform,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import Svg, { Path, Circle, Rect, Defs, LinearGradient as SvgGradient, Stop } from 'react-native-svg';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Shadows, Typography, Radius } from '../theme';
import { AppText } from '../components/typography/AppText';
import { SideMenuDrawer } from '../components/SideMenuDrawer';
import { useApp } from '../context/AppContext';

const { width } = Dimensions.get('window');
const ITEM_WIDTH = Math.round(width * 0.78);
const ITEM_GAP = 8; // Khoảng cách đồng đều 8px giữa các thẻ
const SNAP_INTERVAL = ITEM_WIDTH + ITEM_GAP;
const SIDE_SPACER = (width - ITEM_WIDTH) / 2;

// Kích thước thẻ số dư vuốt ngang
const BALANCE_CARD_WIDTH = Math.round(width * 0.60); // 👈 Chỉnh chiều rộng thẻ số dư (tăng/giảm % màn hình, vd: 0.58, 0.60, 0.65)
const BALANCE_CARD_GAP = 10;                         // 👈 Khoảng cách giữa thẻ 1 và thẻ 2 khi vuốt ngang
const BALANCE_SNAP_INTERVAL = BALANCE_CARD_WIDTH + BALANCE_CARD_GAP;

// Official Vector Icons for Quick Actions (Lotus Pink Theme)
function MBTransferIcon({ size = 28, color = '#D2519D' }: { size?: number; color?: string }) {
  return <MaterialCommunityIcons name="bank-transfer" size={size} color={color} />;
}

function MBPhoneIcon({ size = 28, color = '#D2519D' }: { size?: number; color?: string }) {
  return <Ionicons name="phone-portrait-outline" size={size} color={color} />;
}

function MBPiggyIcon({ size = 28, color = '#D2519D' }: { size?: number; color?: string }) {
  return <MaterialCommunityIcons name="piggy-bank-outline" size={size} color={color} />;
}

function MBCoinsIcon({ size = 28, color = '#D2519D' }: { size?: number; color?: string }) {
  return <MaterialCommunityIcons name="hand-coin-outline" size={size} color={color} />;
}

// Shield Check Icon (Huy hiệu bảo mật / xác thực)
function MBShieldCheckIcon({ size = 22 }: { size?: number }) {
  return <MaterialCommunityIcons name="shield-check" size={size} color="#10B981" />;
}

// Crown Icon cho Badge Basic
function MBCrownIcon({ size = 14 }: { size?: number }) {
  return <FontAwesome5 name="crown" size={size} color="#94A3B8" />;
}

// Quick Actions Data with exact badges
const QUICK_ACTIONS = [
  { id: '1', component: MBTransferIcon, title: 'Chuyển tiền', badge: null, badgeColor: null },
  { id: '2', component: MBPhoneIcon, title: 'Nạp tiền\nđiện thoại', badge: null, badgeColor: null },
  { id: '3', component: MBPiggyIcon, title: 'Tiền gửi', badge: '🧧 TÀI LỘC', badgeColor: '#E11D48' },
  { id: '4', component: MBCoinsIcon, title: 'Vay nhanh', badge: 'NHƯ GIÓ 💨', badgeColor: '#FDF2F8', badgeTextColor: '#D2519D' },
];

// 6 Banners đồng bộ kích thước & layout chuẩn đẹp 100%
const BASE_CAROUSEL_DATA = [
  {
    id: 'b1',
    type: 'blue',
    brand: 'MB',
    badge: 'TÍCH LŨY 24/7',
    titleYellow: 'TIẾT KIỆM',
    titleRed: 'SINH LỜI',
    subtitle: 'Lãi suất hấp dẫn mỗi ngày từ 1K',
    cta: 'GỬI TIỀN NGAY',
    colorStart: '#1E1B4B',
    colorEnd: '#312E81',
    tags: [
      { text: '0.1%', color: '#FDD349', textColor: '#1A1A1A', top: 25, right: 20, rotate: '12deg' },
    ],
    showCarMascot: false,
  },
  {
    id: 'b2',
    type: 'live',
    brand: 'MB',
    badge: 'LIVESTREAM ▷ 26.08 19:30-21:30',
    titleYellow: 'SIÊU THỊ SỐ',
    titleRed: 'LÊN LIVE',
    subtitle: 'Mở quẩy deal vi vu 2/9',
    cta: 'ĐĂNG KÝ NGAY',
    colorStart: '#0B2E73',
    colorEnd: '#0A1AD2',
    tags: [
      { text: '50K', color: '#FDD349', textColor: '#1A1A1A', top: 24, right: 16, rotate: '12deg' },
      { text: '50%', color: '#FDD349', textColor: '#1A1A1A', top: 60, right: 26, rotate: '-10deg' },
      { text: '500K', color: '#FDD349', textColor: '#1A1A1A', top: 98, right: 14, rotate: '15deg' },
    ],
    showCarMascot: true,
  },
  {
    id: 'b3',
    type: 'orange',
    brand: 'MB',
    badge: 'ƯU ĐÃI THẺ MB',
    titleYellow: 'HOÀN 500K',
    titleRed: 'MỞ THẺ',
    subtitle: 'Miễn phí thường niên trọn đời',
    cta: 'MỞ THẺ NGAY',
    colorStart: '#EA580C',
    colorEnd: '#C2410C',
    tags: [
      { text: 'HOT', color: '#FDE047', textColor: '#1A1A1A', top: 25, right: 20, rotate: '-15deg' },
    ],
    showCarMascot: false,
  },
  {
    id: 'b4',
    type: 'green',
    brand: 'MB Ageas',
    badge: 'BẢO VỆ TOÀN DIỆN',
    titleYellow: 'BẢO HIỂM',
    titleRed: 'BÌNH AN',
    subtitle: 'Quyền lợi y tế lên đến 1 tỷ VNĐ',
    cta: 'TÌM HIỂU NGAY',
    colorStart: '#064E3B',
    colorEnd: '#047857',
    tags: [
      { text: '1 TỶ', color: '#34D399', textColor: '#064E3B', top: 25, right: 20, rotate: '10deg' },
    ],
    showCarMascot: false,
  },
  {
    id: 'b5',
    type: 'purple',
    brand: 'MBS',
    badge: 'CHỨNG KHOÁN MBS',
    titleYellow: 'MIỄN PHÍ',
    titleRed: 'GIAO DỊCH',
    subtitle: 'Khởi đầu đầu tư chỉ từ 10.000đ',
    cta: 'MỞ TÀI KHOẢN',
    colorStart: '#4C1D95',
    colorEnd: '#6D28D9',
    tags: [
      { text: 'FREE', color: '#FDE047', textColor: '#1A1A1A', top: 25, right: 20, rotate: '-12deg' },
    ],
    showCarMascot: false,
  },
  {
    id: 'b6',
    type: 'cyan',
    brand: 'MB Vay',
    badge: 'DUYỆT TRONG 1 PHÚT',
    titleYellow: 'VAY SIÊU TỐC',
    titleRed: '100 TRIỆU',
    subtitle: 'Lãi suất ưu đãi không thế chấp',
    cta: 'VAY NGAY',
    colorStart: '#0C4A6E',
    colorEnd: '#0284C7',
    tags: [
      { text: '1 PHÚT', color: '#38BDF8', textColor: '#0C4A6E', top: 25, right: 20, rotate: '15deg' },
    ],
    showCarMascot: false,
  },
];

// Tạo danh sách lặp tuần hoàn vô tận (Infinite Looping Array)
const LOOP_MULTIPLIER = 12;
const CAROUSEL_DATA = Array.from({ length: LOOP_MULTIPLIER }).flatMap((_, loopIdx) =>
  BASE_CAROUSEL_DATA.map((item, itemIdx) => ({
    ...item,
    uniqueId: `loop-${loopIdx}-${item.id}-${itemIdx}`,
  }))
);
const TOTAL_CAROUSEL_ITEMS = CAROUSEL_DATA.length;
const INITIAL_CAROUSEL_INDEX = BASE_CAROUSEL_DATA.length * 5; // Bắt đầu ở giữa dải lặp

// Grid 8 services matching exact screenshot
const SERVICES = [
  { id: '1', title: 'Vua Xổ Số', iconBg: '#FFF1F2', iconColor: '#E11D48', icon: 'ticket', badgeText: '9' },
  { id: '2', title: 'Vé số\nVietlott', iconBg: '#EF4444', iconColor: '#FFFFFF', icon: 'tag', customLogo: 'SMS' },
  { id: '3', title: 'Data 4G/\nNạp tiền', iconBg: '#F0FDF4', iconColor: '#059669', icon: 'wifi', multiLogo: true },
  { id: '4', title: 'Vé Máy Bay\nSố', iconBg: '#06B6D4', iconColor: '#FDE047', icon: 'plane' },
  { id: '5', title: 'Vé Máy Bay', iconBg: '#FFFFFF', iconColor: '#0284C7', icon: 'plane' },
  { id: '6', title: 'Data Viettel', iconBg: '#581C87', iconColor: '#FFFFFF', icon: 'zap', customLogo: '4G' },
  { id: '7', title: 'Tử Vi', iconBg: '#1E1B4B', iconColor: '#A5B4FC', icon: 'star', isYinYang: true },
  { id: '8', title: 'Xem thêm', iconBg: '#FFFFFF', iconColor: Colors.primary, icon: 'grid', isGrid: true },
];

export default function HomeScreen({ navigation }: any) {
  const { user, wallet, refreshBalance, isBalanceLoading } = useApp();
  const [balanceVisible, setBalanceVisible] = useState(true);
  const [isSideMenuVisible, setIsSideMenuVisible] = useState(false); // Modal menu 3 gạch
  const [activeIndex, setActiveIndex] = useState(INITIAL_CAROUSEL_INDEX);
  const scrollX = useRef(new Animated.Value(INITIAL_CAROUSEL_INDEX * SNAP_INTERVAL)).current;
  const scrollY = useRef(new Animated.Value(0)).current; // Theo dõi vị trí cuộn dọc
  const flatListRef = useRef<FlatList>(null);
  const isUserInteracting = useRef(false);
  const currentIndexRef = useRef(INITIAL_CAROUSEL_INDEX);

  // Hiệu ứng xuất hiện thanh nổi "Dán chuyển tiền AI" khi kéo cuộn xuống dưới
  const stickyHeaderOpacity = scrollY.interpolate({
    inputRange: [40, 85],
    outputRange: [0, 1],
    extrapolate: 'clamp',
  });

  const stickyHeaderTranslateY = scrollY.interpolate({
    inputRange: [40, 85],
    outputRange: [-25, 0],
    extrapolate: 'clamp',
  });

  // Tự động làm mờ và ẩn lớp nền hồng phía trên khi kéo cuộn xuống
  const headerBgOpacity = scrollY.interpolate({
    inputRange: [0, 90],
    outputRange: [1, 0],
    extrapolate: 'clamp',
  });

  const headerBgTranslateY = scrollY.interpolate({
    inputRange: [0, 90],
    outputRange: [0, -80],
    extrapolate: 'clamp',
  });

  useEffect(() => {
    // Cuộn tới vị trí giữa ban đầu và thiết lập scrollX chuẩn xác
    setTimeout(() => {
      flatListRef.current?.scrollToOffset({
        offset: INITIAL_CAROUSEL_INDEX * SNAP_INTERVAL,
        animated: false,
      });
      scrollX.setValue(INITIAL_CAROUSEL_INDEX * SNAP_INTERVAL);
      currentIndexRef.current = INITIAL_CAROUSEL_INDEX;
    }, 100);

    // Vòng lặp chuyển động tự động vô tận không bao giờ đứt gãy
    const timer = setInterval(() => {
      if (!isUserInteracting.current && flatListRef.current) {
        let nextIndex = currentIndexRef.current + 1;

        // Khi gần chạm đuôi, tự động dịch chuyển âm thầm về giữa mượt mà
        if (nextIndex >= TOTAL_CAROUSEL_ITEMS - BASE_CAROUSEL_DATA.length * 2) {
          const resetIndex = BASE_CAROUSEL_DATA.length * 5;
          flatListRef.current.scrollToOffset({
            offset: resetIndex * SNAP_INTERVAL,
            animated: false,
          });
          scrollX.setValue(resetIndex * SNAP_INTERVAL);
          currentIndexRef.current = resetIndex;
          nextIndex = resetIndex + 1;
        }

        flatListRef.current.scrollToOffset({
          offset: nextIndex * SNAP_INTERVAL,
          animated: true,
        });
        currentIndexRef.current = nextIndex;
        setActiveIndex(nextIndex);
      }
    }, 3500);

    return () => clearInterval(timer);
  }, []);

  const renderBannerItem = ({ item, index }: { item: any; index: number }) => {
    const inputRange = [
      (index - 1) * SNAP_INTERVAL,
      index * SNAP_INTERVAL,
      (index + 1) * SNAP_INTERVAL,
    ];
    const scale = scrollX.interpolate({
      inputRange,
      outputRange: [0.86, 1.0, 0.86], // Thẻ giữa to hơn chuẩn 1.0, 2 thẻ bên thu nhỏ 0.86
      extrapolate: 'clamp',
    });
    const opacity = scrollX.interpolate({
      inputRange,
      outputRange: [0.65, 1.0, 0.65], // Thẻ bên mờ nhẹ 65% để làm nổi bật thẻ giữa
      extrapolate: 'clamp',
    });

    return (
      <Animated.View
        style={[
          styles.bannerItemWrapper,
          {
            width: ITEM_WIDTH,
            transform: [{ scale }],
            opacity,
            marginHorizontal: ITEM_GAP / 2, // Đồng bộ khoảng cách 2 bên chuẩn 8px
          },
        ]}
      >
        <View style={styles.bannerItem}>
          <LinearGradient
            colors={[item.colorStart, item.colorEnd]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.bannerBackground}
          >
            {/* Top Row: Mini Brand Logo (20px) + Livestream / Promo Badge */}
            <View style={styles.bannerTopRow}>
              <View style={styles.bannerBrandLogo}>
                <View style={styles.miniStar}>
                  <AppText style={styles.miniStarText}>★</AppText>
                </View>
                <AppText style={styles.bannerBrandText}>{item.brand}</AppText>
              </View>

              {item.badge && (
                <View style={styles.bannerBadge}>
                  <AppIcon name="play" size="xs" color={Colors.white} />
                  <AppText style={styles.bannerBadgeText}>{item.badge}</AppText>
                </View>
              )}
            </View>

            {/* 2-line 3D Banner Title */}
            <View style={styles.bannerTextContent}>
              {item.titleYellow && (
                <View style={styles.title3DBoxYellow}>
                  <AppText style={styles.bannerTitleYellow}>{item.titleYellow}</AppText>
                </View>
              )}
              {item.titleRed && (
                <View style={styles.title3DBoxRed}>
                  <AppText style={styles.bannerTitleRed}>{item.titleRed}</AppText>
                </View>
              )}
              <AppText style={styles.bannerSubtitle} numberOfLines={1}>{item.subtitle}</AppText>
            </View>

            {/* Floating Confetti / Voucher Tags */}
            {item.tags && item.tags.map((tag: any, tIdx: number) => (
              <View
                key={tIdx}
                style={[
                  styles.floatingTag,
                  {
                    top: tag.top,
                    right: tag.right,
                    backgroundColor: tag.color,
                    transform: [{ rotate: tag.rotate }],
                  },
                ]}
              >
                <AppText style={[styles.floatingTagText, { color: tag.textColor }]}>
                  {tag.text}
                </AppText>
              </View>
            ))}

            {/* Mascot Graphic at Right Bottom */}
            {item.showCarMascot && (
              <View style={styles.mascotBleedContainer}>
                <View style={styles.carMascotWrapper}>
                  {/* Bee mascot on yellow car */}
                  <View style={styles.beeHead}>
                    <AppText style={{ fontSize: 24 }}>🐝</AppText>
                    <View style={styles.flagIcon}>
                      <AppText style={{ fontSize: 10 }}>🇻🇳</AppText>
                    </View>
                  </View>
                  <View style={styles.yellowCar}>
                    <AppText style={{ fontSize: 26 }}>🚗</AppText>
                  </View>
                </View>
              </View>
            )}

            {/* Bottom CTA Pill Button */}
            {item.cta && (
              <TouchableOpacity style={styles.ctaPill} activeOpacity={0.8}>
                <AppText style={styles.ctaPillText}>{item.cta}</AppText>
              </TouchableOpacity>
            )}
          </LinearGradient>
        </View>
      </Animated.View>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent />

      {/* STICKY FLOATING TOP BAR (Chỉ hiện khi cuộn xuống dưới, bo cong sâu bên TRÁI) */}
      <Animated.View
        style={[
          styles.stickyHeaderContainer,
          {
            opacity: stickyHeaderOpacity,
            transform: [{ translateY: stickyHeaderTranslateY }],
          },
        ]}
        pointerEvents="box-none"
      >
        <View style={styles.stickyHeaderWrapper}>
          <LinearGradient
            colors={['#E4ACB2', '#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={StyleSheet.absoluteFill}
          />
          {/* Vùng phát quang uốn lượn kính mờ ở góc dưới bên trái */}
          <View style={styles.stickyLeftAura} />

          <SafeAreaView edges={['top']}>
            <View style={styles.stickyHeaderContent}>
              {/* 1. Ô Dán chuyển tiền AI dạng viên thuốc */}
              <TouchableOpacity
                style={styles.stickySearchPill}
                activeOpacity={0.85}
                onPress={() => navigation.navigate('Search')}
              >
                <AppText style={styles.stickySearchText}>Dán chuyển tiền AI</AppText>
              </TouchableOpacity>

              {/* 2. Cụm Icon: Chuông 🔔 + 3 Gạch ☰ */}
              <View style={styles.stickyHeaderActions}>
                <TouchableOpacity
                  style={styles.glassHeaderBtn}
                  activeOpacity={0.7}
                  onPress={() => navigation.navigate('Notifications')}
                >
                  <AppIcon name="notification" size="sm" color={Colors.white} />
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.glassHeaderBtn}
                  activeOpacity={0.7}
                  onPress={() => setIsSideMenuVisible(true)}
                >
                  <AppIcon name="menu" size="sm" color={Colors.white} />
                </TouchableOpacity>
              </View>
            </View>
          </SafeAreaView>
        </View>
      </Animated.View>

      {/* 3D Header Background with Lotus Pink Aura capsules (Tự động ẩn đi khi kéo cuộn xuống) */}
      <Animated.View
        style={[
          styles.headerBackground,
          {
            opacity: headerBgOpacity,
            transform: [{ translateY: headerBgTranslateY }],
          },
        ]}
      >
        <LinearGradient
          colors={['#E4ACB2', '#D2519D', '#700F43']}
          start={{ x: 0, y: 0 }}
          end={{ x: 0.8, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        {/* Floating 3D capsule shapes */}
        <View style={styles.capsuleShape1} />
        <View style={styles.capsuleShape2} />
        <View style={styles.auraGlow} />
      </Animated.View>

      <SafeAreaView style={{ flex: 1 }} edges={['top']}>
        {/* Top Navigation Header (Cao ~58px, Logo trái, 3 icon phải gap 16px) */}
        <View style={styles.headerRow}>
          {/* Logo MB with Star */}
          <View style={styles.logoContainer}>
            <View style={styles.starIconWrapper}>
              <AppText style={styles.starText}>★</AppText>
            </View>
            <AppText style={styles.logoText}>MB</AppText>
          </View>
          
          {/* 3 Right Action Icons (Gap: 16px, kích thước 22-24px) */}
          <View style={styles.headerActions}>
            {/* Search Icon with mic/dot inside */}
            <TouchableOpacity style={styles.glassHeaderBtn} activeOpacity={0.7} onPress={() => navigation.navigate('Search')}>
              <Svg width={22} height={22} viewBox="0 0 24 24" fill="none">
                <Circle cx="11" cy="11" r="6.5" stroke="#FFFFFF" strokeWidth="2" />
                <Path d="M16 16l4.5 4.5" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" />
                <Circle cx="11" cy="11" r="1.5" fill="#FDF2F8" />
              </Svg>
            </TouchableOpacity>

            {/* Notification Bell */}
            <TouchableOpacity
              style={styles.glassHeaderBtn}
              activeOpacity={0.7}
              onPress={() => navigation.navigate('Notifications')}
            >
              <AppIcon name="notification" size="sm" color={Colors.white} />
            </TouchableOpacity>

            {/* Hamburger Menu 3 gạch */}
            <TouchableOpacity
              style={styles.glassHeaderBtn}
              activeOpacity={0.7}
              onPress={() => setIsSideMenuVisible(true)}
            >
              <AppIcon name="menu" size="sm" color={Colors.white} />
            </TouchableOpacity>
          </View>
        </View>

        <Animated.ScrollView
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.scrollContent}
          onScroll={Animated.event(
            [{ nativeEvent: { contentOffset: { y: scrollY } } }],
            { useNativeDriver: true }
          )}
          scrollEventThrottle={16}
          refreshControl={
            <RefreshControl
              refreshing={isBalanceLoading}
              onRefresh={refreshBalance}
              tintColor="#D2519D"
              colors={['#D2519D', '#700F43']}
            />
          }
        >

          {/* Balance & Avatar Section (Nổi trên header, hỗ trợ vuốt ngang xem thẻ kế bên) */}
          <View style={styles.balanceSection}>
            <View style={styles.balanceRow}>

              {/* Left Column: Avatar (52px, viền trắng 2px, check xanh) + Badge Basic */}
              <View style={styles.avatarColumn}>
                <View style={styles.avatarWrapper}>
                  <Image source={{ uri: 'https://i.pravatar.cc/150?img=11' }} style={styles.avatar} />
                  {/* Verified Shield Badge */}
                  <View style={styles.verifiedShield}>
                    <AppIcon name="check" size="xs" color={Colors.white} />
                  </View>
                </View>

                {/* Badge "Basic": Pill trắng nhỏ dưới avatar, icon giỏ hàng 12px + chữ 11px */}
                <View style={styles.basicBadge}>
                  <AppIcon name="shoppingBag" size="xs" color="#475569" />
                  <AppText style={styles.basicBadgeText}>Basic</AppText>
                </View>
                
                {/* User Name below badge */}
                <AppText style={{ color: Colors.white, fontSize: 12, fontWeight: 'bold', marginTop: 4 }}>
                  {user?.name ? user.name.split(' ').pop() : 'Bạn'}
                </AppText>
              </View>

              {/* Right Column: Horizontal Swipeable Balance Cards List (Kéo vuốt ngang mượt mà) */}
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                decelerationRate="fast"
                snapToInterval={BALANCE_SNAP_INTERVAL}
                contentContainerStyle={styles.balanceScrollContent}
                style={styles.balanceScrollList}
              >
                {/* CARD 1: Tổng số dư VND (Tone Hồng Sen Đậm) */}
                <View style={[styles.balanceCardWrapper, { width: BALANCE_CARD_WIDTH, marginRight: BALANCE_CARD_GAP }]}>
                  <LinearGradient
                    colors={['rgba(228, 172, 178, 0.95)', 'rgba(210, 81, 157, 0.95)', 'rgba(112, 15, 67, 0.98)']}
                    style={styles.balanceCard}
                  >
                    {/* Dòng 1: Label "Tổng số dư VND" + chevron > + icon con mắt */}
                    <View style={styles.balanceHeader}>
                      <AppText style={styles.balanceTitle}>Tổng số dư VND</AppText>
                      <AppIcon name="chevronRight" size="xs" color="rgba(255,255,255,0.9)" />
                      <View style={{ flex: 1 }} />
                      <TouchableOpacity
                        onPress={() => setBalanceVisible(!balanceVisible)}
                        hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
                        style={styles.eyeToggleBtn}
                      >
                        <AppIcon name={balanceVisible ? "eyeOff" : "eye"} size="sm" color="#FDF2F8" />
                      </TouchableOpacity>
                    </View>

                    {/* Dòng 2: Số dư lớn + đơn vị "VND" */}
                    <View style={styles.amountRow}>
                      <AppText style={styles.amountNumber}>
                        {balanceVisible 
                          ? (wallet?.balance?.toLocaleString('vi-VN') || '0')
                          : '*** ***'}
                      </AppText>
                      <AppText style={styles.amountCurrency}> {wallet?.currency || 'VND'}</AppText>
                    </View>

                    {/* Dòng 3: Link "SINH LỜI MỖI NGÀY" + chevron > */}
                    <TouchableOpacity style={styles.profitStrip} activeOpacity={0.8}>
                      <AppText style={styles.profitText}>SINH LỜI MỖI NGÀY</AppText>
                      <AppIcon name="chevronRight" size="xs" color="#FDF2F8" />
                    </TouchableOpacity>
                  </LinearGradient>
                </View>

                {/* CARD 2: Thẻ MB Visa (Tone Hồng Sen Sẫm) */}
                <View style={[styles.balanceCardWrapper, { width: BALANCE_CARD_WIDTH }]}>
                  <LinearGradient
                    colors={['rgba(210, 81, 157, 0.95)', 'rgba(157, 23, 100, 0.95)', 'rgba(80, 7, 43, 0.98)']}
                    style={styles.balanceCard}
                  >
                    {/* Dòng 1: Label "Thẻ MB Hi Visa" + chevron > + icon thẻ */}
                    <View style={styles.balanceHeader}>
                      <AppText style={styles.balanceTitle}>Thẻ MB Hi Visa</AppText>
                      <AppIcon name="chevronRight" size="xs" color="rgba(255,255,255,0.9)" />
                      <View style={{ flex: 1 }} />
                      <AppIcon name="card" size="xs" color="#FDF2F8" />
                    </View>

                    {/* Dòng 2: Hạn mức / Số dư thẻ */}
                    <View style={styles.amountRow}>
                      <AppText style={styles.amountNumber}>
                        {balanceVisible ? '50,000,000' : '*** ***'}
                      </AppText>
                      <AppText style={styles.amountCurrency}> VND</AppText>
                    </View>

                    {/* Dòng 3: Link "QUẢN LÝ THẺ & HẠN MỨC" + chevron > */}
                    <TouchableOpacity style={styles.profitStrip} activeOpacity={0.8}>
                      <AppText style={styles.profitText}>QUẢN LÝ THẺ & HẠN MỨC</AppText>
                      <AppIcon name="chevronRight" size="xs" color="#FDF2F8" />
                    </TouchableOpacity>
                  </LinearGradient>
                </View>
              </ScrollView>
            </View>
          </View>

          {/* MAIN FULL-WIDTH WHITE BODY CONTAINER (Bo cong đỉnh 32px, chứa 4 mục, carousel và dịch vụ) */}
          <View style={styles.whiteBodyContainer}>
            {/* 4 Quick Actions Row */}
            <View style={styles.quickActionsRow}>
              {QUICK_ACTIONS.map((item, index) => {
                const IconComp = item.component;
                return (
                  <TouchableOpacity
                    key={index}
                    style={styles.actionItem}
                    activeOpacity={0.8}
                    onPress={() => {
                      if (item.id === '1') navigation.navigate('Transfer');
                      else if (item.id === '2') navigation.navigate('PhoneRecharge');
                      else if (item.id === '3') navigation.navigate('Deposit');
                      else if (item.id === '4') navigation.navigate('Deposit');
                    }}
                  >
                    {/* Icon Container with relative position for the badge */}
                    <View style={styles.actionIconContainer}>
                      <View style={styles.actionIconBg}>
                        <IconComp size={28} color="#D2519D" />
                      </View>

                      {/* Badges positioned at top: -8, right: -10 */}
                      {item.badge && (
                        <View
                          style={[
                            styles.badge,
                            item.id === '4' ? styles.badgeNhuGio : styles.badgeTaiLoc,
                          ]}
                        >
                          <AppText
                            style={[
                              styles.badgeText,
                              item.id === '4' ? styles.badgeTextNhuGio : styles.badgeTextTaiLoc,
                            ]}
                          >
                            {item.badge}
                          </AppText>
                        </View>
                      )}
                    </View>

                    {/* Text below icon */}
                    <AppText style={styles.actionTitle} numberOfLines={2}>
                      {item.title}
                    </AppText>
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Center Red Round Chevrons Down Expand Button */}
            <View style={styles.expandButtonWrapper}>
              <TouchableOpacity style={styles.expandButton} activeOpacity={0.8}>
                <Svg width={14} height={14} viewBox="0 0 24 24" fill="none">
                  <Path
                    d="M7 8l5 5 5-5M7 14l5 5 5-5"
                    stroke="#FFFFFF"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </Svg>
              </TouchableOpacity>
            </View>

            {/* Banner Carousel (6 Banners chạy vòng lặp vô tận không đứt gãy) */}
            <View style={styles.carouselContainer}>
              <Animated.FlatList
                ref={flatListRef}
                data={CAROUSEL_DATA}
                keyExtractor={(item: any) => item.uniqueId}
                horizontal
                showsHorizontalScrollIndicator={false}
                snapToInterval={SNAP_INTERVAL}
                decelerationRate="fast"
                bounces={true}
                getItemLayout={(_, index) => ({
                  length: SNAP_INTERVAL,
                  offset: SNAP_INTERVAL * index,
                  index,
                })}
                contentContainerStyle={{
                  paddingHorizontal: SIDE_SPACER - ITEM_GAP / 2,
                }}
                onScrollBeginDrag={() => { isUserInteracting.current = true; }}
                onScrollEndDrag={() => { isUserInteracting.current = false; }}
                onMomentumScrollEnd={(e) => {
                  const rawIdx = Math.round(e.nativeEvent.contentOffset.x / SNAP_INTERVAL);
                  currentIndexRef.current = rawIdx;
                  setActiveIndex(rawIdx);
                  isUserInteracting.current = false;

                  // Tự động căn vị trí về giữa dải lặp nếu người dùng vuốt về quá gần mép
                  if (rawIdx < BASE_CAROUSEL_DATA.length * 2 || rawIdx >= TOTAL_CAROUSEL_ITEMS - BASE_CAROUSEL_DATA.length * 2) {
                    const normalizedIdx = (rawIdx % BASE_CAROUSEL_DATA.length) + BASE_CAROUSEL_DATA.length * 5;
                    flatListRef.current?.scrollToOffset({
                      offset: normalizedIdx * SNAP_INTERVAL,
                      animated: false,
                    });
                    scrollX.setValue(normalizedIdx * SNAP_INTERVAL);
                    currentIndexRef.current = normalizedIdx;
                    setActiveIndex(normalizedIdx);
                  }
                }}
                onScroll={Animated.event(
                  [{ nativeEvent: { contentOffset: { x: scrollX } } }],
                  { useNativeDriver: true }
                )}
                scrollEventThrottle={16}
                renderItem={renderBannerItem}
              />
            </View>

            {/* Services Section "Mua sắm - Giải trí - Đầu tư" */}
            <View style={styles.servicesSection}>
              <AppText style={styles.sectionTitle}>Mua sắm - Giải trí - Đầu tư</AppText>
              <View style={styles.servicesGrid}>
                {SERVICES.map((item, index) => (
                  <TouchableOpacity
                    key={index}
                    style={styles.serviceItem}
                    activeOpacity={0.8}
                    onPress={() => {
                      if (item.id === '3' || item.id === '6') {
                        navigation.navigate('PhoneRecharge');
                      } else {
                        navigation.navigate('BillPayment');
                      }
                    }}
                  >
                    <View style={[styles.serviceIconBg, { backgroundColor: item.iconBg }]}>
                      {item.multiLogo ? (
                        <View style={{ alignItems: 'center', justifyContent: 'center' }}>
                          <AppText style={{ fontSize: 8, fontWeight: '900', color: '#0284C7', letterSpacing: -0.2 }}>vinaphone</AppText>
                          <AppText style={{ fontSize: 8, fontWeight: '900', color: '#EA580C', letterSpacing: -0.2 }}>mobifone</AppText>
                        </View>
                      ) : item.customLogo ? (
                        <AppText style={[styles.customLogoText, { color: item.iconColor }]}>
                          {item.customLogo}
                        </AppText>
                      ) : item.isYinYang ? (
                        <AppText style={{ fontSize: 22 }}>☯</AppText>
                      ) : (
                        <AppIcon name={item.icon as any} size="md" color={item.iconColor} />
                      )}
                      {item.badgeText && (
                        <View style={styles.serviceItemBadge}>
                          <AppText style={styles.serviceItemBadgeText}>{item.badgeText}</AppText>
                        </View>
                      )}
                    </View>
                    <AppText style={styles.serviceTitle} numberOfLines={2}>
                      {item.title}
                    </AppText>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          </View>

        </Animated.ScrollView>
      </SafeAreaView>

      {/* Slide-In Side Menu Drawer (Nút 3 gạch chuẩn 1:1 theo ảnh) */}
      <SideMenuDrawer
        visible={isSideMenuVisible}
        onClose={() => setIsSideMenuVisible(false)}
        navigation={navigation}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  stickyHeaderContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 99,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 10,
    elevation: 12,
  },
  stickyHeaderWrapper: {
    overflow: 'hidden',
    borderBottomLeftRadius: 48, // Tăng độ bo cong sâu mềm mại góc dưới bên TRÁI
    borderBottomRightRadius: 0,
    borderBottomWidth: 1.5,
    borderBottomColor: 'rgba(255, 255, 255, 0.35)',
  },
  stickyLeftAura: {
    position: 'absolute',
    bottom: -20,
    left: -20,
    width: 180,
    height: 70,
    borderRadius: 35,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
  },
  stickyHeaderContent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: 20, // Khoảng cách đệm tạo khoảng thở cho góc cong lớn bên trái
    paddingRight: 16,
    paddingTop: Platform.OS === 'android' ? 6 : 2,
    paddingBottom: 16,
    gap: 12,
  },
  stickySearchPill: {
    flex: 1,
    height: 38,
    marginLeft: 6, // Thu gọn lùi lại sang phải một chút đồng bộ với độ cong
    backgroundColor: '#FFFFFF',
    borderRadius: 19,
    justifyContent: 'center',
    paddingHorizontal: 16,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  stickySearchText: {
    fontSize: 13.5,
    fontWeight: '700',
    color: '#64748B',
    letterSpacing: 0.1,
  },
  stickyHeaderActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  headerBackground: {
    position: 'absolute',
    top: 0, left: 0, right: 0,
    height: 380,
    overflow: 'hidden',
  },
  capsuleShape1: {
    position: 'absolute',
    top: -40, left: -60,
    width: 220, height: 110,
    borderRadius: 55,
    backgroundColor: 'rgba(255,255,255,0.08)',
    transform: [{ rotate: '-25deg' }],
  },
  capsuleShape2: {
    position: 'absolute',
    top: 40, right: -40,
    width: 200, height: 90,
    borderRadius: 45,
    backgroundColor: 'rgba(255,255,255,0.06)',
    transform: [{ rotate: '15deg' }],
  },
  auraGlow: {
    position: 'absolute',
    top: -30, left: 20,
    width: 180, height: 180,
    borderRadius: 90,
    backgroundColor: '#F472B6',
    opacity: 0.3,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: Platform.OS === 'android' ? 8 : 4,
    paddingBottom: 16,
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  starIconWrapper: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  starText: {
    color: '#EF4444', // Red star logo
    fontSize: 22,
    fontWeight: '900',
  },
  logoText: {
    color: Colors.white,
    fontSize: 22,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  headerBeeCenter: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  beeCircle: {
    width: 38, height: 38,
    borderRadius: 19,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16, // Cách đều nhau gap: 16px
  },
  glassHeaderBtn: {
    width: 36, height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.18)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.25)',
  },
  aiBtnText: {
    color: Colors.white,
    fontSize: 13,
    fontWeight: '800',
  },
  scrollContent: {
    paddingBottom: 120,
  },
  balanceSection: {
    paddingHorizontal: 16,
    marginTop: 8,
    zIndex: 2,
  },
  balanceRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    position: 'relative',
  },
  avatarColumn: {
    alignItems: 'center',
    marginLeft: 20,       // 👈 Chỉnh khoảng cách cụm Avatar với mép trái màn hình (tăng = sang phải, giảm = sang trái)
    marginRight: 30,      // 👈 Chỉnh khoảng cách giữa cụm Avatar và thẻ số dư bên phải
  },
  avatarWrapper: {
    position: 'relative',
  },
  avatar: {
    width: 52,            // 👈 Chiều rộng ảnh đại diện
    height: 52,           // 👈 Chiều cao ảnh đại diện
    borderRadius: 26,     // 👈 Bo tròn ảnh (nửa width/height để tròn xoe)
    borderWidth: 2,       // 👈 Độ dày viền trắng quanh avatar
    borderColor: Colors.white, // 👈 Màu viền trắng
  },
  verifiedShield: {
    position: 'absolute',
    bottom: -2,           // 👈 Vị trí huy hiệu check so với đáy avatar (chỉnh top/bottom)
    right: -2,            // 👈 Vị trí huy hiệu check so với mép phải avatar (chỉnh left/right)
    backgroundColor: '#10B981', // 👈 Màu nền xanh lá của huy hiệu
    width: 18,            // 👈 Chiều rộng huy hiệu
    height: 18,           // 👈 Chiều cao huy hiệu
    borderRadius: 9,      // 👈 Bo tròn huy hiệu
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,     // 👈 Viền trắng huy hiệu
    borderColor: Colors.white,
  },
  basicBadge: {
    flexDirection: 'row', // Sắp xếp icon và chữ nằm ngang
    alignItems: 'center', // Căn giữa theo chiều dọc
    backgroundColor: Colors.white, // 👈 Màu nền thẻ (trắng)
    paddingHorizontal: 8, // 👈 Độ rộng lề ngang 2 bên của thẻ (tăng/giảm độ dài thẻ)
    paddingVertical: 3,   // 👈 Độ cao lề trên/dưới của thẻ (tăng/giảm độ dày thẻ)
    borderRadius: Radius.pill, // 👈 Bo cong 2 đầu dạng viên thuốc (hoặc custom số vd: 12, 16, 999)
    marginTop: 6,         // 👈 Khoảng cách từ avatar xuống thẻ Basic (tăng = thẻ tụt xuống, giảm = thẻ nhích lên sát avatar)
    gap: 4,               // 👈 Khoảng cách giữa icon và chữ Basic
    ...Shadows.card,      // 👈 Đổ bóng nhẹ cho thẻ
  },
  basicBadgeText: {
    fontSize: 11,         // 👈 Kích cỡ chữ "Basic" (tăng/giảm size chữ)
    fontWeight: '700',    // 👈 Độ đậm chữ ('400', '600', '700', '800', 'bold')
    color: '#475569',     // 👈 Màu sắc chữ (màu xám đậm slate)
  },
  balanceScrollList: {
    flex: 1,
    overflow: 'visible',
  },
  balanceScrollContent: {
    paddingRight: 16,
  },
  balanceCardWrapper: {
    minHeight: 125,       // 👈 Chiều cao tối thiểu của thẻ số dư (tăng/giảm độ cao thẻ)
    borderRadius: 20,     // 👈 Độ bo cong 4 góc của thẻ
    overflow: 'hidden',
    ...Shadows.elevated,  // 👈 Đổ bóng nổi khối 3D cho thẻ
  },
  balanceCard: {
    flex: 1,
    borderRadius: 20,
    paddingTop: 12,        // 👈 Khoảng cách từ mép trên tới dòng "Tổng số dư VND"
    paddingHorizontal: 14, // 👈 Đệm lề 2 bên trong thẻ (trái & phải)
    paddingBottom: 8,      // 👈 Khoảng cách mép dưới
    borderWidth: 1,        // 👈 Độ dày viền kính glassmorphism
    borderColor: 'rgba(255,255,255,0.25)', // 👈 Màu viền kính mờ
    justifyContent: 'space-between',
  },
  balanceHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,               // 👈 Khoảng cách giữa chữ và icon mũi tên
    marginBottom: 2,      // 👈 Khoảng cách giữa dòng header và dòng số tiền
  },
  balanceTitle: {
    color: 'rgba(255,255,255,0.95)',
    fontSize: 12.5,       // 👈 Kích thước chữ "Tổng số dư VND"
    fontWeight: '600',    // 👈 Độ đậm chữ tiêu đề
  },
  eyeToggleBtn: {
    padding: 3,           // 👈 Vùng bấm mở rộng cho icon con mắt
  },
  amountRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: 6,      // 👈 Khoảng cách giữa dòng số tiền và dải "SINH LỜI MỖI NGÀY"
  },
  amountNumber: {
    color: Colors.white,
    fontSize: 22,         // 👈 Kích thước số tiền (vd: 18,010) (tăng = số to hơn, giảm = số nhỏ lại)
    fontWeight: '800',    // 👈 Độ đậm số tiền ('800', '900', 'bold')
    letterSpacing: 0.5,   // 👈 Khoảng cách giữa các con số
  },
  amountCurrency: {
    color: 'rgba(255,255,255,0.92)',
    fontSize: 13.5,       // 👈 Kích thước chữ đơn vị "VND"
    fontWeight: '700',    // 👈 Độ đậm chữ "VND"
  },
  profitStrip: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: 'rgba(255,255,255,0.16)', // 👈 Màu nền dải mờ bên dưới
    marginHorizontal: -14,// 👈 Kéo dài dải mờ ra sát 2 mép thẻ (phải bằng âm của paddingHorizontal)
    marginBottom: -8,     // 👈 Kéo dải mờ xuống sát đáy thẻ (phải bằng âm của paddingBottom)
    paddingHorizontal: 14,// 👈 Đệm lề 2 bên của dải mờ
    paddingVertical: 6,   // 👈 Độ dày chiều dọc của dải mờ (tăng/giảm độ cao dải)
    borderBottomLeftRadius: 20,  // 👈 Bo góc dưới-trái dải mờ khớp với thẻ
    borderBottomRightRadius: 20, // 👈 Bo góc dưới-phải dải mờ khớp với thẻ
  },
  profitText: {
    color: '#FDF2F8',     // 👈 Màu chữ "SINH LỜI MỖI NGÀY" (trắng hồng sen sáng)
    fontSize: 10.5,       // 👈 Kích thước chữ "SINH LỜI MỖI NGÀY"
    fontWeight: '800',    // 👈 Độ đậm chữ
    letterSpacing: 0.3,
  },
  whiteBodyContainer: {
    backgroundColor: '#FFFFFF',  // 👈 1. Màu nền khối thân app (màu trắng)
    borderTopLeftRadius: 22,    // 👈 2. Độ bo cong góc trên-trái
    borderTopRightRadius: 22,   // 👈 3. Độ bo cong góc trên-phải

    // 👇👇👇 CHỈNH KÉO KHỐI TRẮNG LÊN / XUỐNG TẠI ĐÂY: 👇👇👇
    // • MUỐN KÉO XUỐNG DƯỚI (lộ nhiều nền xanh hơn): TĂNG số này lên (vd: 20, 26, 32, 40)
    // • MUỐN KÉO LÊN TRÊN (đè lẹm sâu vào nền xanh): GIẢM số này xuống hoặc DÙNG SỐ ÂM (vd: 5, 0, -10, -20)
    marginTop: 25,              // 👈 4. VỊ TRÍ ĐẨY LÊN/XUỐNG (Tăng số = kéo khối trắng tụt xuống dưới)

    paddingTop: 20,             // 👈 5. Đệm lề bên trong từ mép trên khối trắng đến 4 nút chuyển tiền
    paddingBottom: 120,         // 👈 6. Đệm lề đáy để cuộn không bị thanh menu đáy che
    width: '100%',              // 👈 7. Chiều rộng 100% tràn toàn màn hình
    shadowColor: '#700F43',     // 👈 8. Màu đổ bóng lên nền hồng sen
    shadowOffset: { width: 0, height: -4 }, // 👈 Hướng bóng hắt lên phía trên
    shadowOpacity: 0.12,         // 👈 Độ mờ của bóng
    shadowRadius: 14,           // 👈 Độ lan tỏa của bóng
    elevation: 6,               // 👈 Đảm bảo khối trắng luôn NẰM ĐÈ LÊN TRÊN nền xanh (Android)
    zIndex: 10,                 // 👈 Đảm bảo khối trắng luôn NẰM ĐÈ LÊN TRÊN nền xanh (iOS/Web)
  },
  quickActionsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    alignItems: 'flex-start',
  },
  actionItem: {
    alignItems: 'center',
    flex: 1,
  },
  actionIconContainer: {
    position: 'relative',
    marginBottom: 6,
  },
  actionIconBg: {
    width: 54,
    height: 54,
    borderRadius: 18, // Squircle
    backgroundColor: '#FDF2F8', // Nền hồng pastel hoa sen
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#FCE7F3', // Viền hồng pastel
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  actionTitle: {
    textAlign: 'center',
    fontSize: 12.5,
    fontWeight: '600',
    color: '#1E293B',
    lineHeight: 16,
  },
  badge: {
    position: 'absolute',
    top: -8,
    right: -10,
    paddingHorizontal: 5,
    paddingVertical: 2,
    borderRadius: 4,
    zIndex: 10,
    elevation: 3,
  },
  badgeTaiLoc: {
    backgroundColor: '#E11D48',
  },
  badgeNhuGio: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  badgeText: {
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 0.2,
  },
  badgeTextTaiLoc: {
    color: '#FFFFFF',
  },
  badgeTextNhuGio: {
    color: '#D2519D',
  },
  expandButtonWrapper: {
    alignItems: 'center',
    marginTop: 6,
    marginBottom: 4,
  },
  expandButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#E11D48', // Bright pinkish red
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#E11D48',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.35,
    shadowRadius: 5,
    elevation: 6,
  },
  carouselContainer: {
    marginTop: 20,
    marginBottom: 20,
    height: 190,
  },
  bannerItemWrapper: {
    height: 190,
    justifyContent: 'center',
  },
  bannerItem: {
    flex: 1,
    borderRadius: 18,
    overflow: 'hidden',
    ...Shadows.elevated,
  },
  bannerBackground: {
    flex: 1,
    padding: 14,
    position: 'relative',
  },
  bannerTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 6,
  },
  bannerBrandLogo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: 'rgba(255,255,255,0.2)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: Radius.pill,
  },
  miniStar: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  miniStarText: {
    color: '#EF4444',
    fontSize: 10,
    fontWeight: '900',
  },
  bannerBrandText: {
    color: Colors.white,
    fontSize: 10,
    fontWeight: '900',
  },
  bannerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0A1AD2',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: Radius.pill,
    gap: 4,
  },
  bannerBadgeText: {
    color: Colors.white,
    fontSize: 9,
    fontWeight: '800',
  },
  bannerTextContent: {
    marginTop: 2,
    zIndex: 2,
  },
  title3DBoxYellow: {
    alignSelf: 'flex-start',
  },
  bannerTitleYellow: {
    color: '#FDE047',
    fontSize: 22,
    fontWeight: '900',
    letterSpacing: 0.5,
    textShadowColor: 'rgba(0,0,0,0.4)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 2,
  },
  title3DBoxRed: {
    alignSelf: 'flex-start',
    marginBottom: 2,
  },
  bannerTitleRed: {
    color: '#EF4444',
    fontSize: 22,
    fontWeight: '900',
    letterSpacing: 0.5,
    textShadowColor: 'rgba(255,255,255,0.8)',
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 3,
  },
  bannerSubtitle: {
    color: '#7DD3FC',
    fontSize: 11,
    fontWeight: '700',
    marginTop: 2,
  },
  floatingTag: {
    position: 'absolute',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    zIndex: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 2,
    elevation: 3,
  },
  floatingTagText: {
    fontSize: 9,
    fontWeight: '900',
  },
  mascotBleedContainer: {
    position: 'absolute',
    right: 30,
    bottom: 10,
    zIndex: 2,
  },
  carMascotWrapper: {
    alignItems: 'center',
  },
  beeHead: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: -10,
    zIndex: 3,
  },
  flagIcon: {
    marginLeft: -4,
  },
  yellowCar: {
    zIndex: 1,
  },
  ctaPill: {
    backgroundColor: '#38BDF8',
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    alignSelf: 'flex-start',
    marginTop: 'auto',
    zIndex: 4,
  },
  ctaPillText: {
    color: Colors.white,
    fontSize: 10,
    fontWeight: '800',
  },
  servicesSection: {
    paddingHorizontal: 16,
    marginTop: 4,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#0F172A',
    marginBottom: 14,
  },
  servicesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  serviceItem: {
    alignItems: 'center',
    width: '23%',
    marginBottom: 16,
  },
  serviceIconBg: {
    width: 54, height: 54,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 6,
    position: 'relative',
    ...Shadows.card,
    shadowOpacity: 0.06,
  },
  customLogoText: {
    fontSize: 11,
    fontWeight: '900',
  },
  serviceItemBadge: {
    position: 'absolute',
    top: -4, right: -4,
    backgroundColor: '#EF4444',
    width: 16, height: 16,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  serviceItemBadgeText: {
    color: Colors.white,
    fontSize: 9,
    fontWeight: '800',
  },
  serviceTitle: {
    textAlign: 'center',
    fontSize: 11,
    fontWeight: '500',
    color: '#334155',
    lineHeight: 15,
  },
  calendarCardContent: {
    flex: 1,
    padding: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  calendarTopBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '60%',
    position: 'absolute',
    top: 12,
  },
  calendarRing: {
    width: 8,
    height: 14,
    borderRadius: 4,
    backgroundColor: '#818CF8',
  },
  calendarBody: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  calendarZeroText: {
    fontSize: 42,
    fontWeight: '900',
    color: '#38BDF8',
    letterSpacing: -1,
    textShadowColor: 'rgba(0,0,0,0.5)',
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 3,
  },
  calendarSubText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#FFFFFF',
    marginTop: 2,
    letterSpacing: 0.5,
  },
});