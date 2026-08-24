import React from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { StatusChip } from '../components/StatusChip';
import { SolidCard } from '../components/SolidCard';
import { EmptyState } from '../components/EmptyState';
import { AppText } from '../components/typography/AppText';

interface DeviceManagementScreenProps {
  navigation: any;
}

const mockDevices = [
  { id: '1', name: 'iPhone 15 Pro', lastUsed: 'Hiện tại', current: true, platform: 'iOS' },
  { id: '2', name: 'Samsung Galaxy S24', lastUsed: '2 giờ trước', current: false, platform: 'Android' },
];

export default function DeviceManagementScreen({ navigation }: DeviceManagementScreenProps) {
  const devices = mockDevices;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Thiết bị đã đăng nhập</AppText>
        <TouchableOpacity>
          <AppText style={styles.addBtn}>+ Thêm</AppText>
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {devices.length === 0 ? (
          <EmptyState
            icon="phone-portrait-outline"
            title="Chưa có thiết bị nào"
            subtitle="Thiết bị bạn đăng nhập sẽ hiển thị ở đây"
            actionLabel="Thêm thiết bị"
          />
        ) : (
          <>
            <AppText style={styles.sectionTitle}>Thiết bị hiện tại</AppText>
            {devices.map((device) => (
              <SolidCard key={device.id} style={styles.deviceCard}>
                <View style={styles.deviceHeader}>
                  <LinearGradient
                    colors={[Colors.primarySoft, Colors.deviceIconGradEnd]}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.deviceIcon}
                  >
                    <AppIcon
                      name={device.platform === 'iOS' ? 'phone-portrait' : 'logo-android'}
                      size="lg"
                      color={Colors.primary}
                    />
                  </LinearGradient>
                  <View style={styles.deviceInfo}>
                    <View style={styles.deviceNameRow}>
                      <AppText style={styles.deviceName}>{device.name}</AppText>
                      {device.current && <StatusChip text="Đang dùng" type="success" size="sm" />}
                    </View>
                    <AppText style={styles.devicePlatform}>{device.platform}</AppText>
                    <AppText style={styles.deviceLastUsed}>Sử dụng lần cuối: {device.lastUsed}</AppText>
                  </View>
                </View>
                {!device.current && (
                  <TouchableOpacity style={styles.removeBtn}>
                    <AppText style={styles.removeText}>Gỡ thiết bị</AppText>
                  </TouchableOpacity>
                )}
              </SolidCard>
            ))}

            {/* Security tip */}
            <View style={styles.tipCard}>
                <AppIcon name="information-circle" size="md" color={Colors.primary} />
              <AppText style={styles.tipText}>
                Nếu bạn không nhận ra thiết bị nào, hãy đăng xuất và đổi mật khẩu ngay lập tức.
              </AppText>
            </View>
          </>
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
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },
  headerTitle: {
    
    color: Colors.textPrimary,
  },
  addBtn: {
    
    color: Colors.primary,
    },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  sectionTitle: {
    
    color: Colors.textSecondary,
    marginBottom: Spacing.md,
  },
  deviceCard: {
    marginBottom: Spacing.md,
    padding: Spacing.md,
  },
  deviceHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  deviceIcon: {
    width: 56,
    height: 56,
    borderRadius: Radius.sm,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deviceInfo: {
    flex: 1,
    gap: 4,
  },
  deviceNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  deviceName: {
    
    color: Colors.textPrimary,
  },
  devicePlatform: {
    
    color: Colors.textSecondary,
  },
  deviceLastUsed: {
    
    color: Colors.textSecondary,
  },
  removeBtn: {
    marginTop: Spacing.md,
    alignSelf: 'flex-start',
    paddingVertical: Spacing.xs,
    paddingHorizontal: Spacing.md,
  },
  removeText: {
    
    color: Colors.danger,
    },
  tipCard: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: Spacing.sm,
    padding: Spacing.md,
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.md,
    marginTop: Spacing.lg,
  },
  tipText: {
    flex: 1,
    
    color: Colors.primary,
    lineHeight: 18,
  },
});
