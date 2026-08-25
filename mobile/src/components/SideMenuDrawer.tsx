import React, { useEffect, useRef } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  Modal,
  Animated,
  Dimensions,
  Image,
  TouchableWithoutFeedback,
  SafeAreaView,
  Platform,
} from 'react-native';
import Svg, { Path, Rect, Circle, Polygon } from 'react-native-svg';
import { AppText } from './typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';

interface SideMenuDrawerProps {
  visible: boolean;
  onClose: () => void;
  navigation?: any;
}

const { width } = Dimensions.get('window');
const DRAWER_WIDTH = Math.round(width * 0.82);

// Vector Icons Matching Exact Screenshot
function CloseXIcon({ size = 22, color = '#1E293B' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path d="M18 6L6 18M6 6l12 12" stroke={color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
    </Svg>
  );
}

// Verified Shield (Góc avatar)
function MBShieldCheckIcon({ size = 20 }: { size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"
        fill="#10B981"
        stroke="#FFFFFF"
        strokeWidth="1.5"
      />
      <Path
        d="m9 12 2 2 4-4"
        stroke="#FFFFFF"
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  );
}

// Config / 4 Shapes Icon (Cấu hình)
function MBConfigIcon({ size = 24, color = Colors.primary }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      {/* Top Left: Square with plus */}
      <Rect x="3.5" y="3.5" width="7" height="7" rx="2" stroke={color} strokeWidth="2" />
      <Path d="M7 5.5v3M5.5 7h3" stroke={color} strokeWidth="1.8" strokeLinecap="round" />
      {/* Top Right: Circle */}
      <Circle cx="17" cy="7" r="3.5" stroke={color} strokeWidth="2" />
      {/* Bottom Left: Circle */}
      <Circle cx="7" cy="17" r="3.5" stroke={color} strokeWidth="2" />
      {/* Bottom Right: Diamond / Rhombus */}
      <Rect x="13.5" y="13.5" width="7" height="7" rx="2" stroke={color} strokeWidth="2" />
    </Svg>
  );
}

// Hexagon Settings Icon (Cài đặt)
function MBSettingsHexIcon({ size = 24, color = Colors.primary }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M12 2.5 L19.8 7 V17 L12 21.5 L4.2 17 V7 L12 2.5 Z"
        stroke={color}
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <Circle cx="12" cy="12" r="3.5" stroke={color} strokeWidth="2" />
    </Svg>
  );
}

// Crown Icon (Hội viên MB)
function MBCrownIcon({ size = 24, color = Colors.primary }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M3 18h18v2.5H3V18zm1.5-10.5 4 3.5 3.5-7 3.5 7 4-3.5 1.5 10H3L4.5 7.5z"
        stroke={color}
        strokeWidth="2"
        strokeLinejoin="round"
        fill="none"
      />
      <Circle cx="12" cy="4" r="1" fill={color} />
      <Circle cx="4.5" cy="7.5" r="1" fill={color} />
      <Circle cx="19.5" cy="7.5" r="1" fill={color} />
    </Svg>
  );
}

// Globe Icon (Ngôn ngữ)
function MBGlobeIcon({ size = 24, color = Colors.primary }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Circle cx="12" cy="12" r="9" stroke={color} strokeWidth="2" />
      <Path d="M3 12h18M12 3c2.8 4 4 6 4 9s-1.2 5-4 9M12 3c-2.8 4-4 6-4 9s1.2 5 4 9" stroke={color} strokeWidth="1.8" />
    </Svg>
  );
}

// Vietnam Flag Round Icon 🇻🇳
function VietnamFlagCircle({ size = 20 }: { size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24">
      {/* Red Circle Background */}
      <Circle cx="12" cy="12" r="12" fill="#DA251D" />
      {/* Gold 5-point Star */}
      <Polygon
        points="12,5 14.2,10.2 19.5,10.5 15.2,14 16.7,19.2 12,16 7.3,19.2 8.8,14 4.5,10.5 9.8,10.2"
        fill="#FFEB3B"
      />
    </Svg>
  );
}

// Logout Icon (Đăng xuất)
function MBLogoutIcon({ size = 24, color = Colors.primary }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path
        d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"
        stroke={color}
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </Svg>
  );
}

