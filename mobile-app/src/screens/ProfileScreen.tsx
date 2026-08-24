import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView, Image } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';

interface ProfileScreenProps {
  navigation: any;
}

export default function ProfileScreen({ navigation }: ProfileScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>Hồ sơ</Text>
          <TouchableOpacity>
              <AppIcon name="settings-outline" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </BlurView>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Profile header */}
        <View style={styles.profileHeader}>
          <Image source={{ uri: 'https://i.pravatar.cc/150' }} style={styles.profileAvatar} />
          <View style={styles.profileInfo}>
            <Text style={styles.profileName}>Nguyễn Văn A</Text>
            <Text style={styles.profilePhone}>0901 234 567</Text>
          </View>
          <TouchableOpacity style={styles.editBtn}>
            <Text style={styles.editBtnText}>Chỉnh sửa</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.closeBtn} onPress={() => navigation.goBack()}>
            <Text style={styles.closeText}>✕</Text>
          </TouchableOpacity>
        </View>

        {/* Menu items */}
        <View style={styles.menuContainer}>
          {[
            { icon: 'person', label: 'Thông tin cá nhân' },
            { icon: 'shield-checkmark', label: 'Bảo mật' },
            { icon: 'phone-portrait', label: 'Quản lý thiết bị' },
            { icon: 'card', label: 'Phương thức thanh toán' },
            { icon: 'help-circle', label: 'Trung tâm trợ giúp' },
          ].map((item, i, arr) => (
            <TouchableOpacity
              key={item.label}
              style={[
                styles.menuItem,
                i === 0 && styles.itemFirst,
                i === arr.length - 1 && styles.itemLast,
              ]}
            >
              <View style={styles.menuItemLeft}>
                <View style={styles.iconBg}>
                    <AppIcon name={item.icon as any} size="sm" color={Colors.primary} />
                </View>
                <Text style={styles.menuItemLabel}>{item.label}</Text>
              </View>
                <AppIcon name="chevron-forward" size="sm" color={Colors.textSecondary} />
            </TouchableOpacity>
          ))}
        </View>

        {/* Language setting */}
        <View style={styles.languageRow}>
          <View style={styles.menuItemLeft}>
            <View style={styles.iconBg}>
                <AppIcon name="language" size="sm" color={Colors.primary} />
            </View>
            <Text style={styles.menuItemLabel}>Ngôn ngữ</Text>
          </View>
          <View style={styles.languageValue}>
            <Text style={styles.languageText}>Tiếng Việt</Text>
              <AppIcon name="chevron-forward" size="sm" color={Colors.textSecondary} />
          </View>
        </View>

        {/* Logout */}
        <TouchableOpacity style={styles.logoutBtn}>
            <AppIcon name="log-out-outline" size="sm" color={Colors.danger} />
          <Text style={styles.logoutText}>Đăng xuất</Text>
        </TouchableOpacity>

        {/* Version */}
        <Text style={styles.versionText}>E-Wallet v1.0.0</Text>
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
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },
  headerTitle: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  scrollView: {
    flex: 1,
  },
  profileHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.lg,
    gap: Spacing.md,
  },
  profileAvatar: {
    width: 64,
    height: 64,
    borderRadius: Radius.xl,
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: 4,
  },
  profilePhone: {
    
    color: Colors.textSecondary,
  },
  editBtn: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.pill,
  },
  editBtnText: {
    
    fontWeight: '600',
    color: Colors.primary,
  },
  closeBtn: {
    width: 32,
    height: 32,
    borderRadius: Radius.sm,
    backgroundColor: Colors.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeText: {
    
    color: Colors.textPrimary,
  },
  menuContainer: {
    marginHorizontal: Spacing.lg,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
  },
  itemFirst: {
    borderTopLeftRadius: Radius.sm,
    borderTopRightRadius: Radius.sm,
  },
  itemLast: {
    borderBottomLeftRadius: Radius.sm,
    borderBottomRightRadius: Radius.sm,
    borderBottomWidth: 0,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  iconBg: {
    width: 36,
    height: 36,
    borderRadius: Radius.xs,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  menuItemLabel: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  languageRow: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.sm,
    backgroundColor: Colors.surface,
    borderRadius: Radius.sm,
    padding: Spacing.md,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    ...Shadows.card,
  },
  languageValue: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  languageText: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.sm,
    marginTop: Spacing.xl,
    marginBottom: Spacing.md,
    paddingHorizontal: Spacing.lg,
  },
  logoutText: {
    
    fontWeight: '600',
    color: Colors.danger,
  },
  versionText: {
    textAlign: 'center',
    
    color: Colors.textSecondary,
    marginBottom: Spacing.lg,
  },
});
