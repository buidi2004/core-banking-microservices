import React, { useState, useEffect } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { AppText } from '../components/typography/AppText';
import { useApp } from '../context/AppContext';
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { WalletApi, getAuthToken } from '../services/api';
import { Alert } from 'react-native';

interface Transaction {
  id: string;
  name: string;
  amount: string;
  date: string;
  icon: any;
  type: 'credit' | 'debit';
  rawTx: any;
}

interface HistoryScreenProps {
  navigation: any;
}

export default function HistoryScreen({ navigation }: HistoryScreenProps) {
  const { user } = useApp();
  const [activeCategory, setActiveCategory] = useState('Tất cả');
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);
  
  const categories = ['Tất cả', 'Tiền vào', 'Tiền ra', 'Chờ xử lý'];

  const handleExport = (format: 'csv' | 'pdf' | 'excel') => {
    if (!user?.walletId) return;
    Alert.alert(
      'Xuất sao kê',
      `Bạn có muốn xuất sao kê định dạng ${format.toUpperCase()}?`,
      [
        { text: 'Hủy', style: 'cancel' },
        { 
          text: 'Xuất ngay', 
          onPress: async () => {
            try {
              setIsExporting(true);
              const url = WalletApi.exportStatement(user.walletId, format);
              const token = getAuthToken();
              const ext = format === 'excel' ? 'xlsx' : format;
              const fileUri = `${FileSystem.documentDirectory}saokae_${Date.now()}.${ext}`;
              
              const { uri, status } = await FileSystem.downloadAsync(url, fileUri, {
                headers: {
                  Authorization: `Bearer ${token}`
                }
              });
              
              if (status === 200) {
                const isAvailable = await Sharing.isAvailableAsync();
                if (isAvailable) {
                  await Sharing.shareAsync(uri);
                } else {
                  Alert.alert('Thành công', `Sao kê đã được lưu tại ${uri}`);
                }
              } else {
                throw new Error(`Tải về thất bại, mã lỗi: ${status}`);
              }
            } catch (e: any) {
              console.error(e);
              Alert.alert('Lỗi', 'Không thể xuất sao kê. ' + e.message);
            } finally {
              setIsExporting(false);
            }
          }
        }
      ]
    );
  };

  useEffect(() => {
    const fetchHistory = async () => {
      try {
        if (!user?.walletId) return;
        setIsLoading(true);
        // Map category
        let typeFilter = undefined;
        if (activeCategory === 'Tiền vào') typeFilter = 'CREDIT';
        if (activeCategory === 'Tiền ra') typeFilter = 'DEBIT';

        const res = await WalletApi.getTransactionHistory(user.walletId, 0, 50, typeFilter);
        const data = res.data as any[];

          const mapped: Transaction[] = data.map(tx => {
          const isCredit = tx.type === 'DEPOSIT' || (tx.type === 'TRANSFER' && tx.targetWalletId === user.walletId);
          return {
            id: tx.transactionId || tx.id,
            name: tx.type === 'DEPOSIT' ? 'Nạp tiền' : (tx.type === 'WITHDRAWAL' ? 'Rút tiền' : 'Chuyển tiền'),
            amount: `${isCredit ? '+' : '-'}${tx.amount.toLocaleString('vi-VN')} đ`,
            date: new Date(tx.timestamp || tx.createdAt).toLocaleDateString('vi-VN'),
            icon: isCredit ? 'arrow-down-circle' : 'arrow-up-circle',
            type: isCredit ? 'credit' : 'debit',
            rawTx: tx,
          };
        });
        setTransactions(mapped);
      } catch (e) {
        console.error('Lỗi tải lịch sử:', e);
      } finally {
        setIsLoading(false);
      }
    };
    fetchHistory();
  }, [user?.walletId, activeCategory]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Lịch sử giao dịch</AppText>
        <TouchableOpacity onPress={() => {
          Alert.alert('Định dạng xuất', 'Chọn định dạng bạn muốn tải về:', [
            { text: 'PDF', onPress: () => handleExport('pdf') },
            { text: 'Excel', onPress: () => handleExport('excel') },
            { text: 'CSV', onPress: () => handleExport('csv') },
            { text: 'Hủy', style: 'cancel' }
          ]);
        }}>
          <AppIcon name="download-outline" size="md" color={Colors.primary} />
        </TouchableOpacity>
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
          {isLoading ? (
            <ActivityIndicator size="large" color="#D2519D" style={{ marginTop: 40 }} />
          ) : transactions.length === 0 ? (
            <AppText style={{ textAlign: 'center', marginTop: 40, color: '#64748B' }}>Không có giao dịch nào</AppText>
          ) : (
            transactions.map((tx, index) => (
              <GroupedListRow
                key={tx.id}
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
                onPress={() => navigation.navigate('TransactionDetail', { transaction: tx.rawTx })}
              />
            ))
          )}
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
