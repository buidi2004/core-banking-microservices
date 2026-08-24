import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { EmptyState } from '../components/EmptyState';

interface ChooseRecipientScreenProps {
  navigation: any;
}

export default function ChooseRecipientScreen({ navigation }: ChooseRecipientScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
              <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Chọn người nhận</Text>
          <TouchableOpacity style={styles.headerIconBtn}>
              <AppIcon name="notifications-outline" size="sm" color={Colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </BlurView>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Title */}
        <Text style={styles.pageTitle}>Chuyển tiền</Text>

        {/* Quick input methods */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.methodScroll}>
          {[
            { icon: 'phone-portrait', label: 'Số tài khoản' },
            { icon: 'call', label: 'Số điện thoại' },
            { icon: 'qr-code', label: 'Quét QR' },
            { icon: 'bookmarks', label: 'Mẫu chuyển' },
          ].map((method, i) => (
            <TouchableOpacity key={i} style={styles.methodItem}>
              <View style={styles.methodIcon}>
                  <AppIcon name={method.icon as any} size="md" color={Colors.primary} />
              </View>
              <Text style={styles.methodLabel}>{method.label}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Main input card */}
        <View style={styles.inputCard}>
          <View style={styles.inputWrapper}>
              <AppIcon name="qr-code" size="sm" color={Colors.textSecondary} />
            <Text style={styles.inputPlaceholder}>Nhập số tài khoản hoặc tên người nhận</Text>
            <TouchableOpacity style={styles.scanBtn}>
                <AppIcon name="scan" size="sm" color={Colors.primary} />
            </TouchableOpacity>
          </View>
          <View style={styles.extraActions}>
            <TouchableOpacity>
              <Text style={styles.extraActionText}>📷 Chụp ảnh</Text>
            </TouchableOpacity>
            <Text style={styles.divider}>|</Text>
            <TouchableOpacity>
              <Text style={styles.extraActionText}>🖼 Tải ảnh</Text>
            </TouchableOpacity>
            <Text style={styles.divider}>|</Text>
            <TouchableOpacity>
              <Text style={styles.extraActionText}>📋 Dán</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Recent contacts */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Gần đây</Text>
            <TouchableOpacity>
              <Text style={styles.seeAllText}>Xem tất cả</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.recentList}>
            {['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C'].map((name, i) => (
              <TouchableOpacity key={i} style={styles.recentItem}>
                <View style={styles.recentAvatar}>
                    <AppIcon name="person" size="sm" color={Colors.primary} />
                </View>
                <Text style={styles.recentName}>{name}</Text>
                  <AppIcon name="chevron-forward" size="xs" color={Colors.textSecondary} />
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Partners */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Đối tác liên kết</Text>
          <View style={styles.partnerList}>
            {['Shopee', 'Grab', 'Viettel', 'EVN'].map((partner, i) => (
              <TouchableOpacity key={i} style={styles.partnerItem}>
                <View style={styles.partnerAvatar}>
                  <Text style={styles.partnerInitial}>{partner[0]}</Text>
                </View>
                <Text style={styles.partnerName}>{partner}</Text>
                <View style={styles.partnerBadge}>
                  <Text style={styles.partnerBadgeText}>+99</Text>
                </View>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Saved contacts */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Danh bạ</Text>
          <View style={styles.savedList}>
            {['Nguyễn Văn A', 'Trần Thị B'].map((contact, i) => (
              <TouchableOpacity key={i} style={styles.savedItem}>
                <View style={styles.savedAvatar}>
                    <AppIcon name="person-circle" size="lg" color={Colors.primary} />
                </View>
                <View style={styles.savedInfo}>
                  <Text style={styles.savedName}>{contact}</Text>
                  <Text style={styles.savedAccount}>****1234</Text>
                </View>
                <TouchableOpacity style={styles.transferBtn}>
                  <Text style={styles.transferBtnText}>Chuyển</Text>
                </TouchableOpacity>
              </TouchableOpacity>
            ))}
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
  headerTitle: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  headerIconBtn: {
    width: 36,
    height: 36,
    borderRadius: Radius.sm,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  pageTitle: {
    fontSize: Typography.headingXl.fontSize,
    fontWeight: '800',
    color: Colors.textPrimary,
    marginBottom: Spacing.lg,
  },
  methodScroll: {
    marginBottom: Spacing.lg,
  },
  methodItem: {
    alignItems: 'center',
    marginRight: Spacing.md,
    minWidth: 72,
  },
  methodIcon: {
    width: 56,
    height: 56,
    borderRadius: Radius.lg,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.card,
  },
  methodLabel: {
    
    color: Colors.textPrimary,
    fontWeight: '500',
    marginTop: Spacing.xs,
    textAlign: 'center',
  },
  inputCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.md,
    borderWidth: 1.5,
    borderColor: Colors.primary,
    ...Shadows.card,
    marginBottom: Spacing.lg,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.bgBase,
    borderRadius: Radius.sm,
    paddingHorizontal: Spacing.md,
    height: 48,
  },
  inputPlaceholder: {
    flex: 1,
    
    color: Colors.textSecondary,
    marginLeft: Spacing.sm,
  },
  scanBtn: {
    padding: Spacing.xs,
  },
  extraActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: Spacing.sm,
    gap: Spacing.sm,
  },
  extraActionText: {
    
    color: Colors.primary,
  },
  divider: {
    
    color: Colors.textSecondary,
  },
  section: {
    marginBottom: Spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  sectionTitle: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  seeAllText: {
    
    color: Colors.primary,
    fontWeight: '600',
  },
  recentList: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  recentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
  },
  recentAvatar: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.sm,
  },
  recentName: {
    flex: 1,
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  partnerList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  partnerItem: {
    width: '47%',
    backgroundColor: Colors.surface,
    borderRadius: Radius.sm,
    padding: Spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    ...Shadows.card,
  },
  partnerAvatar: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  partnerInitial: {
    
    fontWeight: '700',
    color: Colors.primary,
  },
  partnerName: {
    flex: 1,
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  partnerBadge: {
    backgroundColor: Colors.warning,
    borderRadius: Radius.xs,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  partnerBadgeText: {
    fontSize: Typography.captionXs.fontSize,
    fontWeight: '700',
    color: Colors.white,
  },
  savedList: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  savedItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
  },
  savedAvatar: {
    marginRight: Spacing.sm,
  },
  savedInfo: {
    flex: 1,
  },
  savedName: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  savedAccount: {
    
    color: Colors.textSecondary,
    marginTop: 2,
  },
  transferBtn: {
    backgroundColor: Colors.primary,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
  },
  transferBtnText: {
    
    fontWeight: '600',
    color: Colors.white,
  },
});