// Chevron Right
function ChevronRightIcon({ size = 18, color = '#94A3B8' }: { size?: number; color?: string }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <Path d="M9 18l6-6-6-6" stroke={color} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
    </Svg>
  );
}

export function SideMenuDrawer({ visible, onClose, navigation }: SideMenuDrawerProps) {
  const { user } = useApp();
  const slideAnim = useRef(new Animated.Value(DRAWER_WIDTH)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(slideAnim, {
          toValue: 0,
          duration: 260,
          useNativeDriver: true,
        }),
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 260,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(slideAnim, {
          toValue: DRAWER_WIDTH,
          duration: 220,
          useNativeDriver: true,
        }),
        Animated.timing(fadeAnim, {
          toValue: 0,
          duration: 220,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible]);

  if (!visible) return null;

  return (
    <Modal transparent visible={visible} animationType="none" onRequestClose={onClose}>
      <View style={styles.overlayContainer}>
        {/* Dim Backdrop */}
        <TouchableWithoutFeedback onPress={onClose}>
          <Animated.View style={[styles.backdrop, { opacity: fadeAnim }]} />
        </TouchableWithoutFeedback>

        {/* Slide-In Drawer Body */}
        <Animated.View style={[styles.drawerBody, { transform: [{ translateX: slideAnim }] }]}>
          <SafeAreaView style={styles.safeArea}>
            
            {/* Top Close Button */}
            <View style={styles.topHeader}>
              <View style={{ flex: 1 }} />
              <TouchableOpacity
                onPress={onClose}
                style={styles.closeBtn}
                hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
                activeOpacity={0.7}
              >
                <CloseXIcon size={22} color="#1E293B" />
              </TouchableOpacity>
            </View>

            {/* User Profile Header */}
            <TouchableOpacity
              style={styles.profileRow}
              activeOpacity={0.75}
              onPress={() => {
                onClose();
                navigation?.navigate('EditProfile');
              }}
            >
              <View style={styles.avatarWrapper}>
                <Image
                  source={{ uri: 'https://i.pravatar.cc/150?img=11' }}
                  style={styles.avatar}
                />
                <View style={styles.verifiedBadge}>
                  <MBShieldCheckIcon size={18} />
                </View>
              </View>

              <View style={styles.profileInfo}>
                <AppText style={styles.profileName}>{user?.name || 'Tài khoản'}</AppText>
                <View style={styles.profileLinkRow}>
                  <AppText style={styles.profileLinkText}>Hồ sơ người dùng</AppText>
                  <ChevronRightIcon size={14} color={Colors.primary} />
                </View>
              </View>
            </TouchableOpacity>

            <View style={styles.divider} />

            {/* Menu List */}
            <View style={styles.menuList}>
              {/* Item 1: Cấu hình */}
              <TouchableOpacity style={styles.menuRow} activeOpacity={0.7}>
                <View style={styles.menuLeft}>
                  <MBConfigIcon size={24} color={Colors.primary} />
                  <AppText style={styles.menuTitle}>Cấu hình</AppText>
                </View>
                <ChevronRightIcon size={18} color={Colors.primary} />
              </TouchableOpacity>

              {/* Item 2: Cài đặt with NEW badge */}
              <TouchableOpacity style={styles.menuRow} activeOpacity={0.7}>
                <View style={styles.menuLeft}>
                  <MBSettingsHexIcon size={24} color={Colors.primary} />
                  <AppText style={styles.menuTitle}>Cài đặt</AppText>
                  <View style={styles.newBadge}>
                    <AppText style={styles.newBadgeText}>NEW</AppText>
                  </View>
                </View>
                <ChevronRightIcon size={18} color={Colors.primary} />
              </TouchableOpacity>

              {/* Item 3: Hội viên MB with Basic badge */}
              <TouchableOpacity style={styles.menuRow} activeOpacity={0.7}>
                <View style={styles.menuLeft}>
                  <MBCrownIcon size={24} color={Colors.primary} />
                  <AppText style={styles.menuTitle}>Hội viên MB</AppText>
                </View>
                <View style={styles.basicPillBadge}>
                  <Svg width={16} height={16} viewBox="0 0 24 24" fill="none">
                    <Path
                      d="M3 18h18v2.5H3V18zm1.5-10.5 4 3.5 3.5-7 3.5 7 4-3.5 1.5 10H3L4.5 7.5z"
                      fill="#94A3B8"
                    />
                  </Svg>
                  <AppText style={styles.basicPillText}>Basic</AppText>
                </View>
              </TouchableOpacity>
            </View>

            {/* Spacer */}
            <View style={{ flex: 1 }} />

            {/* Bottom Actions */}
            <View style={styles.bottomSection}>
              {/* Ngôn ngữ */}
              <TouchableOpacity style={styles.bottomRow} activeOpacity={0.7}>
                <View style={styles.menuLeft}>
                  <MBGlobeIcon size={24} color={Colors.primary} />
                  <AppText style={styles.bottomTitle}>Ngôn ngữ</AppText>
                </View>
                <View style={styles.langValueRow}>
                  <AppText style={styles.langText}>Tiếng Việt</AppText>
                  <VietnamFlagCircle size={20} />
                </View>
              </TouchableOpacity>

              {/* Đăng xuất */}
              <TouchableOpacity
                style={styles.bottomRow}
                activeOpacity={0.7}
                onPress={() => {
                  onClose();
                  navigation?.navigate('Login');
                }}
              >
                <View style={styles.menuLeft}>
                  <MBLogoutIcon size={24} color={Colors.primary} />
                  <AppText style={styles.bottomTitle}>Đăng xuất</AppText>
                </View>
              </TouchableOpacity>

              {/* Version & Status */}
              <View style={styles.versionFooter}>
                <AppText style={styles.versionNumber}>v6.5.15 (763)</AppText>
                <AppText style={styles.versionStatus}>Phiên bản mới nhất</AppText>
              </View>
            </View>

          </SafeAreaView>
        </Animated.View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlayContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(15, 23, 42, 0.45)', // Nền mờ phía sau
  },
  drawerBody: {
    position: 'absolute',
    right: 0,
    top: 0,
    bottom: 0,
    width: DRAWER_WIDTH,
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: -4, height: 0 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 20,
  },
  safeArea: {
    flex: 1,
    paddingHorizontal: 20,
    paddingBottom: Platform.OS === 'ios' ? 16 : 24,
  },
  topHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: 12,
    paddingBottom: 8,
  },
  closeBtn: {
    padding: 6,
  },
  profileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    gap: 14,
  },
  avatarWrapper: {
    position: 'relative',
  },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  verifiedBadge: {
    position: 'absolute',
    top: -3,
    left: -3,
    zIndex: 10,
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontSize: 17,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: 0.3,
    marginBottom: 4,
  },
  profileLinkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  profileLinkText: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.primary, // Hồng Sen Đậm (#D2519D)
  },
  divider: {
    height: 1,
    backgroundColor: '#F1F5F9',
    marginVertical: 12,
  },
  menuList: {
    paddingTop: 8,
  },
  menuRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 18,
  },
  menuLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  menuTitle: {
    fontSize: 15.5,
    fontWeight: '700',
    color: '#1E293B',
    letterSpacing: 0.1,
  },
  newBadge: {
    backgroundColor: '#E11D48',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    marginLeft: 4,
  },
  newBadgeText: {
    color: '#FFFFFF',
    fontSize: 9.5,
    fontWeight: '900',
    letterSpacing: 0.3,
  },
  basicPillBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  basicPillText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#475569',
  },
  bottomSection: {
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    paddingTop: 12,
  },
  bottomRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
  },
  bottomTitle: {
    fontSize: 15.5,
    fontWeight: '700',
    color: '#1E293B',
  },
  langValueRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  langText: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.primary, // Hồng Sen Đậm (#D2519D)
  },
  versionFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 16,
    paddingBottom: 8,
  },
  versionNumber: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0F172A',
  },
  versionStatus: {
    fontSize: 12.5,
    fontWeight: '700',
    color: Colors.primary, // Hồng Sen Đậm (#D2519D)
  },
});
