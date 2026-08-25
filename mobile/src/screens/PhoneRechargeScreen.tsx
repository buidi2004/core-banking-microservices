import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  StatusBar,
  ScrollView,
  TextInput,
  Dimensions,
  Alert,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

interface PhoneRechargeScreenProps {
  navigation: any;
}

const { width } = Dimensions.get('window');
const GRID_ITEM_WIDTH = (width - 32 - 16) / 3;

const DENOMINATIONS = [
  { id: '1', amount: '10,000 đ', rawAmount: '10.000', price: '9,800 đ', discount: '-2%' },
  { id: '2', amount: '20,000 đ', rawAmount: '20.000', price: '19,600 đ', discount: '-2%' },
  { id: '3', amount: '30,000 đ', rawAmount: '30.000', price: '29,400 đ', discount: '-2%' },
  { id: '4', amount: '50,000 đ', rawAmount: '50.000', price: '49,000 đ', discount: '-2%' },
  { id: '5', amount: '100,000 đ', rawAmount: '100.000', price: '98,000 đ', discount: '-2%' },
  { id: '6', amount: '200,000 đ', rawAmount: '200.000', price: '196,000 đ', discount: '-2%' },
  { id: '7', amount: '300,000 đ', rawAmount: '300.000', price: '294,000 đ', discount: '-2%' },
  { id: '8', amount: '500,000 đ', rawAmount: '500.000', price: '490,000 đ', discount: '-2%' },
];

const DATA_PACKAGES = [
  {
    id: 'd1',
    name: '1N',
    price: '10,000 đ',
    duration: '1 ngày',
    dataAmount: '5 GB',
    description: '5GB/ngày, hết lưu lượng ngừng truy cập.',
    provider: 'SSMedia',
    providerIcon: <MaterialCommunityIcons name="cellphone-wireless" size={24} color="#059669" />,
  },
  {
    id: 'd2',
    name: 'ST15K',
    price: '15,000 đ',
    duration: '3 ngày',
    dataAmount: '3 GB',
    description: '3GB Data tốc độ cao sử dụng trong 3 ngày.',
    provider: 'VPAY',
    providerIcon: <MaterialCommunityIcons name="signal-5g" size={24} color="#DC2626" />,
  },
  {
    id: 'd3',
    name: 'ST30K',
    price: '30,000 đ',
    duration: '7 ngày',
    dataAmount: '7 GB',
    description: '7GB Data tốc độ cao sử dụng trong 7 ngày.',
    provider: 'Vina & Mobi',
    providerIcon: <MaterialCommunityIcons name="wifi" size={24} color="#0284C7" />,
  },
];

