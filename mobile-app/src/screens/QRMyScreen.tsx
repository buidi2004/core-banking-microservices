import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView, Image } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { StatusChip } from '../components/StatusChip';

interface QRMyScreenProps {
  navigation: any;
}

export default function QRMyScreen({ navigation }: QRMyScreenProps) {
  const [isAnimated, setIsAnimated] = useState(false);
  const [expiryCountdown] = useState('04:32');

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
              <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>QR của tôi</Text>
          <View style={styles.spacer} />
        </View>
      </BlurView>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* QR Card */}
        <View style={styles.qrCardContainer}>
          <View style={styles.qrCard}>
            {/* QR Code placeholder */}
            <View style={styles.qrCodeArea}>
                <AppIcon name="qr-code" size="huge" color={Colors.textPrimary} />
            </View>
            
            {/* User info */}
            <View style={styles.qrUserInfo}>
              <Image source={{ uri: 'https://i.pravatar.cc/100' }} style={styles.userAvatar} />
              <View style={styles.userInfoText}>
                <Text style={styles.userName}>Nguyễn Văn A</Text>
                <Text style={styles.userId}>ID: 884729103</Text>
              </View>
            </View>

            {/* Expiry badge */}
            <View style={styles.expiryBadge}>
                <AppIcon name="timer" size="xs" color={Colors.warning} />
              <Text style={styles.expiryText}>Hết hạn sau {expiryCountdown}</Text>
            </View>
          </View>
        </View>

        {/* Toggle switch */}
        <View style={styles.toggleSection}>
          <Text style={styles.toggleLabel}>QR tĩnh</Text>
          <TouchableOpacity
            style={[styles.toggleSwitch, isAnimated && styles.toggleSwitchActive]}
            onPress={() => setIsAnimated(!isAnimated)}
          >
            <View style={[styles.toggleDot, isAnimated && styles.toggleDotActive]} />
          </TouchableOpacity>
          <Text style={styles.toggleLabel}>QR động</Text>
        </View>

        {/* Info card */}
        <View style={styles.infoCard}>
            <AppIcon name="information-circle" size="md" color={Colors.primary} />
          <Text style={styles.infoText}>
            QR động được cập nhật mỗi 5 phút để tăng cường bảo mật.
          </Text>
        </View>

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity style={styles.actionBtn}>
              <AppIcon name="download" size="sm" color={Colors.primary} />
            <Text style={styles.actionText}>Tải về</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionBtn}>
              <AppIcon name="share-social" size="sm" color={Colors.primary} />
            <Text style={styles.actionText}>Chia sẻ</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionBtn}>
              <AppIcon name="refresh" size="sm" color={Colors.primary} />
            <Text style={styles.actionText}>Làm mới</Text>
          </TouchableOpacity>
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
  spacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
    paddingBottom: Spacing.xxl,
  },
  qrCardContainer: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.xl,
  },
  qrCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.lg,
    padding: Spacing.xxl,
    alignItems: 'center',
    ...Shadows.hero,
  },
  qrCodeArea: {
    padding: Spacing.md,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
  },
  qrUserInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: Spacing.md,
    gap: Spacing.sm,
  },
  userAvatar: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
  },
  userInfoText: {
    gap: 4,
  },
  userName: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  userId: {
    
    color: Colors.textSecondary,
  },
  expiryBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
    marginTop: Spacing.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    backgroundColor: Colors.warningSoft,
    borderRadius: Radius.pill,
  },
  expiryText: {
    
    fontWeight: '600',
    color: Colors.warningText,
  },
  toggleSection: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.md,
    marginTop: Spacing.xxl,
  },
  toggleLabel: {
    
    fontWeight: '600',
    color: Colors.textSecondary,
  },
  toggleSwitch: {
    width: 52,
    height: 30,
    borderRadius: Radius.sm,
    backgroundColor: Colors.primarySoft,
    padding: 2,
  },
  toggleSwitchActive: {
    backgroundColor: Colors.primary,
  },
  toggleDot: {
    width: 26,
    height: 26,
    borderRadius: Radius.xs,
    backgroundColor: Colors.surface,
  },
  toggleDotActive: {
    marginLeft: 26,
  },
  infoCard: {
    marginHorizontal: Spacing.lg,
    marginTop: Spacing.xl,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: Spacing.sm,
    padding: Spacing.md,
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.md,
  },
  infoText: {
    flex: 1,
    
    color: Colors.primary,
    lineHeight: 18,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: Spacing.xxl,
    paddingHorizontal: Spacing.lg,
  },
  actionBtn: {
    alignItems: 'center',
    gap: Spacing.xs,
  },
  actionText: {
    
    color: Colors.primary,
    fontWeight: '600',
  },
});
