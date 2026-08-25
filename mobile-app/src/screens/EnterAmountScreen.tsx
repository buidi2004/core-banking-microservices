import React, { useState, useMemo } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Dimensions,
  StatusBar,
  Modal,
  FlatList,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';
import { WalletApi } from '../services/api';

const { width, height } = Dimensions.get('window');

// Bank Definition Interface
interface BankItem {
  id: string;
  shortName: string;
  fullName: string;
  displayName: string;
  iconType: string;
}

const BANK_LIST: BankItem[] = [
  {
    id: 'senbank',
    shortName: 'SenBank (Nội bộ)',
    fullName: 'Ngân hàng SenBank (Chuyển nội bộ 24/7 siêu tốc)',
    displayName: 'SenBank\n(Nội bộ)',
    iconType: 'senbank',
  },
  {
    id: 'mb',
    shortName: 'MBBank (MB)',
    fullName: 'Ngân hàng TMCP Quân đội',
    displayName: 'Quân đội\n(MBBank)',
    iconType: 'mb',
  },
  {
    id: 'mbv',
    shortName: 'Việt Nam Hiện Đại (MBV)',
    fullName: 'Ngân hàng TNHH MTV Việt Nam Hiện Đại (MBV)',
    displayName: 'Việt Nam Hiện Đại\n(MBV)',
    iconType: 'mbv',
  },
  {
    id: 'vba',
    shortName: 'Agribank (VBA)',
    fullName: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam',
    displayName: 'Nông nghiệp\n(Agribank)',
    iconType: 'vba',
  },
  {
    id: 'vcb',
    shortName: 'Vietcombank (VCB)',
    fullName: 'Ngân hàng TMCP Ngoại thương Việt Nam',
    displayName: 'Ngoại thương Việt Nam\n(VCB)',
    iconType: 'vcb',
  },
  {
    id: 'ctg',
    shortName: 'Vietinbank (CTG)',
    fullName: 'Ngân hàng TMCP Công thương Việt Nam',
    displayName: 'Công thương Việt Nam\n(Vietinbank)',
    iconType: 'ctg',
  },
  {
    id: 'bidv',
    shortName: 'BIDV',
    fullName: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam',
    displayName: 'Đầu tư & Phát triển\n(BIDV)',
    iconType: 'bidv',
  },
  {
    id: 'tcb',
    shortName: 'Techcombank (TCB)',
    fullName: 'Ngân hàng TMCP Kỹ thương Việt Nam',
    displayName: 'Kỹ thương Việt Nam\n(Techcombank)',
    iconType: 'tcb',
  },
  {
    id: 'vpb',
    shortName: 'VPBank (VPB)',
    fullName: 'Ngân hàng TMCP Việt Nam Thịnh Vượng',
    displayName: 'Việt Nam Thịnh Vượng\n(VPBank)',
    iconType: 'vpb',
  },
  {
    id: 'acb',
    shortName: 'ACB',
    fullName: 'Ngân hàng TMCP Á Châu',
    displayName: 'Á Châu\n(ACB)',
    iconType: 'acb',
  },
  {
    id: 'tpb',
    shortName: 'TPBank (TPB)',
    fullName: 'Ngân hàng TMCP Tiên Phong',
    displayName: 'Tiên Phong\n(TPBank)',
    iconType: 'tpb',
  },
  {
    id: 'stb',
    shortName: 'Sacombank (STB)',
    fullName: 'Ngân hàng TMCP Sài Gòn Thương Tín',
    displayName: 'Sài Gòn Thương Tín\n(Sacombank)',
    iconType: 'stb',
  },
];

