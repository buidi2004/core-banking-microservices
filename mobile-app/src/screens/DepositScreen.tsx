import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';
import { BankCardRow } from '../components/BankCardRow';
import { QuickAmountChip } from '../components/QuickAmountChip';
import { AmountEntryPad } from '../components/AmountEntryPad';

interface DepositScreenProps {
  navigation: any;
}

export default function DepositScreen({ navigation }: DepositScreenProps) {
  const [amount, setAmount] = useState('');
  const [selectedSource, setSelectedSource] = useState('Vietcombank ****8888');

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Nạp tiền</Text>
        <View style={styles.spacer} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Source card */}
        <TouchableOpacity style={styles.sourceCard} onPress={() => navigation.navigate('BankCardManagement')}>
          <View style={styles.sourceLeft}>
              <AppIcon name="card" size="md" color={Colors.primary} />
            <View style={styles.sourceInfo}>
              <Text style={styles.sourceLabel}>Nguồn nạp tiền</Text>
              <Text style={styles.sourceValue}>{selectedSource}</Text>
            </View>
          </View>
            <AppIcon name="chevron-forward" size="sm" color={Colors.textSecondary} />
        </TouchableOpacity>

        {/* Amount input */}
        <View style={styles.amountSection}>
          <Text style={styles.amountLabel}>Nhập số tiền nạp</Text>
          <View style={styles.amountDisplay}>
            <Text style={styles.currencySymbol}>VNĐ</Text>
            <Text style={styles.amountValue}>{amount || '0'}</Text>
          </View>
        </View>

        {/* Quick amount chips */}
        <View style={styles.quickAmounts}>
          {['50.000', '100.000', '200.000', '500.000', '1.000.000'].map((q) => (
            <QuickAmountChip key={q} value={q} onPress={setAmount} />
          ))}
        </View>

        {/* Amount entry pad */}
        <AmountEntryPad onInputChange={setAmount} />

        {/* Info */}
        <View style={styles.infoCard}>
            <AppIcon name="information-circle" size="sm" color={Colors.primary} />
          <Text style={styles.infoText}>
            Nạp từ 500.000đ nhận ngay voucher giảm giá 50.000đ
          </Text>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title="Tiếp tục"
          onPress={() => navigation.navigate('DepositConfirm')}
          disabled={!amount || parseInt(amount.replace(/\./g, '')) === 0}
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
    fontFamily: 'System',
  },
  quickAmounts: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  infoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    backgroundColor: Colors.warningSoft,
    borderRadius: Radius.md,
    padding: Spacing.md,
    marginBottom: Spacing.xl,
  },
  infoText: {
    flex: 1,
    
    color: Colors.warningText,
    fontWeight: '500',
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
