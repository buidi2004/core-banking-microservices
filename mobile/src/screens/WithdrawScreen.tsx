import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';
import { BankCardRow } from '../components/BankCardRow';
import { QuickAmountChip } from '../components/QuickAmountChip';
import { AmountEntryPad } from '../components/AmountEntryPad';
import { StatusChip } from '../components/StatusChip';
import { AppText } from '../components/typography/AppText';

interface WithdrawScreenProps {
  navigation: any;
}

import { useApp } from '../context/AppContext';

export default function WithdrawScreen({ navigation }: WithdrawScreenProps) {
  const { wallet } = useApp();
  const [amount, setAmount] = useState('');
  const [selectedBank] = useState('');
  
  const balance = wallet?.balance || 0;
  const amountNum = parseInt(amount.replace(/\./g, '') || '0');
  const isExceedBalance = amountNum > balance;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <AppIcon name="arrowLeft" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Rút tiền</AppText>
        <View style={styles.spacer} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Target bank card */}
        <TouchableOpacity style={styles.sourceCard} onPress={() => navigation.navigate('BankCardManagement')}>
          <View style={styles.sourceLeft}>
            <AppIcon name="card" size="lg" color={Colors.primary} />
            <View style={styles.sourceInfo}>
              <AppText style={styles.sourceLabel}>Ngân hàng nhận</AppText>
              <AppText style={styles.sourceValue}>{selectedBank}</AppText>
            </View>
          </View>
          <AppIcon name="chevronRight" size="md" color={Colors.textSecondary} />
        </TouchableOpacity>

        {/* Amount input */}
        <View style={styles.amountSection}>
          <AppText style={styles.amountLabel}>Số tiền rút</AppText>
          <View style={styles.amountDisplay}>
            <AppText style={styles.currencySymbol}>VNĐ</AppText>
            <AppText variant="display" style={styles.amountValue}>{amount || '0'}</AppText>
          </View>
          <AppText style={styles.balanceHint}>Số dư khả dụng: {balance.toLocaleString('vi-VN')} VNĐ</AppText>
          {isExceedBalance && (
            <View style={styles.warningContainer}>
              <StatusChip text="Vượt quá số dư" type="warning" size="sm" />
            </View>
          )}
        </View>

        {/* Quick amount chips */}
        <View style={styles.quickAmounts}>
          {['50.000', '100.000', '200.000', '500.000'].map((q) => (
            <QuickAmountChip key={q} value={q} onPress={setAmount} />
          ))}
        </View>

        {/* Amount entry pad */}
        <AmountEntryPad onInputChange={setAmount} />

        {/* Fee info */}
        <View style={styles.feeCard}>
          <View style={styles.feeRow}>
            <AppText style={styles.feeLabel}>Phí rút tiền</AppText>
            <AppText style={styles.feeValue}>Miễn phí</AppText>
          </View>
          <View style={styles.feeRow}>
            <AppText style={styles.feeLabel}>Thời gian xử lý</AppText>
            <AppText style={styles.feeValue}>Trong ngày</AppText>
          </View>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title="Xác nhận rút tiền"
          onPress={() => navigation.navigate('WithdrawConfirm', { amount, selectedBank })}
          disabled={!amount || amountNum === 0 || isExceedBalance}
        />
        <SecondaryButton title="Hủy" onPress={() => navigation.goBack()} style={styles.secondaryBtn} />
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
    
    color: Colors.textPrimary,
  },
  spacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  sourceCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    ...Shadows.card,
  },
  sourceLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  sourceInfo: {
    gap: 4,
  },
  sourceLabel: {
    
    color: Colors.textSecondary,
  },
  sourceValue: {
    
    color: Colors.textPrimary,
  },
  amountSection: {
    marginTop: Spacing.xl,
    marginBottom: Spacing.lg,
  },
  amountLabel: {
    
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  amountDisplay: {
    flexDirection: 'row',
    alignItems: 'baseline',
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.xl,
    ...Shadows.card,
  },
  currencySymbol: {
    
    color: Colors.textSecondary,
    marginRight: Spacing.sm,
  },
  amountValue: {
    color: Colors.primary,
  },
  balanceHint: {
    
    color: Colors.textSecondary,
    marginTop: Spacing.sm,
  },
  warningContainer: {
    marginTop: Spacing.sm,
  },
  quickAmounts: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  feeCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    marginBottom: Spacing.xl,
    ...Shadows.card,
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
    
    color: Colors.textPrimary,
  },
  footer: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.lg,
    gap: Spacing.md,
  },
  secondaryBtn: {
    marginTop: 0,
  },
});