// Bank Logo Component (100% Crisp Vector & Official Branding Badges)
function BankLogoBadge({ type, size = 38 }: { type: string; size?: number }) {
  if (type === 'senbank') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#FDF2F8', borderColor: '#FCE7F3' }]}>
        <AppText style={{ color: '#D2519D', fontSize: 18, fontWeight: '900' }}>★</AppText>
      </View>
    );
  }
  if (type === 'mb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#FFF1F2', borderColor: '#FECDD3' }]}>
        <AppText style={{ color: '#E11D48', fontSize: 18, fontWeight: '900' }}>★</AppText>
      </View>
    );
  }
  if (type === 'mbv') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#E11D48', borderColor: '#BE123C' }]}>
        <AppText style={{ color: '#FFFFFF', fontSize: 10, fontWeight: '900', letterSpacing: 0.5 }}>MBV</AppText>
      </View>
    );
  }
  if (type === 'vba') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#8A1538', borderColor: '#70102D' }]}>
        <MaterialCommunityIcons name="sprout" size={19} color="#FBBF24" />
      </View>
    );
  }
  if (type === 'vcb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#F0FDF4', borderColor: '#DCFCE7' }]}>
        <Ionicons name="triangle" size={17} color="#15803D" />
      </View>
    );
  }
  if (type === 'ctg') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#004B87', borderColor: '#003A68' }]}>
        <MaterialCommunityIcons name="circle-slice-8" size={19} color="#38BDF8" />
      </View>
    );
  }
  if (type === 'bidv') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#0054A6', borderColor: '#004080' }]}>
        <MaterialCommunityIcons name="flower-tulip-outline" size={19} color="#34D399" />
      </View>
    );
  }
  if (type === 'tcb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#E21A22', borderColor: '#C4131A' }]}>
        <MaterialCommunityIcons name="view-grid" size={17} color="#FFFFFF" />
      </View>
    );
  }
  if (type === 'vpb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#F0FDF4', borderColor: '#BBF7D0' }]}>
        <MaterialCommunityIcons name="flower" size={18} color="#00B14F" />
      </View>
    );
  }
  if (type === 'acb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#005BAA', borderColor: '#004887' }]}>
        <AppText style={{ color: '#FFFFFF', fontSize: 10.5, fontWeight: '900' }}>ACB</AppText>
      </View>
    );
  }
  if (type === 'tpb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#5A2D81', borderColor: '#482468' }]}>
        <Ionicons name="triangle" size={15} color="#F97316" style={{ transform: [{ rotate: '90deg' }] }} />
      </View>
    );
  }
  if (type === 'stb') {
    return (
      <View style={[styles.bankLogoBase, { backgroundColor: '#0054A6', borderColor: '#004080' }]}>
        <AppText style={{ color: '#FFFFFF', fontSize: 10.5, fontWeight: '900' }}>STB</AppText>
      </View>
    );
  }
  return (
    <View style={[styles.bankLogoBase, { backgroundColor: '#FDF2F8', borderColor: '#FCE7F3' }]}>
      <MaterialCommunityIcons name="bank-outline" size={18} color="#700F43" />
    </View>
  );
}

// High-performance Vietnamese Number Words Converter (Memoized)
const WORDS_CACHE: Record<number, string> = {};

function readThreeDigits(n: number, showLeadingZero: boolean): string {
  const digits = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];
  const h = Math.floor(n / 100);
  const t = Math.floor((n % 100) / 10);
  const u = n % 10;
  let str = '';

  if (h > 0 || showLeadingZero) {
    str += digits[h] + ' trăm ';
  }
  if (t > 1) {
    str += digits[t] + ' mươi ';
    if (u === 1) str += 'mốt ';
    else if (u === 4) str += 'tư ';
    else if (u === 5) str += 'lăm ';
    else if (u > 0) str += digits[u] + ' ';
  } else if (t === 1) {
    str += 'mười ';
    if (u === 5) str += 'lăm ';
    else if (u > 0) str += digits[u] + ' ';
  } else if (u > 0) {
    if (h > 0 || showLeadingZero) str += 'lẻ ';
    str += digits[u] + ' ';
  }
  return str.trim();
}

