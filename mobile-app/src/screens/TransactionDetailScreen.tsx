import React from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { AppText } from '../components/typography/AppText';

interface TransactionDetailScreenProps {
  route: any;
  navigation: any;
}

export default function TransactionDetailScreen({ route, navigation }: TransactionDetailScreenProps) {
  const { transaction } = route.params || {};

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
            right={<AppText style={styles.statusSuccess}>Hoàn thành</AppText>}
          />
        </View>

        {/* Detail card */}
        <View style={styles.detailCard}>
          {[
            { label: 'Loại giao dịch', value: transaction?.type === 'credit' ? 'Tiền vào' : 'Tiền ra' },
            { label: 'Người nhận/Gửi', value: transaction?.name || '—' },
            { label: 'Số tiền', value: transaction?.amount || '—' },
            { label: 'Thời gian', value: transaction?.date || '12/10/2024 14:30' },
            { label: 'Mã giao dịch', value: 'TXN' + Math.random().toString(36).substr(2, 9).toUpperCase() },
            { label: 'Phí', value: 'Miễn phí' },
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
