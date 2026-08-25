import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { AppText } from '../components/typography/AppText';

interface BillInputScreenProps {
  route: any;
  navigation: any;
}

export default function BillInputScreen({ route, navigation }: BillInputScreenProps) {
  const { provider } = route.params || { provider: 'Tiền điện' };
  const [customerId, setCustomerId] = useState('');
  const [isValid, setIsValid] = useState(false);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>{provider}</AppText>
        <TouchableOpacity>
            <AppIcon name="scan" size="sm" color={Colors.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Input card */}
        <View style={[styles.inputCard, isValid && styles.inputCardValid]}>
          <View style={styles.inputHeader}>
              <AppIcon name={provider === 'Tiền điện' ? 'flash' : 'water'} size="md" color={Colors.primary} />
            <AppText style={styles.inputLabel}>Mã khách hàng / Số hợp đồng</AppText>
          </View>
          <View style={styles.inputWrapper}>
              <AppIcon name="barcode-outline" size="sm" color={Colors.textSecondary} />
            <AppText style={styles.inputPlaceholder}>Nhập mã khách hàng...</AppText>
          </View>
          {isValid && (
            <AppText style={styles.validText}>✓ Mã hợp lệ</AppText>
          )}
        </View>

        {/* Preview card */}
        {isValid && (
          <View style={styles.previewCard}>
            <AppText style={styles.previewLabel}>Thông tin thanh toán</AppText>
            <View style={styles.previewRow}>
              <AppText style={styles.previewField}>Khách hàng</AppText>
              <AppText style={styles.previewValue}>Nguyễn Văn A</AppText>
            </View>
            <View style={styles.previewRow}>
              <AppText style={styles.previewField}>Kỳ thanh toán</AppText>
              <AppText style={styles.previewValue}>Tháng 10/2024</AppText>
            </View>
            <View style={[styles.previewRow, styles.totalRow]}>
              <AppText style={styles.previewField}>Số tiền cần trả</AppText>
              <AppText variant="headingSm" style={styles.totalAmount}>350.000 VNĐ</AppText>
            </View>
          </View>
        )}
      </ScrollView>

      <View style={styles.footer}>
        <PrimaryButton
          title={`Thanh toán • ${isValid ? '350.000đ' : 'Nhập mã khách hàng'}`}
          onPress={() => navigation.navigate('BillConfirm', { provider, billId: customerId, amount: 350000 })}
          disabled={!isValid}
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
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  inputCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.md,
    borderWidth: 1.5,
    borderColor: Colors.primarySoft,
    ...Shadows.card,
  },
  inputCardValid: {
    borderColor: Colors.primary,
  },
  inputHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.sm,
  },
  inputLabel: {
    
    color: Colors.textPrimary,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.bgBase,
    borderRadius: Radius.sm,
    paddingHorizontal: Spacing.md,
    height: 48,
  },
  inputPlaceholder: {
    flex: 1,
    
    color: Colors.textSecondary,
    marginLeft: Spacing.sm,
  },
  validText: {
    
    color: Colors.success,
    marginTop: Spacing.sm,
  },
  previewCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    marginTop: Spacing.lg,
    ...Shadows.card,
  },
  previewLabel: {
    
    color: Colors.textPrimary,
    marginBottom: Spacing.md,
  },
  previewRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
  },
  previewField: {
    
    color: Colors.textSecondary,
  },
  previewValue: {
    
    color: Colors.textPrimary,
  },
  totalRow: {
    borderTopWidth: 1,
    borderTopColor: Colors.primarySoft,
    marginTop: Spacing.sm,
    paddingTop: Spacing.md,
  },
  totalAmount: {
    color: Colors.primary,
  },
  footer: {
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.lg,
  },
});
