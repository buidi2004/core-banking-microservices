import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
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
import { ActivityIndicator } from 'react-native';

const { width } = Dimensions.get('window');

interface Beneficiary {
  id: string;
  name: string;
  accountNumber: string;
  bankName: string;
  bankType: string;
  nickname?: string;
}

export default function BeneficiariesScreen({ navigation }: { navigation: any }) {
  const [beneficiaries, setBeneficiaries] = useState<Beneficiary[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  React.useEffect(() => {
    const fetchBeneficiaries = async () => {
      try {
        const res = await WalletApi.getBeneficiaries();
        // map backend structure if needed
        const mapped = (res.data || []).map((b: any) => ({
          id: b.id,
          name: b.nickname || b.accountNumber,
          accountNumber: b.accountNumber || b.beneficiaryWalletId,
          bankName: b.bankCode || 'SenBank (Nội bộ)',
          bankType: b.bankCode?.toLowerCase().includes('mb') ? 'mb' : 
                    b.bankCode?.toLowerCase().includes('vcb') ? 'vcb' : 
                    b.bankCode?.toLowerCase().includes('tcb') ? 'tcb' : 
                    b.bankCode?.toLowerCase().includes('acb') ? 'acb' : 
                    b.bankCode?.toLowerCase().includes('bidv') ? 'bidv' : 'senbank',
          nickname: b.nickname,
        }));
        setBeneficiaries(mapped);
      } catch (e) {
        console.error('Failed to get beneficiaries', e);
      } finally {
        setIsLoading(false);
      }
    };
    fetchBeneficiaries();
  }, []);

  const filtered = beneficiaries.filter(
    (b) =>
      b.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      b.accountNumber.includes(searchQuery) ||
      (b.nickname && b.nickname.toLowerCase().includes(searchQuery.toLowerCase())) ||
      b.bankName.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleDeleteBeneficiary = (id: string, name: string) => {
    Alert.alert(
      'Xóa người nhận',
      `Bạn có chắc chắn muốn xóa "${name}" khỏi danh bạ người thụ hưởng đã lưu?`,
      [
        { text: 'Hủy', style: 'cancel' },
        {
          text: 'Xóa',
          style: 'destructive',
          onPress: async () => {
            try {
              await WalletApi.deleteBeneficiary(id);
              setBeneficiaries(beneficiaries.filter((b) => b.id !== id));
            } catch (e) {
              Alert.alert('Lỗi', 'Không thể xóa người nhận lúc này.');
            }
          },
        },
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

        <AppText style={styles.headerTitle}>Danh bạ người nhận</AppText>

        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.navigate('Home')}
        >
          <Ionicons name="home-outline" size={22} color="#700F43" />
        </TouchableOpacity>
      </View>

      {/* SEARCH BAR */}
      <View style={styles.searchBarWrapper}>
        <Ionicons name="search-outline" size={20} color="#94A3B8" />
        <TextInput
          style={styles.searchInput}
          placeholder="Tìm tên, số tài khoản hoặc ngân hàng..."
          placeholderTextColor="#94A3B8"
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
        {searchQuery.length > 0 && (
          <TouchableOpacity onPress={() => setSearchQuery('')}>
            <Ionicons name="close-circle" size={18} color="#94A3B8" />
          </TouchableOpacity>
        )}
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        <AppText style={styles.sectionHeading}>
          Đã lưu ({filtered.length} người thụ hưởng)
        </AppText>

        {isLoading ? (
          <ActivityIndicator size="large" color="#D2519D" style={{ marginTop: 40 }} />
        ) : filtered.length === 0 ? (
          <AppText style={{ textAlign: 'center', marginTop: 40, color: '#64748B' }}>Chưa có danh bạ người nhận nào</AppText>
        ) : (
          filtered.map((item) => (
          <TouchableOpacity
            key={item.id}
            style={styles.beneficiaryCard}
            activeOpacity={0.8}
            onPress={() =>
              navigation.navigate('EnterAmount', {
                recipient: { name: item.name, phone: item.accountNumber },
                selectedBank: item.bankName,
              })
            }
          >
            {/* Bank Badge */}
            {item.bankType === 'mb' && (
              <View style={[styles.bankBadge, { backgroundColor: '#FFF1F2', borderColor: '#FECDD3' }]}>
                <AppText style={{ color: '#E11D48', fontSize: 18, fontWeight: '900' }}>★</AppText>
              </View>
            )}
            {item.bankType === 'vcb' && (
              <View style={[styles.bankBadge, { backgroundColor: '#F0FDF4', borderColor: '#DCFCE7' }]}>
                <Ionicons name="triangle" size={17} color="#15803D" />
              </View>
            )}
            {item.bankType === 'tcb' && (
              <View style={[styles.bankBadge, { backgroundColor: '#FEF2F2', borderColor: '#FEE2E2' }]}>
                <MaterialCommunityIcons name="view-grid" size={17} color="#E21A22" />
              </View>
            )}
            {item.bankType === 'acb' && (
              <View style={[styles.bankBadge, { backgroundColor: '#005BAA', borderColor: '#004887' }]}>
                <AppText style={{ color: '#FFFFFF', fontSize: 10.5, fontWeight: '900' }}>ACB</AppText>
              </View>
            )}
            {item.bankType === 'bidv' && (
              <View style={[styles.bankBadge, { backgroundColor: '#0054A6', borderColor: '#004080' }]}>
                <MaterialCommunityIcons name="flower-tulip-outline" size={18} color="#34D399" />
              </View>
            )}
            {item.bankType !== 'mb' && item.bankType !== 'vcb' && item.bankType !== 'tcb' && item.bankType !== 'acb' && item.bankType !== 'bidv' && (
              <View style={[styles.bankBadge, { backgroundColor: '#FDF2F8', borderColor: '#FCE7F3' }]}>
                <AppText style={{ color: '#D2519D', fontSize: 16, fontWeight: '900' }}>★</AppText>
              </View>
            )}

            {/* Info */}
            <View style={styles.infoCol}>
              <View style={styles.nameRow}>
                <AppText style={styles.nameText}>{item.nickname || item.name}</AppText>
                {item.nickname && (
                  <View style={styles.nickPill}>
                    <AppText style={styles.nickText}>{item.name}</AppText>
                  </View>
                )}
              </View>
              <AppText style={styles.accountText}>STK: {item.accountNumber}</AppText>
              <AppText style={styles.bankText}>{item.bankName}</AppText>
            </View>

            {/* Action */}
            <TouchableOpacity
              style={styles.deleteBtn}
              activeOpacity={0.7}
              onPress={() => handleDeleteBeneficiary(item.id, item.nickname || item.name)}
            >
              <Ionicons name="trash-outline" size={18} color="#EF4444" />
            </TouchableOpacity>
          </TouchableOpacity>
        )))}
      </ScrollView>

      {/* FOOTER: ADD BENEFICIARY */}
      <View style={styles.bottomFooter}>
        <TouchableOpacity
          style={styles.addBtn}
          activeOpacity={0.9}
          onPress={() => navigation.navigate('Transfer')}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <Ionicons name="person-add-outline" size={20} color="#FFFFFF" style={{ marginRight: 8 }} />
          <AppText style={styles.addBtnText}>Chuyển tiền & Lưu người nhận mới</AppText>
        </TouchableOpacity>
      </View>
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
  searchBarWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginTop: 12,
    marginBottom: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    color: '#0F172A',
    fontWeight: '600',
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 110,
  },
  sectionHeading: {
    fontSize: 14,
    fontWeight: '800',
    color: '#64748B',
    marginBottom: 12,
  },
  beneficiaryCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 10,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 5,
    elevation: 2,
  },
  bankBadge: {
    width: 44,
    height: 44,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
  },
  infoCol: {
    flex: 1,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 2,
  },
  nameText: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  nickPill: {
    backgroundColor: '#FDF2F8',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
  },
  nickText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#700F43',
  },
  accountText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#700F43',
    marginBottom: 1,
  },
  bankText: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '600',
  },
  deleteBtn: {
    padding: 8,
  },
  bottomFooter: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 24,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  addBtn: {
    width: '100%',
    height: 48,
    borderRadius: 24,
    overflow: 'hidden',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 4,
  },
  addBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
