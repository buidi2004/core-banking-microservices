import React, { useState } from 'react';
import { View, StyleSheet, Image, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { AppText } from '../components/typography/AppText';

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
          <View style={styles.logoContainer}>
            <AppIcon name="wallet" size="md" color={Colors.primary} />
            <AppText variant="heading" style={styles.logoText}>EWallet</AppText>
          </View>
          <View style={styles.headerActions}>
            <TouchableOpacity style={styles.headerIconBtn}>
              <AppIcon name="search" size="sm" color={Colors.textPrimary} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.headerIconBtn} onPress={() => navigation.navigate('Notifications')}>
              <AppIcon name="notification" size="sm" color={Colors.textPrimary} />
              <View style={styles.notifDot} />
            </TouchableOpacity>
            <TouchableOpacity style={styles.headerIconBtn}>
              <AppIcon name="menu" size="sm" color={Colors.textPrimary} />
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
              <AppText variant="caption" style={styles.walletLabel}>Tổng số dư</AppText>
              <TouchableOpacity onPress={() => setBalanceVisible(!balanceVisible)}>
                <AppIcon name={balanceVisible ? "eyeOff" : "eye"} size="sm" color={Colors.textSecondary} />
              </TouchableOpacity>
            </View>
            <AppText variant="display" style={styles.balanceText}>
              {balanceVisible ? '5.500.000 VNĐ' : '••••••'}
            </AppText>
            <TouchableOpacity style={styles.viewDetailBtn}>
              <AppText variant="caption" style={styles.viewDetailText}>Xem chi tiết</AppText>
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
                <AppText variant="caption" style={styles.quickActionLabel}>{item.label}</AppText>
              </TouchableOpacity>
            ))}
          </View>
          <TouchableOpacity style={styles.viewAllBtn}>
            <AppText variant="caption" style={styles.viewAllText}>Xem thêm</AppText>
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
              <AppText variant="caption" style={styles.promoSubtitle}>Ưu đãi tháng 7!</AppText>
              <AppText variant="body" style={styles.promoTitle}>Giảm 20% khi thanh toán tại Highlands Coffee</AppText>
              <View style={styles.promoButton}>
                <AppText variant="bodySm" style={styles.promoButtonText}>Xem ngay</AppText>
              </View>
            </View>
          </LinearGradient>
        </TouchableOpacity>

        {/* Recent Transactions */}
        <View style={styles.historySection}>
          <View style={styles.sectionHeader}>
            <AppText variant="heading" style={styles.sectionTitle}>Giao dịch gần đây</AppText>
            <TouchableOpacity onPress={() => navigation.navigate('History')}>
              <AppText variant="caption" style={styles.viewAllText}>Tất cả</AppText>
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
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  logoText: {
    color: Colors.primary,
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
    color: Colors.textSecondary,
    },
  balanceText: {
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
    color: Colors.primary,
    },
  quickActionsSheet: {
    marginHorizontal: Spacing.lg,
    marginTop: -24,
    backgroundColor: Colors.surface,
    borderTopLeftRadius: Radius.lg,
    borderTopRightRadius: Radius.lg,
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
    color: Colors.textPrimary,
    },
  viewAllBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: Spacing.md,
    gap: Spacing.xs,
  },
  viewAllText: {
    color: Colors.primary,
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
    color: Colors.glassOpaque,
    marginBottom: 4,
  },
  promoTitle: {
    color: Colors.white,
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