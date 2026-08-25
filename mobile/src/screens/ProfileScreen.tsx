import React from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView, Image, StatusBar } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';

interface ProfileScreenProps {
  navigation: any;
}

export default function ProfileScreen({ navigation }: ProfileScreenProps) {
  const { user } = useApp();
  
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.content}>
        
        {/* User Profile Header */}
        <View style={styles.profileRow}>
          <View style={styles.avatarWrapper}>
            <Image
              source={{ uri: 'https://i.pravatar.cc/150?img=11' }}
              style={styles.avatar}
            />
            <View style={styles.verifiedBadge}>
              <MaterialCommunityIcons name="shield-check" size={16} color="#10B981" />
            </View>
          </View>

          <View style={styles.profileInfo}>
            <AppText style={styles.profileName}>{user?.name || 'Tài khoản'}</AppText>
            <TouchableOpacity
              style={styles.profileLinkRow}
              activeOpacity={0.7}
              onPress={() => navigation.navigate('UserProfile')}
            >
              <AppText style={styles.profileLinkText}>Hồ sơ người dùng</AppText>
              <Ionicons name="chevron-forward" size={14} color={Colors.primary} />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.divider} />

        {/* Menu List with Real Vector Icons */}
        <View style={styles.menuList}>
          {/* Item 1: Cấu hình */}
          <TouchableOpacity style={styles.menuRow} activeOpacity={0.7}>
            <View style={styles.menuLeft}>
              <MaterialCommunityIcons name="view-grid-plus-outline" size={24} color={Colors.primary} />
              <AppText style={styles.menuTitle}>Cấu hình</AppText>
            </View>
            <Ionicons name="chevron-forward" size={18} color={Colors.primary} />
          </TouchableOpacity>

          {/* Item 2: Cài đặt with NEW badge */}
          <TouchableOpacity style={styles.menuRow} activeOpacity={0.7}>
            <View style={styles.menuLeft}>
              <Ionicons name="settings-outline" size={24} color={Colors.primary} />
              <AppText style={styles.menuTitle}>Cài đặt</AppText>
              <View style={styles.newBadge}>
                <AppText style={styles.newBadgeText}>NEW</AppText>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={18} color={Colors.primary} />
          </TouchableOpacity>

          {/* Item 3: Hội viên MB with Basic badge */}
          <TouchableOpacity
            style={styles.menuRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('KycLevel')}
          >
            <View style={styles.menuLeft}>
              <FontAwesome5 name="crown" size={20} color={Colors.primary} />
              <AppText style={styles.menuTitle}>Hội viên MB</AppText>
            </View>
            <View style={styles.basicPillBadge}>
              <FontAwesome5 name="crown" size={12} color="#94A3B8" />
              <AppText style={styles.basicPillText}>Basic</AppText>
            </View>
          </TouchableOpacity>

          {/* Item 4: Điều khoản sử dụng */}
          <TouchableOpacity
            style={styles.menuRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('TermsOfService')}
          >
            <View style={styles.menuLeft}>
              <MaterialCommunityIcons name="file-document-outline" size={24} color={Colors.primary} />
              <AppText style={styles.menuTitle}>Điều khoản & Điều kiện</AppText>
            </View>
            <Ionicons name="chevron-forward" size={18} color={Colors.primary} />
          </TouchableOpacity>
        </View>

        <View style={{ flex: 1, minHeight: 80 }} />

        {/* Bottom Actions */}
        <View style={styles.bottomSection}>
          {/* Ngôn ngữ */}
          <TouchableOpacity style={styles.bottomRow} activeOpacity={0.7}>
            <View style={styles.menuLeft}>
              <Ionicons name="globe-outline" size={24} color={Colors.primary} />
              <AppText style={styles.bottomTitle}>Ngôn ngữ</AppText>
            </View>
            <View style={styles.langValueRow}>
              <AppText style={styles.langText}>Tiếng Việt</AppText>
              <AppText style={{ fontSize: 20 }}>🇻🇳</AppText>
            </View>
          </TouchableOpacity>

          {/* Đăng xuất */}
          <TouchableOpacity
            style={styles.bottomRow}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('Login')}
          >
            <View style={styles.menuLeft}>
              <Ionicons name="log-out-outline" size={24} color={Colors.primary} />
              <AppText style={styles.bottomTitle}>Đăng xuất</AppText>
            </View>
          </TouchableOpacity>

          {/* Version & Status */}
          <View style={styles.versionFooter}>
            <AppText style={styles.versionNumber}>v6.5.15 (763)</AppText>
            <AppText style={styles.versionStatus}>Phiên bản mới nhất</AppText>
          </View>
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  content: {
    flexGrow: 1,
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 40,
  },
  profileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    gap: 16,
  },
  avatarWrapper: {
    position: 'relative',
  },
  avatar: {
    width: 60,
    height: 60,
    borderRadius: 30,
    borderWidth: 2,
    borderColor: '#FCE7F3',
  },
  verifiedBadge: {
    position: 'absolute',
    bottom: -2,
    right: -2,
    backgroundColor: '#FFFFFF',
    borderRadius: 10,
    padding: 1,
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: 0.2,
  },
  profileLinkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  profileLinkText: {
    fontSize: 13.5,
    fontWeight: '600',
    color: Colors.primary,
  },
  divider: {
    height: 1,
    backgroundColor: '#F1F5F9',
    marginVertical: 10,
  },
  menuList: {
    paddingTop: 8,
  },
  menuRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F8FAFC',
  },
  menuLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  menuTitle: {
    fontSize: 15.5,
    fontWeight: '700',
    color: '#0F172A',
  },
  newBadge: {
    backgroundColor: '#EF4444',
    borderRadius: 6,
    paddingHorizontal: 5,
    paddingVertical: 1.5,
    marginLeft: 4,
  },
  newBadgeText: {
    color: '#FFFFFF',
    fontSize: 9,
    fontWeight: '900',
    letterSpacing: 0.3,
  },
  basicPillBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F1F5F9',
    borderRadius: 14,
    paddingHorizontal: 10,
    paddingVertical: 4,
    gap: 4,
  },
  basicPillText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#64748B',
  },
  bottomSection: {
    paddingTop: 16,
  },
  bottomRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  bottomTitle: {
    fontSize: 15.5,
    fontWeight: '700',
    color: '#0F172A',
  },
  langValueRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  langText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  versionFooter: {
    alignItems: 'center',
    paddingTop: 24,
    paddingBottom: 10,
  },
  versionNumber: {
    fontSize: 13,
    fontWeight: '700',
    color: '#94A3B8',
  },
  versionStatus: {
    fontSize: 12,
    fontWeight: '500',
    color: '#CBD5E1',
    marginTop: 2,
  },
});