export default function PhoneRechargeScreen({ navigation }: PhoneRechargeScreenProps) {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [activeTab, setActiveTab] = useState<'topup' | 'data'>('topup');
  const [selectedDenomId, setSelectedDenomId] = useState<string>('5');
  const [selectedDataId, setSelectedDataId] = useState<string>('d1');

  const selectedDenom = DENOMINATIONS.find((d) => d.id === selectedDenomId);
  const selectedData = DATA_PACKAGES.find((d) => d.id === selectedDataId);

  const handleContinue = () => {
    if (activeTab === 'topup' && selectedDenom) {
      const parsedAmount = parseInt(selectedDenom.amount.replace(/\./g, ''), 10);
      navigation.navigate('BillConfirm', {
        provider: 'Nạp điện thoại trả trước',
        billId: phoneNumber,
        amount: parsedAmount,
      });
    } else if (activeTab === 'data' && selectedData) {
      const parsedAmount = parseInt(selectedData.price.replace(/\./g, ''), 10);
      navigation.navigate('BillConfirm', {
        provider: `Gói data ${selectedData.provider}`,
        billId: phoneNumber,
        amount: parsedAmount,
      });
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* TOP HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backBtn}
          onPress={() => navigation.goBack()}
          activeOpacity={0.7}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Nạp tiền điện thoại</AppText>

        <TouchableOpacity
          style={styles.backBtn}
          onPress={() => navigation.navigate('Home')}
          activeOpacity={0.7}
        >
          <Ionicons name="home-outline" size={22} color="#700F43" />
        </TouchableOpacity>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* PHONE NUMBER INPUT CARD */}
        <View style={styles.phoneInputCard}>
          <AppText style={styles.inputCardLabel}>Số điện thoại nhận tiền</AppText>

          <View style={styles.phoneInputRow}>
            <TextInput
              style={styles.phoneInput}
              value={phoneNumber}
              onChangeText={setPhoneNumber}
              keyboardType="phone-pad"
              placeholder="Nhập số điện thoại"
              placeholderTextColor="#94A3B8"
            />

            {phoneNumber.length > 0 && (
              <TouchableOpacity
                onPress={() => setPhoneNumber('')}
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                style={{ marginRight: 10 }}
              >
                <Ionicons name="close-circle" size={20} color="#94A3B8" />
              </TouchableOpacity>
            )}

            <TouchableOpacity
              activeOpacity={0.7}
              onPress={() => Alert.alert('Danh bạ', 'Mở danh bạ điện thoại')}
            >
              <MaterialCommunityIcons name="book-account-outline" size={26} color="#700F43" />
            </TouchableOpacity>
          </View>

          {/* Viettel Badge */}
          <View style={styles.networkBadgeRow}>
            <View style={styles.networkDot} />
            <AppText style={styles.networkText}>Nhà mạng: Viettel (Trả trước)</AppText>
          </View>
        </View>

        {/* 2 TABS (NẠP ĐIỆN THOẠI | MUA DATA 4G/5G) */}
        <View style={styles.tabsContainer}>
          <TouchableOpacity
            style={[styles.tabItem, activeTab === 'topup' && styles.tabItemActive]}
            onPress={() => setActiveTab('topup')}
            activeOpacity={0.8}
          >
            <AppText style={[styles.tabText, activeTab === 'topup' && styles.tabTextActive]}>
              Nạp tiền ĐT
            </AppText>
            {activeTab === 'topup' && <View style={styles.tabActiveBar} />}
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabItem, activeTab === 'data' && styles.tabItemActive]}
            onPress={() => setActiveTab('data')}
            activeOpacity={0.8}
          >
            <AppText style={[styles.tabText, activeTab === 'data' && styles.tabTextActive]}>
              Gói cước Data 4G/5G
            </AppText>
            {activeTab === 'data' && <View style={styles.tabActiveBar} />}
          </TouchableOpacity>
        </View>

        {/* TAB 1: MỆNH GIÁ NẠP TIỀN */}
        {activeTab === 'topup' && (
          <View style={styles.sectionContainer}>
            <AppText style={styles.sectionHeading}>Chọn mệnh giá nạp</AppText>

            <View style={styles.denomGrid}>
              {DENOMINATIONS.map((denom) => {
                const isSelected = denom.id === selectedDenomId;
                return (
                  <TouchableOpacity
                    key={denom.id}
                    style={[styles.denomCard, isSelected && styles.denomCardSelected]}
                    activeOpacity={0.8}
                    onPress={() => setSelectedDenomId(denom.id)}
                  >
                    {/* Discount badge */}
                    <View style={styles.discountBadge}>
                      <AppText style={styles.discountText}>{denom.discount}</AppText>
                    </View>

                    <AppText style={[styles.denomAmountText, isSelected && styles.denomAmountTextSelected]}>
                      {denom.amount}
                    </AppText>

                    <AppText style={[styles.denomPriceText, isSelected && styles.denomPriceTextSelected]}>
                      Giá: {denom.price}
                    </AppText>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        )}

        {/* TAB 2: GÓI CƯỚC DATA */}
        {activeTab === 'data' && (
          <View style={styles.sectionContainer}>
            <AppText style={styles.sectionHeading}>Gói Data đề xuất cho bạn</AppText>

            {DATA_PACKAGES.map((pkg) => {
              const isSelected = pkg.id === selectedDataId;
              return (
                <TouchableOpacity
                  key={pkg.id}
                  style={[styles.dataCard, isSelected && styles.dataCardSelected]}
                  activeOpacity={0.8}
                  onPress={() => setSelectedDataId(pkg.id)}
                >
                  <View style={styles.dataCardLeft}>
                    <View style={styles.providerIconWrap}>
                      {pkg.providerIcon}
                    </View>
                    <View style={{ flex: 1 }}>
                      <View style={styles.dataNameRow}>
                        <AppText style={styles.dataPkgName}>{pkg.name}</AppText>
                        <View style={styles.durationBadge}>
                          <AppText style={styles.durationText}>{pkg.duration}</AppText>
                        </View>
                      </View>
                      <AppText style={styles.dataDescText}>{pkg.description}</AppText>
                    </View>
                  </View>

                  <View style={styles.dataCardRight}>
                    <AppText style={styles.dataAmountBig}>{pkg.dataAmount}</AppText>
                    <AppText style={styles.dataPriceText}>{pkg.price}</AppText>
                  </View>
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </ScrollView>

      {/* FOOTER CTA */}
      <View style={styles.bottomFooter}>
        <View style={styles.footerPriceRow}>
          <AppText style={styles.footerPriceLabel}>Tổng thanh toán:</AppText>
          <AppText style={styles.footerPriceValue}>
            {activeTab === 'topup' ? selectedDenom?.price : selectedData?.price}
          </AppText>
        </View>

        <TouchableOpacity
          style={styles.continueButton}
          activeOpacity={0.9}
          onPress={handleContinue}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <AppText style={styles.continueButtonText}>Tiếp tục</AppText>
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
  backBtn: {
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
    paddingBottom: 120,
  },
  phoneInputCard: {
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
    marginBottom: 16,
  },
  inputCardLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#64748B',
    marginBottom: 8,
  },
  phoneInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1.5,
    borderBottomColor: '#D2519D',
    paddingBottom: 8,
    marginBottom: 10,
  },
  phoneInput: {
    flex: 1,
    fontSize: 18,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: 0.5,
  },
  networkBadgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  networkDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#10B981',
  },
  networkText: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
  },
  tabsContainer: {
    flexDirection: 'row',
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 16,
    overflow: 'hidden',
  },
  tabItem: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    position: 'relative',
  },
  tabItemActive: {
    backgroundColor: '#FDF2F8',
  },
  tabText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  tabTextActive: {
    fontWeight: '800',
    color: '#700F43',
  },
  tabActiveBar: {
    position: 'absolute',
    bottom: 0,
    width: '60%',
    height: 3,
    backgroundColor: '#700F43',
    borderRadius: 1.5,
  },
  sectionContainer: {
    marginBottom: 16,
  },
  sectionHeading: {
    fontSize: 15.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  denomGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  denomCard: {
    width: GRID_ITEM_WIDTH,
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
    paddingVertical: 14,
    paddingHorizontal: 8,
    alignItems: 'center',
    position: 'relative',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  denomCardSelected: {
    borderColor: '#D2519D',
    backgroundColor: '#FDF2F8',
  },
  discountBadge: {
    position: 'absolute',
    top: 0,
    right: 0,
    backgroundColor: '#E11D48',
    borderTopRightRadius: 12,
    borderBottomLeftRadius: 8,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  discountText: {
    color: '#FFFFFF',
    fontSize: 10,
    fontWeight: '900',
  },
  denomAmountText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 4,
  },
  denomAmountTextSelected: {
    color: '#700F43',
  },
  denomPriceText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  denomPriceTextSelected: {
    color: '#700F43',
    fontWeight: '700',
  },
  dataCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  dataCardSelected: {
    borderColor: '#D2519D',
    backgroundColor: '#FDF2F8',
  },
  dataCardLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  providerIconWrap: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  dataNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 2,
  },
  dataPkgName: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
  },
  durationBadge: {
    backgroundColor: '#F1F5F9',
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  durationText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#475569',
  },
  dataDescText: {
    fontSize: 12,
    color: '#64748B',
    lineHeight: 16,
  },
  dataCardRight: {
    alignItems: 'flex-end',
    marginLeft: 8,
  },
  dataAmountBig: {
    fontSize: 17,
    fontWeight: '900',
    color: '#700F43',
    marginBottom: 2,
  },
  dataPriceText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 16,
  },
  footerPriceRow: {
    flex: 1,
  },
  footerPriceLabel: {
    fontSize: 12.5,
    color: '#64748B',
    fontWeight: '600',
  },
  footerPriceValue: {
    fontSize: 18,
    fontWeight: '900',
    color: '#700F43',
  },
  continueButton: {
    flex: 1.2,
    height: 48,
    borderRadius: 24,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 4,
  },
  continueButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