function numberToVietnameseWords(numStr: string): string {
  const clean = numStr.replace(/[^0-9]/g, '');
  if (!clean || clean === '0') return 'Không Đồng';
  const num = parseInt(clean, 10);
  if (isNaN(num)) return 'Không Đồng';

  if (WORDS_CACHE[num]) return WORDS_CACHE[num];

  const scales = ['', 'nghìn', 'triệu', 'tỷ'];
  let temp = num;
  let scaleIdx = 0;
  const parts: string[] = [];

  while (temp > 0) {
    const chunk = temp % 1000;
    if (chunk > 0) {
      const chunkText = readThreeDigits(chunk, temp >= 1000);
      const scaleName = scales[scaleIdx] || '';
      parts.unshift((chunkText + ' ' + scaleName).trim());
    }
    temp = Math.floor(temp / 1000);
    scaleIdx++;
  }

  const result = (parts.join(' ').replace(/\s+/g, ' ').trim() + ' Đồng');
  const capitalized = result.charAt(0).toUpperCase() + result.slice(1);
  WORDS_CACHE[num] = capitalized;
  return capitalized;
}

const AVAILABLE_BALANCE = 5420000;

interface EnterAmountScreenProps {
  route: any;
  navigation: any;
}

export default function EnterAmountScreen({ route, navigation }: EnterAmountScreenProps) {
  const { user, wallet } = useApp();
  const params = route.params || {};
  
  const [accountNumber, setAccountNumber] = useState(params.phone || '');
  const [selectedBankItem, setSelectedBankItem] = useState<BankItem>(BANK_LIST[0]); // Default: SenBank (Nội bộ)
  const [recipientName, setRecipientName] = useState(params.name || '');
  const [recipientWalletId, setRecipientWalletId] = useState(params.walletId || '');
  const [amount, setAmount] = useState('');
  const [transferMessage, setTransferMessage] = useState('');
  const [isSaved, setIsSaved] = useState(false);

  // Dynamic lookup of recipient name when account number changes
  const handleAccountChange = (text: string) => {
    const cleanText = text.replace(/[^0-9]/g, '');
    setAccountNumber(cleanText);
    setRecipientName('');
    setRecipientWalletId('');
  };

  React.useEffect(() => {
    if (accountNumber.length >= 8) {
      const fetchInfo = async () => {
        try {
          const res = await WalletApi.getRecipientInfo(undefined, accountNumber);
          if (res.data && res.data.maskedName) {
            setRecipientName(res.data.maskedName);
            setRecipientWalletId(res.data.walletId);
          }
        } catch (e) {
          // If not found or error, keep it empty
        }
      };
      
      const timeoutId = setTimeout(() => {
        fetchInfo();
      }, 500); // 500ms debounce
      
      return () => clearTimeout(timeoutId);
    }
  }, [accountNumber]);

  // Raw numeric amount & Balance validation
  const rawNumAmount = parseInt(amount.replace(/[^0-9]/g, ''), 10) || 0;
  const currentBalance = wallet?.balance || 0;
  const isInsufficient = rawNumAmount > currentBalance;
  const isContinueEnabled = rawNumAmount >= 2000 && !isInsufficient && accountNumber.length >= 8;

  // Bank selection modal state
  const [isBankModalVisible, setIsBankModalVisible] = useState(false);
  const [bankSearchQuery, setBankSearchQuery] = useState('');

  // Filtered banks by search
  const filteredBanks = useMemo(() => {
    if (!bankSearchQuery.trim()) return BANK_LIST;
    const q = bankSearchQuery.toLowerCase();
    return BANK_LIST.filter(
      (b) => b.shortName.toLowerCase().includes(q) || b.fullName.toLowerCase().includes(q)
    );
  }, [bankSearchQuery]);

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* 1. TOP HEADER */}
      <View style={styles.header}>
        <TouchableOpacity
          style={styles.backBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Chuyển tiền SenBank 24/7</AppText>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* 2. SECTION 1: NGUỒN CHUYỂN TIỀN */}
        <View style={styles.sectionBlock}>
          <AppText style={styles.sectionLabel}>Nguồn chuyển tiền</AppText>
          
          <TouchableOpacity style={styles.sourceCard} activeOpacity={0.8}>
            <View style={styles.sourceInfoCol}>
              <AppText style={styles.sourceAccountType}>
                TÀI KHOẢN SENBANK - {user?.phoneNumber || '0923158725'}
              </AppText>
              <AppText style={styles.sourceBalanceText}>
                {wallet?.balance ? wallet.balance.toLocaleString('vi-VN') : '0'} VND
              </AppText>
            </View>

            <Ionicons name="chevron-down" size={20} color="#D2519D" />
          </TouchableOpacity>
        </View>

        {/* 3. SECTION 2: CHUYỂN ĐẾN (3 TẦNG KÉP) */}
        <View style={styles.sectionBlock}>
          <AppText style={styles.sectionLabel}>Chuyển đến</AppText>

          <View style={styles.destinationCard}>
            {/* Tầng 1: Chọn Ngân hàng (Bấm mở Modal Chọn Ngân Hàng) */}
            <TouchableOpacity
              style={styles.bankSelectRow}
              activeOpacity={0.8}
              onPress={() => setIsBankModalVisible(true)}
            >
              <View style={styles.bankLogoWrap}>
                <BankLogoBadge type={selectedBankItem.iconType} size={38} />
              </View>

              <View style={styles.bankTextCol}>
                <AppText style={styles.cardSubLabel}>Ngân hàng</AppText>
                <AppText style={styles.bankNameText}>{selectedBankItem.displayName}</AppText>
              </View>
              
              <Ionicons name="chevron-down" size={20} color="#D2519D" />
            </TouchableOpacity>

            {/* Dotted Divider 1 */}
            <View style={styles.dashedDivider} />

            {/* Tầng 2: Số tài khoản */}
            <View style={styles.accountNumberRow}>
              <View style={{ flex: 1 }}>
                <AppText style={styles.cardSubLabel}>Số tài khoản / Số điện thoại</AppText>
                <TextInput
                  style={styles.accountNumberInput}
                  placeholder="Nhập số tài khoản hoặc SĐT"
                  placeholderTextColor="#94A3B8"
                  keyboardType="numeric"
                  value={accountNumber}
                  onChangeText={handleAccountChange}
                />
              </View>

              <View style={styles.accountActionsRow}>
                {accountNumber.length > 0 && (
                  <TouchableOpacity activeOpacity={0.7} onPress={() => handleAccountChange('')}>
                    <Ionicons name="close-circle" size={20} color="#94A3B8" style={{ marginRight: 10 }} />
                  </TouchableOpacity>
                )}
                <TouchableOpacity
                  activeOpacity={0.7}
                  onPress={() => navigation.navigate('Beneficiaries')}
                >
                  <MaterialCommunityIcons name="card-account-details-outline" size={24} color="#D2519D" />
                </TouchableOpacity>
              </View>
            </View>

            {/* Dotted Divider 2 */}
            <View style={styles.dashedDivider} />

            {/* Tầng 3: Money Chat & Lưu */}
            <View style={styles.recipientRow}>
              <View style={{ flex: 1 }}>
                <AppText style={styles.cardSubLabel}>Người nhận (Tra cứu tự động)</AppText>
                <AppText style={styles.recipientNameText}>{recipientName}</AppText>
              </View>

              <TouchableOpacity
                style={[styles.savePillBtn, isSaved && styles.savePillBtnActive]}
                activeOpacity={0.8}
                onPress={() => setIsSaved(!isSaved)}
              >
                <Ionicons
                  name={isSaved ? "bookmark" : "bookmark-outline"}
                  size={15}
                  color={isSaved ? "#FFFFFF" : "#700F43"}
                  style={{ marginRight: 4 }}
                />
                <AppText style={[styles.savePillText, isSaved && { color: '#FFFFFF' }]}>
                  {isSaved ? 'Đã lưu' : 'Lưu'}
                </AppText>
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* 4. SECTION 3: SỐ TIỀN CHUYỂN */}
        <View style={styles.amountSectionWrapper}>
          <View style={[styles.amountDisplayCard, isInsufficient && styles.amountDisplayCardError]}>
            <View style={styles.amountCenterRow}>
              <TextInput
                style={[styles.amountInput, isInsufficient && { color: '#DC2626' }]}
                placeholder="0"
                placeholderTextColor="#D2519D"
                keyboardType="numeric"
                value={amount}
                onChangeText={setAmount}
              />
              <AppText style={[styles.currencyLabel, isInsufficient && { color: '#DC2626' }]}>VND</AppText>
            </View>

            <View style={styles.amountRightIcons}>
              {amount.length > 0 && (
                <TouchableOpacity activeOpacity={0.7} onPress={() => setAmount('')}>
                  <Ionicons name="close-circle" size={20} color="#94A3B8" style={{ marginRight: 8 }} />
                </TouchableOpacity>
              )}
              <TouchableOpacity activeOpacity={0.7}>
                <Ionicons name="information-circle" size={20} color="#06B6D4" />
              </TouchableOpacity>
            </View>
          </View>

          {/* Dòng báo đỏ số dư không đủ */}
          {isInsufficient ? (
            <View style={styles.insufficientWarningCard}>
              <Ionicons name="alert-circle" size={18} color="#DC2626" />
              <AppText style={styles.insufficientWarningText}>
                Số dư khả dụng không đủ để chuyển (Thiếu {(rawNumAmount - currentBalance).toLocaleString('vi-VN')} đ)
              </AppText>
            </View>
          ) : (
            <AppText style={styles.amountInWordsText}>
              {numberToVietnameseWords(amount)}
            </AppText>
          )}
        </View>

        {/* 5. SECTION 4: NỘI DUNG CHUYỂN TIỀN */}
        <View style={styles.messageCard}>
          <AppText style={styles.cardSubLabel}>Nội dung chuyển tiền</AppText>
          
          <View style={styles.messageInputRow}>
            <TextInput
              style={styles.messageInput}
              value={transferMessage}
              onChangeText={setTransferMessage}
              placeholder="Nhập nội dung chuyển tiền"
              placeholderTextColor="#94A3B8"
            />

            {transferMessage.length > 0 && (
              <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => setTransferMessage('')}
              >
                <Ionicons name="close-circle" size={20} color="#94A3B8" />
              </TouchableOpacity>
            )}
          </View>
        </View>
      </ScrollView>

      {/* 6. BOTTOM ACTION FOOTER (QUICK AMOUNT PILLS + ACTION BUTTONS) */}
      <View style={styles.bottomFooter}>
        {/* Nút Quay lại & Tiếp tục */}
        <View style={styles.actionButtonsRow}>
          <TouchableOpacity
            style={styles.backActionButton}
            activeOpacity={0.8}
            onPress={() => navigation.goBack()}
          >
            <AppText style={styles.backActionText}>Quay lại</AppText>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.continueActionButton, !isContinueEnabled && styles.continueActionDisabled]}
            activeOpacity={isContinueEnabled ? 0.9 : 1}
            disabled={!isContinueEnabled}
            onPress={() => navigation.navigate('ConfirmTransfer', {
              amount: amount || '0',
              accountNumber,
              selectedBank: selectedBankItem.shortName,
              notes: transferMessage,
              recipient: { name: recipientName, phone: accountNumber, walletId: recipientWalletId }
            })}
          >
            <LinearGradient
              colors={isContinueEnabled ? ['#D2519D', '#700F43'] : ['#CBD5E1', '#94A3B8']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={StyleSheet.absoluteFill}
            />
            <AppText style={styles.continueActionText}>Tiếp tục</AppText>
          </TouchableOpacity>
        </View>

        {/* 3 Quick Amount Chips Dưới Cùng (20,000 | 200,000 | 2,000,000) */}
        <View style={styles.quickAmountPillsRow}>
          {['20,000', '200,000', '2,000,000'].map((chipVal) => (
            <TouchableOpacity
              key={chipVal}
              style={[
                styles.quickPill,
                amount === chipVal && styles.quickPillActive
              ]}
              activeOpacity={0.8}
              onPress={() => setAmount(chipVal)}
            >
              <AppText style={[
                styles.quickPillText,
                amount === chipVal && styles.quickPillTextActive
              ]}>
                {chipVal}
              </AppText>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* =========================================================================
          7. BOTTOM SHEET MODAL: "CHỌN NGÂN HÀNG" (CHUẨN 1:1 THEO ẢNH)
         ========================================================================= */}
      <Modal
        visible={isBankModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setIsBankModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <TouchableOpacity
            style={styles.modalBackdropTap}
            activeOpacity={1}
            onPress={() => setIsBankModalVisible(false)}
          />

          <View style={styles.bankSheetContainer}>
            {/* Top Drag Handle */}
            <View style={styles.sheetHandleBar} />

            {/* Sheet Title */}
            <AppText style={styles.sheetTitle}>Chọn ngân hàng</AppText>

            {/* Search Input Bar */}
            <View style={styles.searchBarRow}>
              <TextInput
                style={styles.searchBarInput}
                placeholder="Tìm theo tên ngân hàng"
                placeholderTextColor="#94A3B8"
                value={bankSearchQuery}
                onChangeText={setBankSearchQuery}
              />
              <Ionicons name="search-outline" size={20} color="#94A3B8" />
            </View>

            {/* Bank Items List */}
            <FlatList
              data={filteredBanks}
              keyExtractor={(item) => item.id}
              showsVerticalScrollIndicator={false}
              contentContainerStyle={styles.bankListContent}
              ItemSeparatorComponent={() => <View style={styles.bankItemDivider} />}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={styles.bankListItem}
                  activeOpacity={0.7}
                  onPress={() => {
                    setSelectedBankItem(item);
                    setIsBankModalVisible(false);
                    setBankSearchQuery('');
                  }}
                >
                  <BankLogoBadge type={item.iconType} size={38} />

                  <View style={styles.bankItemInfo}>
                    <AppText style={styles.bankItemShortName}>{item.shortName}</AppText>
                    <AppText style={styles.bankItemFullName} numberOfLines={2}>
                      {item.fullName}
                    </AppText>
                  </View>

                  {selectedBankItem.id === item.id && (
                    <Ionicons name="checkmark-circle" size={22} color="#D2519D" />
                  )}
                </TouchableOpacity>
              )}
            />
          </View>
        </View>
      </Modal>
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
    fontSize: 17.5,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: -0.3,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 140,
  },
  sectionBlock: {
    marginBottom: 16,
  },
  sectionLabel: {
    fontSize: 15.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 8,
  },
  sourceCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  sourceInfoCol: {
    flex: 1,
  },
  sourceAccountType: {
    fontSize: 12,
    fontWeight: '800',
    color: '#700F43',
    marginBottom: 4,
    letterSpacing: 0.2,
  },
  sourceBalanceText: {
    fontSize: 20,
    fontWeight: '900',
    color: '#0F172A',
  },
  destinationCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    paddingHorizontal: 14,
    paddingVertical: 4,
  },
  cardSubLabel: {
    fontSize: 11.5,
    fontWeight: '800',
    color: '#700F43',
    marginBottom: 3,
  },
  bankSelectRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
  },
  bankLogoWrap: {
    marginRight: 12,
  },
  bankLogoBase: {
    width: 38,
    height: 38,
    borderRadius: 12,
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  mbStarPinwheel: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  bankTextCol: {
    flex: 1,
  },
  bankNameText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    lineHeight: 20,
  },
  dashedDivider: {
    borderBottomWidth: 1,
    borderColor: '#E2E8F0',
    borderStyle: 'dashed',
    marginVertical: 2,
  },
  accountNumberRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
  },
  accountNumberInput: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
    paddingVertical: 2,
  },
  accountActionsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  recipientRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
  },
  recipientNameText: {
    fontSize: 15.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  savePillBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: '#D2519D',
    borderRadius: 18,
    paddingHorizontal: 14,
    paddingVertical: 5,
    backgroundColor: '#FFFFFF',
  },
  savePillBtnActive: {
    backgroundColor: '#D2519D',
    borderColor: '#D2519D',
  },
  savePillText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#700F43',
  },
  amountSectionWrapper: {
    marginBottom: 16,
  },
  amountDisplayCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    paddingVertical: 14,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1.5,
    borderColor: '#D2519D',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  amountDisplayCardError: {
    borderColor: '#EF4444',
    backgroundColor: '#FEF2F2',
    shadowColor: '#EF4444',
  },
  insufficientWarningCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEF2F2',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
    marginTop: 8,
    gap: 6,
    borderWidth: 1,
    borderColor: '#FECACA',
  },
  insufficientWarningText: {
    fontSize: 12.5,
    fontWeight: '700',
    color: '#DC2626',
    flex: 1,
  },
  amountCenterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  amountInput: {
    fontSize: 24,
    fontWeight: '900',
    color: '#700F43',
    textAlign: 'center',
    minWidth: 60,
    paddingVertical: 0,
  },
  currencyLabel: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginLeft: 6,
  },
  amountRightIcons: {
    flexDirection: 'row',
    alignItems: 'center',
    position: 'absolute',
    right: 14,
  },
  amountInWordsText: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
    marginTop: 6,
    marginLeft: 4,
  },
  messageCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 20,
  },
  messageInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 2,
  },
  messageInput: {
    flex: 1,
    fontSize: 15,
    fontWeight: '700',
    color: '#0F172A',
    paddingVertical: 2,
  },
  bottomFooter: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 20,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    gap: 10,
  },
  actionButtonsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  backActionButton: {
    flex: 1,
    height: 48,
    borderRadius: 24,
    borderWidth: 1.5,
    borderColor: '#D2519D',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  backActionText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#700F43',
  },
  continueActionButton: {
    flex: 1.4,
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
  continueActionDisabled: {
    shadowOpacity: 0,
    elevation: 0,
    opacity: 0.7,
  },
  continueActionText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  quickAmountPillsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
  },
  quickPill: {
    flex: 1,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#FDF2F8',
    borderWidth: 1.2,
    borderColor: '#FBCFE8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  quickPillActive: {
    backgroundColor: '#D2519D',
    borderColor: '#D2519D',
  },
  quickPillText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#700F43',
  },
  quickPillTextActive: {
    color: '#FFFFFF',
  },

  // ===== "CHỌN NGÂN HÀNG" BOTTOM SHEET STYLES =====
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.45)',
    justifyContent: 'flex-end',
  },
  modalBackdropTap: {
    flex: 1,
  },
  bankSheetContainer: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    height: height * 0.78,
    paddingTop: 12,
    paddingHorizontal: 16,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 16,
  },
  sheetHandleBar: {
    width: 44,
    height: 4.5,
    borderRadius: 3,
    backgroundColor: '#CBD5E1',
    alignSelf: 'center',
    marginBottom: 14,
  },
  sheetTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#700F43',
    textAlign: 'center',
    marginBottom: 16,
  },
  searchBarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F8FAFC',
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 14,
  },
  searchBarInput: {
    flex: 1,
    fontSize: 14.5,
    fontWeight: '600',
    color: '#0F172A',
    paddingVertical: 2,
  },
  bankListContent: {
    paddingBottom: 40,
  },
  bankListItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    gap: 12,
  },
  bankItemInfo: {
    flex: 1,
  },
  bankItemShortName: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 3,
  },
  bankItemFullName: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
    lineHeight: 16,
  },
  bankItemDivider: {
    height: 1,
    backgroundColor: '#F1F5F9',
  },
});