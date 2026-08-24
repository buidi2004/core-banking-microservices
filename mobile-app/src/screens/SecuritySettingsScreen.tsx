import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';

interface SecuritySettingsScreenProps {
  navigation: any;
}

export default function SecuritySettingsScreen({ navigation }: SecuritySettingsScreenProps) {
  const items = [
    { icon: 'finger-print' as const, label: 'Đổi PIN', desc: 'Cập nhật mã PIN 6 chữ số', screen: 'SetPin' },
    { icon: 'lock-closed' as const, label: 'Đổi mật khẩu', desc: 'Bảo vệ tài khoản của bạn', screen: null },
    { icon: 'shield-checkmark' as const, label: 'Xác thực 2 yếu tố', desc: 'Bật xác thực OTP', screen: null },
    { icon: 'eye-off' as const, label: 'Ẩn số dư', desc: 'Tắt hiển thị số dư mặc định', screen: null },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Bảo mật</Text>
        <View style={styles.spacer} />
      </View>

      <View style={styles.listContainer}>
        {items.map((item, index) => (
          <TouchableOpacity
            key={index}
            style={[
              styles.item,
              index === 0 && styles.itemFirst,
              index === items.length - 1 && styles.itemLast,
            ]}
            onPress={() => item.screen && navigation.navigate(item.screen)}
          >
            <View style={styles.itemLeft}>
              <View style={styles.iconBg}>
                  <AppIcon name={item.icon} size="sm" color={Colors.primary} />
              </View>
              <View style={styles.itemText}>
                <Text style={styles.itemLabel}>{item.label}</Text>
                <Text style={styles.itemDesc}>{item.desc}</Text>
              </View>
            </View>
              <AppIcon name="chevron-forward" size="sm" color={Colors.textSecondary} />
          </TouchableOpacity>
        ))}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
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
  spacer: {
    width: 40,
  },
  listContainer: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.md,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
  },
  item: {
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
  itemLeft: {
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
  itemText: {
    gap: 4,
  },
  itemLabel: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  itemDesc: {
    
    color: Colors.textSecondary,
  },
});
