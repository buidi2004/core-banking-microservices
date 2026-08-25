import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { SearchBar } from '../components/SearchBar';
import { ProviderIconGrid } from '../components/ProviderIconGrid';
import { GroupedListRow } from '../components/GroupedListRow';
import { EmptyState } from '../components/EmptyState';
import { AppText } from '../components/typography/AppText';

interface BillPaymentScreenProps {
  navigation: any;
}

const providers = [
  { icon: 'flash', label: 'Điện' },
  { icon: 'water', label: 'Nước' },
  { icon: 'wifi', label: 'Internet' },
  { icon: 'cellular', label: 'Di động' },
  { icon: 'tv', label: 'Truyền hình' },
  { icon: 'school', label: 'Học phí' },
];

const savedBills = [
  { id: '1', provider: 'Tiền điện', amount: '350.000đ', dueDate: '15/10/2024' },
  { id: '2', provider: 'Tiền nước', amount: '180.000đ', dueDate: '20/10/2024' },
];

export default function BillPaymentScreen({ navigation }: BillPaymentScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Thanh toán hoá đơn</AppText>
        <TouchableOpacity>
            <AppIcon name="time-outline" size="sm" color={Colors.textPrimary} />
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Search bar */}
        <SearchBar
          value={searchQuery}
          onChangeText={setSearchQuery}
          placeholder="Tìm nhà cung cấp..."
        />

        {/* Provider grid */}
        <AppText style={styles.sectionTitle}>Danh mục dịch vụ</AppText>
        <ProviderIconGrid
          providers={providers.map((p) => ({
            ...p,
            onPress: () => navigation.navigate('BillInput', { provider: p.label }),
          }))}
        />

        {/* Saved bills */}
        <AppText style={styles.sectionTitle}>Hoá đơn đã lưu</AppText>
        {savedBills.length === 0 ? (
          <EmptyState title="Chưa có hoá đơn nào" subtitle="Bạn chưa có hóa đơn nào được lưu" />
        ) : (
          <View style={styles.billsList}>
            {savedBills.map((bill, index) => (
              <TouchableOpacity
                key={bill.id}
                style={[styles.billItem, index === savedBills.length - 1 && styles.billItemLast]}
                onPress={() => navigation.navigate('BillInput', { provider: bill.provider })}
              >
                <View style={styles.billLeft}>
                  <AppText style={styles.billProvider}>{bill.provider}</AppText>
                  <AppText style={styles.billDue}>Hạn: {bill.dueDate}</AppText>
                </View>
                <View style={styles.billRight}>
                  <AppText style={styles.billAmount}>{bill.amount}</AppText>
                    <AppIcon name="chevron-forward" size="sm" color={Colors.textSecondary} />
                </View>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </ScrollView>
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
    paddingTop: Spacing.md,
  },
  sectionTitle: {
    
    color: Colors.textPrimary,
    paddingHorizontal: Spacing.lg,
    marginTop: Spacing.md,
    marginBottom: Spacing.sm,
  },
  billsList: {
    marginHorizontal: Spacing.lg,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  billItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
  },
  billItemLast: {
    borderBottomWidth: 0,
  },
  billLeft: {
    gap: 4,
  },
  billProvider: {
    
    color: Colors.textPrimary,
  },
  billDue: {
    
    color: Colors.textSecondary,
  },
  billRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  billAmount: {
    
    color: Colors.primary,
  },
});
