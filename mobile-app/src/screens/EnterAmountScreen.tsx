import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

interface EnterAmountScreenProps {
  route: any;
  navigation: any;
}

export default function EnterAmountScreen({ route, navigation }: EnterAmountScreenProps) {
  const { recipient } = route.params || { recipient: 'Nguyễn Văn A' };
  const [amount, setAmount] = useState('');
  const [notes, setNotes] = useState('');

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrowLeft" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Nhập số tiền</Text>
          <View style={styles.spacer} />
        </View>
      </BlurView>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Recipient info */}
        <View style={styles.recipientCard}>
          <View style={styles.recipientAvatar}>
            <AppIcon name="profile" size="md" color={Colors.primary} />
          </View>
          <View style={styles.recipientInfo}>
            <Text style={styles.recipientLabel}>Người nhận</Text>
            <Text style={styles.recipientName}>{recipient}</Text>
          </View>
        </View>

        {/* Amount input */}
        <View style={styles.amountSection}>
          <Text style={styles.amountLabel}>Số tiền chuyển</Text>
          <View style={styles.amountDisplay}>
            <Text style={styles.currencySymbol}>VNĐ</Text>
            <Text style={styles.amountValue}>{amount || '0'}</Text>
          </View>
        </View>

        {/* Quick amount chips */}
        <View style={styles.quickAmounts}>
          {['50.000', '100.000', '200.000', '500.000'].map((q) => (
            <TouchableOpacity
              key={q}
              style={styles.quickChip}
              onPress={() => setAmount(q)}
            >
              <Text style={styles.quickChipText}>{q}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Notes input */}
        <View style={styles.notesSection}>
          <Text style={styles.notesLabel}>Ghi chú (tùy chọn)</Text>
          <View style={styles.notesInput}>
            <Text style={styles.notesPlaceholder}>Thêm ghi chú...</Text>
          </View>
        </View>
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title="Tiếp tục"
          onPress={() => navigation.navigate('ConfirmTransfer', { amount, notes })}
          disabled={!amount}
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
    paddingTop: Spacing.xxl,
    paddingHorizontal: Spacing.lg,
  },
  recipientCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
    ...Shadows.card,
  },
  recipientAvatar: {
    width: 48,
    height: 48,
    borderRadius: Radius.pill,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  recipientInfo: {
    flex: 1,
  },
  recipientLabel: {
    
    color: Colors.textSecondary,
  },
  recipientName: {
    
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
  quickAmounts: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  quickChip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    backgroundColor: Colors.primarySoft,
    borderRadius: Radius.pill,
  },
  quickChipText: {
    
    fontWeight: '600',
    color: Colors.primaryDeep,
  },
  notesSection: {
    marginTop: Spacing.md,
  },
  notesLabel: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  notesInput: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.md,
    minHeight: 80,
  },
  notesPlaceholder: {
    
    color: Colors.textSecondary,
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