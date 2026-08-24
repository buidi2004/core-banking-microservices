import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
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

interface WithdrawScreenProps {
  navigation: any;
}

export default function WithdrawScreen({ navigation }: WithdrawScreenProps) {
  const [amount, setAmount] = useState('');
  const [selectedBank] = useState('Ngân hàng A ****8888');
  const balance = 5500000;
  const amountNum = parseInt(amount.replace(/\./g, '') || '0');
  const isExceedBalance = amountNum > balance;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <AppIcon name="arrowLeft" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Rút tiền</Text>
        <View style={styles.spacer} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Target bank card */}
        <TouchableOpacity style={styles.sourceCard} onPress={() => navigation.navigate('BankCardManagement')}>
          <View style={styles.sourceLeft}>
            <AppIcon name="card" size="lg" color={Colors.primary} />
            <View style={styles.sourceInfo}>
              <Text style={styles.sourceLabel}>Ngân hàng nhận</Text>
              <Text style={styles.sourceValue}>{selectedBank}</Text>
            </View>
          </View>
          <AppIcon name="chevronRight" size="md" color={Colors.textSecondary} />
        </TouchableOpacity>

        {/* Amount input */}
        <View style={styles.amountSection}>
          <Text style={styles.amountLabel}>Số tiền rút</Text>
          <View style={styles.amountDisplay}>
            <Text style={styles.currencySymbol}>VNĐ</Text>
            <Text style={styles.amountValue}>{amount || '0'}</Text>
          </View>
          <Text style={styles.balanceHint}>Số dư khả dụng: {balance.toLocaleString()} VNĐ</Text>
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
            <Text style={styles.feeLabel}>Phí rút tiền</Text>
            <Text style={styles.feeValue}>Miễn phí</Text>
          </View>
          <View style={styles.feeRow}>
            <Text style={styles.feeLabel}>Thời gian xử lý</Text>
            <Text style={styles.feeValue}>Trong ngày</Text>
          </View>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title="Xác nhận rút tiền"
          onPress={() => navigation.navigate('WithdrawConfirm')}
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
    
    fontWeight: '700',
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
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  amountSection: {
    marginTop: Spacing.xl,
    marginBottom: Spacing.lg,
  },
  amountLabel: {
    
    fontWeight: '700',
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
    
    fontWeight: '600',
    color: Colors.textSecondary,
    marginRight: Spacing.sm,
  },
  amountValue: {
    fontSize: Typography.display.fontSize,
    fontWeight: '800',
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
    
    fontWeight: '600',
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