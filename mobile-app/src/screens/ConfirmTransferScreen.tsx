import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

interface ConfirmTransferScreenProps {
  route: any;
  navigation: any;
}

export default function ConfirmTransferScreen({ route, navigation }: ConfirmTransferScreenProps) {
  const { recipient, amount } = route.params || {};

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
              <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Xác nhận chuyển tiền</Text>
          <View style={styles.spacer} />
        </View>
      </BlurView>

      <View style={styles.content}>
        {/* Summary card */}
        <View style={styles.summaryCard}>
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Người nhận</Text>
            <Text style={styles.summaryValue}>{recipient?.name || 'Người nhận'}</Text>
          </View>
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Số điện thoại</Text>
            <Text style={styles.summaryValue}>{recipient?.phone || ''}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Số tiền</Text>
            <Text style={styles.amountValue}>{amount} VNĐ</Text>
          </View>
        </View>

        {/* Fee info */}
        <View style={styles.feeCard}>
          <View style={styles.feeRow}>
            <Text style={styles.feeLabel}>Phí giao dịch</Text>
            <Text style={styles.feeValue}>Miễn phí</Text>
          </View>
          <View style={styles.feeRow}>
            <Text style={styles.feeLabel}>Tổng thanh toán</Text>
            <Text style={styles.totalValue}>{amount} VNĐ</Text>
          </View>
        </View>

        <PrimaryButton
          title="Xác nhận chuyển"
          onPress={() => navigation.navigate('TransferResult', { success: true })}
        />

        <SecondaryButton
          title="Quay lại"
          onPress={() => navigation.goBack()}
          style={styles.secondaryBtn}
        />
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
  content: {
    flex: 1,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.xl,
  },
  summaryCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    ...Shadows.card,
    marginBottom: Spacing.lg,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
  },
  summaryLabel: {
    
    color: Colors.textSecondary,
  },
  summaryValue: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  amountValue: {
    
    fontWeight: '800',
    color: Colors.primary,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.primarySoft,
    marginVertical: Spacing.sm,
  },
  feeCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    ...Shadows.card,
    marginBottom: Spacing.xxl,
  },
  feeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
  },
  feeLabel: {
    
    color: Colors.textSecondary,
  },
  feeValue: {
    
    fontWeight: '600',
    color: Colors.success,
  },
  totalValue: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  secondaryBtn: {
    marginTop: Spacing.md,
  },
});
