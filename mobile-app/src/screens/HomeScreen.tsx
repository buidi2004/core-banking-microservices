import React, { useState } from 'react';
import { View, Text, StyleSheet, Image, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';

interface HomeScreenProps {
  navigation: any;
}

export default function HomeScreen({ navigation }: HomeScreenProps) {
  const [balanceVisible, setBalanceVisible] = useState(true);

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <Image source={{ uri: 'https://i.pravatar.cc/100' }} style={styles.avatar} />
          <Text style={styles.headerTitle}>Trang chủ</Text>
          <View style={styles.headerActions}>
            <TouchableOpacity style={styles.headerIconBtn}>
              <AppIcon name="search" size="sm" color={Colors.textPrimary} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.headerIconBtn} onPress={() => navigation.navigate('Notifications')}>
              <AppIcon name="notification" size="sm" color={Colors.textPrimary} />
              <View style={styles.notifDot} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.headerIconBtn}>
              <AppIcon name="profile" size="sm" color={Colors.textPrimary} />
            </TouchableOpacity>
          </View>
        </View>
      </BlurView>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        {/* Balance Hero Card */}
        <LinearGradient
          colors={[Colors.heroGradStart, Colors.heroGradMid, Colors.heroGradEnd]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.heroCard}
        >
          <BlurView intensity={40} tint="light" style={styles.heroBlurOverlay} />
          <View style={styles.heroContent}>
            <View style={styles.walletHeader}>
              <Text style={styles.walletLabel}>Tổng số dư</Text>
              <TouchableOpacity onPress={() => setBalanceVisible(!balanceVisible)}>
                <AppIcon name={balanceVisible ? "eyeOff" : "eye"} size="sm" color={Colors.textSecondary} />
              </TouchableOpacity>
            </View>
            <Text style={styles.balanceText}>
              {balanceVisible ? '5.500.000 VNĐ' : '••••••'}
            </Text>
            <TouchableOpacity style={styles.viewDetailBtn}>
              <Text style={styles.viewDetailText}>Xem chi tiết</Text>
              <AppIcon name="chevronRight" size="sm" color={Colors.primary} />
            </TouchableOpacity>
          </View>
        </LinearGradient>

        {/* Quick Actions Sheet */}
        <View style={styles.quickActionsSheet}>
          <View style={styles.quickActionsGrid}>
            {[
              { icon: 'back', label: 'Chuyển tiền', nav: 'Transfer' },
              { icon: 'scanFrame', label: 'Quét QR', nav: 'ScanQR' },
              { icon: 'history', label: 'Lịch sử', nav: 'History' },
              { icon: 'notification', label: 'Thông báo', nav: 'Notifications' },
            ].map((item, i) => (
              <TouchableOpacity key={i} style={styles.quickActionItem} onPress={() => navigation.navigate(item.nav)}>
                <View style={styles.quickActionIcon}>
                  <AppIcon name={item.icon as any} size="md" color={Colors.primary} />
                </View>
                <Text style={styles.quickActionLabel}>{item.label}</Text>
              </TouchableOpacity>
            ))}
          </View>
          <TouchableOpacity style={styles.viewAllBtn}>
            <Text style={styles.viewAllText}>Xem thêm</Text>
            <AppIcon name="chevronRight" size="sm" color={Colors.primary} />
          </TouchableOpacity>
        </View>

        {/* Promo Banner */}
        <TouchableOpacity style={styles.promoBanner} onPress={() => navigation.navigate('Promotions')}>
          <LinearGradient
            colors={[Colors.promoGradStart, Colors.promoGradEnd]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.promoGradient}
          >
            <View style={styles.promoContent}>
              <Text style={styles.promoSubtitle}>Ưu đãi tháng 7!</Text>
              <Text style={styles.promoTitle}>Giảm 20% khi thanh toán tại Highlands Coffee</Text>
              <View style={styles.promoButton}>
                <Text style={styles.promoButtonText}>Xem ngay</Text>
              </View>
            </View>
          </LinearGradient>
        </TouchableOpacity>

        {/* Recent Transactions */}
        <View style={styles.historySection}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Giao dịch gần đây</Text>
            <TouchableOpacity onPress={() => navigation.navigate('History')}>
              <Text style={styles.viewAllText}>Tất cả</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.historyList}>
            <GroupedListRow
              title="Starbucks"
              subtitle="Thanh toán"
              date="14:30"
              amount="-100.000đ"
              amountColor={Colors.danger}
              isFirst
              icon={<AppIcon name="electricity" size="sm" color={Colors.danger} />}
              onPress={() => navigation.navigate('TransactionDetail')}
            />
            <GroupedListRow
              title="Nhận tiền từ Nguyễn Văn A"
              subtitle="Chuyển khoản"
              date="12:15"
              amount="+500.000đ"
              amountColor={Colors.success}
              icon={<AppIcon name="check" size="sm" color={Colors.success} />}
              onPress={() => navigation.navigate('TransactionDetail')}
            />
            <GroupedListRow
              title="Grab Food"
              subtitle="Đặt xe"
              date="10:00"
              amount="-50.000đ"
              amountColor={Colors.danger}
              isLast
              icon={<AppIcon name="phone" size="sm" color={Colors.danger} />}
              onPress={() => navigation.navigate('TransactionDetail')}
            />
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  headerBlur: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: Radius.pill,
  },
  headerTitle: {
    fontSize: Typography.bodyLg.fontSize,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  headerActions: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  headerIconBtn: {
    width: 36,
    height: 36,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.card,
  },
  notifDot: {
    position: 'absolute',
    top: 6,
    right: 6,
    width: 8,
    height: 8,
    borderRadius: Radius.pill,
    backgroundColor: Colors.danger,
  },
  scrollContent: {
    paddingBottom: 40,
  },
  heroCard: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.xxl,
    borderRadius: Radius.lg,
    overflow: 'hidden',
    ...Shadows.hero,
  },
  heroBlurOverlay: {
    position: 'absolute',
    top: 0, left: 0, right: 0, bottom: 0,
    borderRadius: Radius.lg,
  },
  heroContent: {
    padding: Spacing.xxl,
  },
  walletHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  walletLabel: {
    fontSize: Typography.caption.fontSize,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
  balanceText: {
    fontSize: Typography.display.fontSize,
    fontWeight: '800',
    color: Colors.textPrimary,
    marginBottom: Spacing.md,
    letterSpacing: -0.5,
  },
  viewDetailBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  viewDetailText: {
    fontSize: Typography.caption.fontSize,
    color: Colors.primary,
    fontWeight: '600',
  },
  quickActionsSheet: {
    marginHorizontal: Spacing.lg,
    marginTop: -24,
    backgroundColor: Colors.surface,
    borderRadius: Radius.lg,
    padding: Spacing.lg,
    ...Shadows.card,
    zIndex: 1,
  },
  quickActionsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  quickActionItem: {
    alignItems: 'center',
    gap: Spacing.xs,
  },
  quickActionIcon: {
    width: 52,
    height: 52,
    borderRadius: Radius.pill,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  quickActionLabel: {
    fontSize: Typography.caption.fontSize,
    color: Colors.textPrimary,
    fontWeight: '500',
  },
  viewAllBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: Spacing.md,
    gap: Spacing.xs,
  },
  viewAllText: {
    fontSize: Typography.caption.fontSize,
    color: Colors.primary,
    fontWeight: '600',
  },
  promoBanner: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.xl,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  promoGradient: {
    padding: Spacing.lg,
    minHeight: 80,
    justifyContent: 'center',
  },
  promoContent: {
    zIndex: 1,
  },
  promoSubtitle: {
    fontSize: Typography.caption.fontSize,
    color: 'rgba(255,255,255,0.9)',
    fontWeight: '600',
    marginBottom: 4,
  },
  promoTitle: {
    fontSize: Typography.body.fontSize,
    color: '#FFF',
    fontWeight: '700',
    lineHeight: 20,
    marginBottom: Spacing.sm,
  },
  promoButton: {
    backgroundColor: Colors.surface,
    paddingVertical: 6,
    paddingHorizontal: Spacing.md,
    borderRadius: Radius.pill,
    alignSelf: 'flex-start',
  },
  promoButtonText: {
    fontSize: Typography.bodySm.fontSize,
    fontWeight: '700',
    color: Colors.primary,
  },
  historySection: {
    marginTop: Spacing.xxl,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  sectionTitle: {
    fontSize: Typography.heading.fontSize,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  historyList: {
    marginHorizontal: Spacing.lg,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
});