import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

interface TransferResultScreenProps {
  route: any;
  navigation: any;
}

export default function TransferResultScreen({ route, navigation }: TransferResultScreenProps) {
  const { success } = route.params || { success: true };

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur} />

      <View style={styles.content}>
        {/* Success/Failure icon */}
        <View style={[
          styles.iconCircle,
          { backgroundColor: success ? Colors.successSoft : Colors.dangerSoft }
        ]}>
          <AppIcon
            name={success ? 'checkmark-circle' : 'close-circle'}
            size="xxxl"
            color={success ? Colors.success : Colors.danger}
          />
        </View>

        <Text style={styles.title}>
          {success ? 'Giao dịch thành công!' : 'Giao dịch thất bại'}
        </Text>

        <View style={styles.amountCard}>
          <Text style={styles.amountLabel}>Số tiền đã chuyển</Text>
          <Text style={styles.amountValue}>500.000 VNĐ</Text>
        </View>

        <View style={styles.infoCard}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Người nhận</Text>
            <Text style={styles.infoValue}>Nguyễn Văn A</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Mã giao dịch</Text>
            <Text style={styles.infoValue}>TXN{Date.now().toString().slice(-6)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Thời gian</Text>
            <Text style={styles.infoValue}>12/10/2024 14:30</Text>
          </View>
        </View>

        <View style={styles.buttonGroup}>
          <PrimaryButton
            title="Về trang chủ"
            onPress={() => navigation.navigate('MainTabs')}
          />
          <SecondaryButton
            title="Xem lịch sử"
            onPress={() => navigation.navigate('History')}
            style={styles.secondaryBtn}
          />
        </View>
      </View>
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
  content: {
    flex: 1,
    paddingHorizontal: Spacing.xxl,
    paddingTop: Spacing.xxl,
  },
  iconCircle: {
    width: 120,
    height: 120,
    borderRadius: Radius.xl,
    justifyContent: 'center',
    alignItems: 'center',
    alignSelf: 'center',
    marginBottom: Spacing.lg,
  },
  title: {
    fontSize: Typography.heading.fontSize,
    fontWeight: '700',
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },
  amountCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.xl,
    alignItems: 'center',
    marginBottom: Spacing.md,
    ...Shadows.card,
  },
  amountLabel: {
    
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  amountValue: {
    fontSize: Typography.headingLg.fontSize,
    fontWeight: '800',
    color: Colors.primary,
  },
  infoCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    marginTop: Spacing.md,
    ...Shadows.card,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
  },
  infoLabel: {
    
    color: Colors.textSecondary,
  },
  infoValue: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.primarySoft,
    marginVertical: Spacing.sm,
  },
  buttonGroup: {
    marginTop: Spacing.xxl,
    gap: Spacing.md,
  },
  secondaryBtn: {
    marginTop: 0,
  },
});
