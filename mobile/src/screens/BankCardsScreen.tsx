import React from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { WalletApi } from '../services/api';
import { useApp } from '../context/AppContext';

const { width } = Dimensions.get('window');

interface LinkedBank {
  id: string;
  provider: string; // VCB, MB, TCB
  number: string;
  cardHolderName: string;
  isDefault?: boolean;
}

export default function BankCardsScreen({ navigation }: { navigation: any }) {
  const { user } = useApp();
  const [banks, setBanks] = React.useState<LinkedBank[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);

  React.useEffect(() => {
    const fetchBanks = async () => {
      try {
        const res = await WalletApi.getFundingSources();
        setBanks(res.data);
      } catch (e) {
        console.error('Lỗi lấy danh sách thẻ:', e);
      } finally {
        setIsLoading(false);
      }
    };
    fetchBanks();
  }, []);

  const handleAddNewBank = () => {
    Alert.alert(
      'Thêm liên kết',
      'Bạn có muốn liên kết thẻ MB Bank tự động không?',
      [
        { text: 'Hủy', style: 'cancel' },
        {
          text: 'Liên kết ngay',
          onPress: async () => {
            try {
              setIsLoading(true);
              await WalletApi.linkFundingSource(
                'BANK_ACCOUNT',
                'MB Bank',
                '9704229384758211',
                user?.name || 'Tài khoản'
              );
              const res = await WalletApi.getFundingSources();
              setBanks(res.data);
            } catch (e: any) {
              Alert.alert('Lỗi', e.message || 'Không thể liên kết thẻ');
            } finally {
              setIsLoading(false);
            }
          }
        }
      ]
    );
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* TOP HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Ngân hàng & thẻ liên kết</AppText>

        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.navigate('Home')}
        >
          <Ionicons name="home-outline" size={22} color="#700F43" />
        </TouchableOpacity>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        <AppText style={styles.sectionHeading}>Tài khoản ngân hàng đã liên kết</AppText>

        {isLoading ? (
          <AppText style={{ textAlign: 'center', marginTop: 20 }}>Đang tải...</AppText>
        ) : banks.length === 0 ? (
          <AppText style={{ textAlign: 'center', marginTop: 20, color: '#64748B' }}>Chưa có thẻ nào được liên kết</AppText>
        ) : (
          banks.map((bank) => (
            <View key={bank.id} style={styles.bankCard}>
              <View style={styles.bankTopRow}>
                {/* Official Bank Vector Badge */}
                {bank.provider?.toLowerCase().includes('mb') && (
                  <View style={[styles.bankBadge, { backgroundColor: '#FFF1F2', borderColor: '#FECDD3' }]}>
                    <AppText style={{ color: '#E11D48', fontSize: 18, fontWeight: '900' }}>★</AppText>
                  </View>
                )}
                {bank.provider?.toLowerCase().includes('vcb') && (
                  <View style={[styles.bankBadge, { backgroundColor: '#F0FDF4', borderColor: '#DCFCE7' }]}>
                    <Ionicons name="triangle" size={17} color="#15803D" />
                  </View>
                )}
                {bank.provider?.toLowerCase().includes('tcb') && (
                  <View style={[styles.bankBadge, { backgroundColor: '#FEF2F2', borderColor: '#FEE2E2' }]}>
                    <MaterialCommunityIcons name="view-grid" size={17} color="#E21A22" />
                  </View>
                )}
                {!bank.provider?.toLowerCase().includes('mb') && !bank.provider?.toLowerCase().includes('vcb') && !bank.provider?.toLowerCase().includes('tcb') && (
                  <View style={[styles.bankBadge, { backgroundColor: '#F1F5F9', borderColor: '#E2E8F0' }]}>
                    <Ionicons name="card" size={17} color="#475569" />
                  </View>
                )}

                <View style={styles.bankInfoCol}>
                  <AppText style={styles.bankNameText}>{bank.provider || 'Ngân hàng'}</AppText>
                  <AppText style={styles.bankAccountText}>STK: {bank.number}</AppText>
                  <AppText style={styles.bankHolderText}>Chủ TK: {bank.cardHolderName || '—'}</AppText>
                </View>

                {bank.isDefault ? (
                  <View style={styles.defaultPill}>
                    <AppText style={styles.defaultPillText}>Mặc định</AppText>
                  </View>
                ) : (
                  <TouchableOpacity activeOpacity={0.7} onPress={() => {
                    Alert.alert('Xóa thẻ', 'Bạn có chắc chắn muốn xóa thẻ này?', [
                      { text: 'Hủy', style: 'cancel' },
                      { 
                        text: 'Xóa', 
                        style: 'destructive',
                        onPress: async () => {
                          try {
                            await WalletApi.unlinkFundingSource(bank.id);
                            setBanks(banks.filter(b => b.id !== bank.id));
                          } catch(e) {}
                        }
                      }
                    ]);
                  }}>
                    <Ionicons name="trash-outline" size={20} color="#EF4444" />
                  </TouchableOpacity>
                )}
              </View>
            </View>
          ))
        )}

        {/* ADD NEW BANK BUTTON */}
        <TouchableOpacity
          style={styles.addBankBtn}
          activeOpacity={0.85}
          onPress={handleAddNewBank}
        >
          <MaterialCommunityIcons name="bank-plus" size={22} color="#700F43" />
          <AppText style={styles.addBankText}>Liên kết ngân hàng mới</AppText>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  headerBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: -0.3,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 40,
  },
  sectionHeading: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  bankCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 12,
  },
  bankTopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  bankBadge: {
    width: 44,
    height: 44,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
  },
  bankInfoCol: {
    flex: 1,
  },
  bankNameText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  bankAccountText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#700F43',
    marginBottom: 1,
  },
  bankHolderText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  defaultPill: {
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 10,
  },
  defaultPillText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#15803D',
  },
  addBankBtn: {
    height: 50,
    borderRadius: 25,
    borderWidth: 1.5,
    borderColor: '#D2519D',
    borderStyle: 'dashed',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    marginTop: 8,
    backgroundColor: '#FDF2F8',
  },
  addBankText: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#700F43',
  },
});
