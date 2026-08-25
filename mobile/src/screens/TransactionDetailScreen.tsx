import React from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { AppText } from '../components/typography/AppText';

import { useApp } from '../context/AppContext';

interface TransactionDetailScreenProps {
  route: any;
  navigation: any;
}

export default function TransactionDetailScreen({ route, navigation }: TransactionDetailScreenProps) {
  const { user } = useApp();
  const { transaction } = route.params || {};
  
  const isCredit = transaction?.type === 'DEPOSIT' || (transaction?.type === 'TRANSFER' && transaction?.targetWalletId === user?.walletId);
  const typeText = transaction?.type === 'DEPOSIT' ? 'Nạp tiền' : (transaction?.type === 'WITHDRAWAL' ? 'Rút tiền' : 'Chuyển tiền');
  const amountStr = `${isCredit ? '+' : '-'}${transaction?.amount?.toLocaleString('vi-VN') || 0} đ`;
  
  const txDateStr = transaction?.timestamp || transaction?.createdAt;
  const dateStr = txDateStr ? new Date(txDateStr).toLocaleString('vi-VN') : '—';
  
  const txId = transaction?.transactionId || transaction?.id || '—';

  return (
    <SafeAreaView style={styles.container}>
      <BlurView intensity={70} tint="light" style={styles.headerBlur}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
              <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <AppText style={styles.headerTitle}>Chi tiết giao dịch</AppText>
          <TouchableOpacity>
              <AppIcon name="share-outline" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
        </View>
      </BlurView>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Status chip */}
        <View style={styles.statusContainer}>
          <GroupedListRow
            title="Trạng thái"
            right={<AppText style={styles.statusSuccess}>{transaction?.status === 'COMPLETED' ? 'Hoàn thành' : transaction?.status || 'Hoàn thành'}</AppText>}
          />
        </View>

        {/* Detail card */}
        <View style={styles.detailCard}>
          {[
            { label: 'Loại giao dịch', value: typeText },
            { label: 'Người nhận/Gửi', value: transaction?.targetWalletId || 'N/A' },
            { label: 'Số tiền', value: amountStr },
            { label: 'Thời gian', value: dateStr },
            { label: 'Mã giao dịch', value: txId },
            { label: 'Phí', value: transaction?.feeAmount ? `${transaction.feeAmount.toLocaleString('vi-VN')} đ` : 'Miễn phí' },
          ].map((item, i) => (
            <View key={i} style={styles.detailRow}>
              <AppText style={styles.detailLabel}>{item.label}</AppText>
              <AppText style={[styles.detailValue, item.label === 'Số tiền' && styles.amountValue]}>
                {item.value}
              </AppText>
              {i < 5 && <View style={styles.divider} />}
            </View>
          ))}
        </View>

        {/* Footer */}
        <View style={styles.footer}>
          <TouchableOpacity style={styles.reportBtn}>
            <AppText style={styles.reportText}>Báo cáo vấn đề</AppText>
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
    
    color: Colors.textPrimary,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.md,
  },
  statusContainer: {
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  detailCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    marginHorizontal: Spacing.lg,
    padding: Spacing.lg,
    ...Shadows.card,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  detailLabel: {
    
    color: Colors.textSecondary,
  },
  detailValue: {
    
    color: Colors.textPrimary,
  },
  amountValue: {
    
    color: Colors.primary,
  },
  statusSuccess: {
    
    color: Colors.success,
  },
  divider: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 1,
    backgroundColor: Colors.primarySoft,
  },
  footer: {
    marginTop: Spacing.xxl,
    marginBottom: Spacing.xl,
    alignItems: 'center',
  },
  reportBtn: {
    padding: Spacing.md,
  },
  reportText: {
    
    color: Colors.danger,
    },
});
