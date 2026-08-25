import React, { useState, useEffect } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { StatusChip } from '../components/StatusChip';
import { SolidCard } from '../components/SolidCard';
import { EmptyState } from '../components/EmptyState';
import { AppText } from '../components/typography/AppText';
import { WalletApi } from '../services/api';

interface DeviceManagementScreenProps {
  navigation: any;
}

interface DeviceSession {
  id: string;
  deviceId: string;
  ipAddress: string;
  userAgent: string;
  active: boolean;
  lastActiveAt: string;
  isCurrent?: boolean; // We'll infer this
}

export default function DeviceManagementScreen({ navigation }: DeviceManagementScreenProps) {
  const [sessions, setSessions] = useState<DeviceSession[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchSessions = async () => {
    try {
      setIsLoading(true);
      const res = await WalletApi.getActiveSessions();
      if (res.data) {
        // Find the most recently active session to mark as 'current'
        // Alternatively, the backend could tell us which one is the current token's session.
        const sorted = res.data.sort((a: any, b: any) => 
          new Date(b.lastActiveAt).getTime() - new Date(a.lastActiveAt).getTime()
        );
        if (sorted.length > 0) {
          sorted[0].isCurrent = true;
        }
        setSessions(sorted);
      }
    } catch (e) {
      console.warn('Failed to fetch sessions:', e);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchSessions();
  }, []);

  const handleRevoke = (deviceId: string, deviceName: string) => {
    Alert.alert(
      'Gỡ thiết bị',
      `Bạn có chắc chắn muốn đăng xuất khỏi thiết bị "${deviceName}"?`,
      [
        { text: 'Hủy', style: 'cancel' },
        {
          text: 'Gỡ thiết bị',
          style: 'destructive',
          onPress: async () => {
            try {
              setIsLoading(true);
              await WalletApi.revokeSession(deviceId);
              await fetchSessions();
            } catch (e: any) {
              Alert.alert('Lỗi', e.message || 'Không thể gỡ thiết bị.');
              setIsLoading(false);
            }
          }
        }
      ]
    );
  };

  const getPlatform = (ua: string) => {
    if (!ua) return 'Unknown';
    if (ua.toLowerCase().includes('iphone') || ua.toLowerCase().includes('ios') || ua.toLowerCase().includes('mac')) return 'iOS';
    if (ua.toLowerCase().includes('android')) return 'Android';
    if (ua.toLowerCase().includes('windows')) return 'Windows';
    return 'Web/Khác';
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Thiết bị đã đăng nhập</AppText>
        <TouchableOpacity onPress={fetchSessions}>
          <AppIcon name="refresh" size="sm" color={Colors.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {isLoading ? (
          <ActivityIndicator size="large" color={Colors.primary} style={{ marginTop: 40 }} />
        ) : sessions.length === 0 ? (
          <EmptyState
            icon="phone-portrait-outline"
            title="Chưa có thiết bị nào"
            subtitle="Thiết bị bạn đăng nhập sẽ hiển thị ở đây"
          />
        ) : (
          <>
            <AppText style={styles.sectionTitle}>Thiết bị hiện tại</AppText>
            {sessions.map((device) => {
              const platform = getPlatform(device.userAgent);
              const name = device.userAgent.split(' ')[0] || device.deviceId;
              const date = new Date(device.lastActiveAt).toLocaleString('vi-VN');

              return (
                <SolidCard key={device.id} style={styles.deviceCard}>
                  <View style={styles.deviceHeader}>
                    <LinearGradient
                      colors={[Colors.primarySoft, Colors.deviceIconGradEnd]}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 1 }}
                      style={styles.deviceIcon}
                    >
                      <AppIcon
                        name={platform === 'iOS' ? 'phone-portrait' : (platform === 'Android' ? 'logo-android' : 'laptop-outline')}
                        size="lg"
                        color={Colors.primary}
                      />
                    </LinearGradient>
                    <View style={styles.deviceInfo}>
                      <View style={styles.deviceNameRow}>
                        <AppText style={styles.deviceName} numberOfLines={1}>{name}</AppText>
                        {device.isCurrent && <StatusChip text="Đang dùng" type="success" size="sm" />}
                      </View>
                      <AppText style={styles.devicePlatform}>{platform} • {device.ipAddress}</AppText>
                      <AppText style={styles.deviceLastUsed}>Lần cuối: {date}</AppText>
                    </View>
                  </View>
                  {!device.isCurrent && (
                    <TouchableOpacity style={styles.removeBtn} onPress={() => handleRevoke(device.deviceId, name)}>
                      <AppText style={styles.removeText}>Gỡ thiết bị</AppText>
                    </TouchableOpacity>
                  )}
                </SolidCard>
              );
            })}

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
