import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { EmptyState } from '../components/EmptyState';

interface NotificationsScreenProps {
  navigation: any;
}

const mockNotifications = [
  { id: '1', title: 'Giao dịch thành công', message: 'Bạn đã chuyển 500.000đ cho Nguyễn Văn A', time: '14:30', read: false, type: 'transaction' },
  { id: '2', title: 'Ưu đãi mới', message: 'Giảm 20% khi thanh toán tại Highlands Coffee', time: '10:00', read: false, type: 'promo' },
  { id: '3', title: 'Nạp tiền thành công', message: 'Đã nạp 1.000.000đ vào ví', time: ' yesterday', read: true, type: 'transaction' },
];

export default function NotificationsScreen({ navigation }: NotificationsScreenProps) {
  const [activeTab, setActiveTab] = useState<'all' | 'unread'>('all');

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
              <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Thông báo</Text>
          <TouchableOpacity>
              <AppIcon name="settings-outline" size="sm" color={Colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </BlurView>

      {/* Tabs */}
      <View style={styles.tabsContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'all' && styles.tabActive]}
          onPress={() => setActiveTab('all')}
        >
          <Text style={[styles.tabText, activeTab === 'all' && styles.tabTextActive]}>Tất cả</Text>
          {activeTab === 'all' && <View style={styles.tabIndicator} />}
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'unread' && styles.tabActive]}
          onPress={() => setActiveTab('unread')}
        >
          <Text style={[styles.tabText, activeTab === 'unread' && styles.tabTextActive]}>Chưa đọc</Text>
          {activeTab === 'unread' && <View style={styles.tabIndicator} />}
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {mockNotifications.length === 0 ? (
          <EmptyState
            icon="notifications-off-outline"
            title="Không có thông báo"
            subtitle="Bạn sẽ thấy thông báo mới tại đây"
          />
        ) : (
          <View style={styles.listContainer}>
            {mockNotifications.map((notif, index) => (
              <GroupedListRow
                key={notif.id}
                title={notif.title}
                subtitle={notif.message}
                date={notif.time}
                isFirst={index === 0}
                isLast={index === mockNotifications.length - 1}
                hasBadge={!notif.read}
                icon={
                  <AppIcon
                    name={notif.type === 'promo' ? 'gift' : 'wallet'}
                    size="sm"
                    color={notif.type === 'promo' ? Colors.warning : Colors.success}
                  />
                }
              />
            ))}
          </View>
        )}
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
  headerTitle: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  tabsContainer: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.sm,
    gap: Spacing.md,
  },
  tab: {
    paddingVertical: Spacing.sm,
    minWidth: 80,
    alignItems: 'center',
  },
  tabActive: {
    // Indicator shown below
  },
  tabText: {
    
    fontWeight: '500',
    color: Colors.textSecondary,
  },
  tabTextActive: {
    color: Colors.textPrimary,
    fontWeight: '700',
  },
  tabIndicator: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 2,
    backgroundColor: Colors.primary,
    borderRadius: Radius.none,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.sm,
  },
  listContainer: {
    marginHorizontal: Spacing.lg,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
});
