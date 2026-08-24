import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { AppText } from '../components/typography/AppText';

interface Transaction {
  name: string;
  amount: string;
  date: string;
  icon: any;
  type: 'credit' | 'debit';
}

interface HistoryScreenProps {
  navigation: any;
}

export default function HistoryScreen({ navigation }: HistoryScreenProps) {
  const [activeCategory, setActiveCategory] = useState('Tất cả');
  
  const categories = ['Tất cả', 'Tiền vào', 'Tiền ra', 'Chờ xử lý'];
  
  const transactions: Transaction[] = [
    { name: 'Starbucks', amount: '-100.000 VNĐ', date: '12/10/2024', icon: 'cafe', type: 'debit' },
    { name: 'Grab', amount: '-50.000 VNĐ', date: '12/10/2024', icon: 'car', type: 'debit' },
    { name: 'Shopee', amount: '-200.000 VNĐ', date: '11/10/2024', icon: 'bag-handle', type: 'debit' },
    { name: 'Nhận tiền', amount: '+500.000 VNĐ', date: '10/10/2024', icon: 'arrow-down-circle', type: 'credit' },
    { name: 'Nạp tiền', amount: '+1.000.000 VNĐ', date: '09/10/2024', icon: 'wallet', type: 'credit' },
    { name: 'ĐIỆN LỰC', amount: '-350.000 VNĐ', date: '08/10/2024', icon: 'flash', type: 'debit' },
    { name: 'MOMO', amount: '-75.000 VNĐ', date: '07/10/2024', icon: 'wallet-outline', type: 'debit' },
    { name: 'Hoàn tiền', amount: '+50.000 VNĐ', date: '06/10/2024', icon: 'return-up-back', type: 'credit' },
  ];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Lịch sử giao dịch</AppText>
        <View style={styles.spacer} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Category filter */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.filterScroll}>
          {categories.map((cat) => (
            <TouchableOpacity
              key={cat}
              style={[
                styles.filterChip,
                activeCategory === cat && styles.filterChipActive,
              ]}
              onPress={() => setActiveCategory(cat)}
            >
              <AppText style={[styles.filterText, activeCategory === cat && styles.filterTextActive]}>
                {cat}
              </AppText>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Transaction list */}
        <View style={styles.listContainer}>
          {transactions.map((tx, index) => (
            <GroupedListRow
              key={`${tx.name}-${tx.date}-${index}`}
              title={tx.name}
              date={tx.date}
              amount={tx.amount}
              amountColor={tx.type === 'credit' ? Colors.success : Colors.danger}
              isFirst={index === 0}
              isLast={index === transactions.length - 1}
              icon={
                <AppIcon
                  name={tx.icon}
                  size="sm"
                  color={tx.type === 'credit' ? Colors.success : Colors.danger}
                />
              }
              onPress={() => navigation.navigate('TransactionDetail', { transaction: tx })}
            />
          ))}
        </View>

        <TouchableOpacity style={styles.viewAllBtn}>
          <AppText style={styles.viewAllText}>Xem tất cả giao dịch</AppText>
        </TouchableOpacity>
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
  spacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
  },
  filterScroll: {
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  filterChip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surface,
    marginRight: Spacing.sm,
  },
  filterChipActive: {
    backgroundColor: Colors.primary,
  },
  filterText: {
    
    color: Colors.textSecondary,
  },
  filterTextActive: {
    color: Colors.surface,
  },
  listContainer: {
    marginHorizontal: Spacing.lg,
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  viewAllBtn: {
    marginTop: Spacing.lg,
    alignSelf: 'center',
    paddingVertical: Spacing.md,
  },
  viewAllText: {
    
    color: Colors.primary,
    },
});
