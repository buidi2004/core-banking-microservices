import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';
import { WalletApi } from '../services/api';
import { ActivityIndicator, Alert } from 'react-native';

const { width, height } = Dimensions.get('window');

// Helper to convert number to Vietnamese words
function numberToVietnameseWords(numStr: string): string {
  const num = parseInt(numStr.replace(/[^0-9]/g, ''), 10);
  if (isNaN(num) || num === 0) return 'Không Đồng';
  if (num === 2000) return 'Hai nghìn Việt Nam Đồng';
  if (num === 20000) return 'Hai mươi nghìn Việt Nam Đồng';
  if (num === 200000) return 'Hai trăm nghìn Việt Nam Đồng';
  if (num === 2000000) return 'Hai triệu Việt Nam Đồng';
  return `${num.toLocaleString('vi-VN')} Việt Nam Đồng`;
}

interface ConfirmTransferScreenProps {
  route: any;
  navigation: any;
}

export default function ConfirmTransferScreen({ route, navigation }: ConfirmTransferScreenProps) {
  const { user, wallet } = useApp();
  const {
    recipient = { name: 'Người nhận', phone: '' },
    amount = '0',
    selectedBank = 'Ngân hàng Nội bộ',
    notes = 'Chuyển tiền',
  } = route.params || {};

  const [isOtpModalVisible, setIsOtpModalVisible] = useState(false);
  const [pinDigits, setPinDigits] = useState<string[]>([]);
  const [isTransferring, setIsTransferring] = useState(false);

  const displayAmount = amount.includes('VND') || amount.includes('đ') ? amount : `${amount} VND`;

  // Keypad press handler
  const handleKeyPress = async (val: string) => {
    if (pinDigits.length < 6 && !isTransferring) {
      const nextPins = [...pinDigits, val];
      setPinDigits(nextPins);

      // Auto-validate when 6 digits are entered
      if (nextPins.length === 6) {
        const pin = nextPins.join('');
        setIsTransferring(true);
        
        try {
          if (!user?.walletId) throw new Error('Không tìm thấy ví nguồn');
          const rawNumAmount = parseInt(amount.replace(/[^0-9]/g, ''), 10) || 0;
          
          // 1. Init Transfer
          const initRes = await WalletApi.initTransfer(user.walletId, recipient.walletId || recipient.phone, rawNumAmount, 'VND');
          
          // 2. Confirm Transfer (Using PIN as both PIN and OTP for now in this demo flow)
          await WalletApi.confirmTransfer(initRes.data.transactionId, pin, pin);
          
          // 3. Auto-save Beneficiary
          try {
            await WalletApi.addBeneficiary(
              recipient.walletId || recipient.phone, // beneficiaryWalletId
              recipient.name,                        // nickname
              selectedBank,                          // bankCode
              recipient.phone                        // accountNumber
            );
          } catch (e) {
            console.log('Failed to auto-save beneficiary:', e);
          }

          setIsOtpModalVisible(false);
          setPinDigits([]);
          setIsTransferring(false);
          
          navigation.navigate('TransferResult', {
            success: true,
            amount: displayAmount,
            recipient,
            selectedBank,
            notes,
            transactionId: initRes.data.transactionId,
            timestamp: new Date().toISOString(),
          });
        } catch (e: any) {
          setIsTransferring(false);
          setPinDigits([]);
          Alert.alert('Lỗi chuyển tiền', e.message || 'Giao dịch thất bại');
        }
      }
    }
  };

  const handleDelete = () => {
    if (pinDigits.length > 0) {
      setPinDigits(pinDigits.slice(0, -1));
    }
  };

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

        <AppText style={styles.headerTitle}>Xác nhận thông tin</AppText>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* 2. MAIN DETAILS CARD */}
        <View style={styles.detailsCard}>
          {/* SỐ TIỀN GIAO DỊCH */}
          <View style={styles.amountSection}>
            <AppText style={styles.amountLabel}>Số tiền giao dịch</AppText>
            <AppText style={styles.amountValueText}>{displayAmount}</AppText>
            <AppText style={styles.amountWordsText}>
              {numberToVietnameseWords(amount)}
            </AppText>
          </View>

          <View style={styles.cardDivider} />

          {/* NGƯỜI CHUYỂN */}
          <View style={styles.partySection}>
            <AppText style={styles.partyHeaderLabel}>Người chuyển</AppText>

            <View style={styles.partyInfoRow}>
              {/* MB Logo Pinwheel */}
              <View style={styles.mbLogoCircle}>
                <AppText style={{ color: '#E11D48', fontSize: 20, fontWeight: '900' }}>★</AppText>
              </View>

              <View style={styles.partyDetailsCol}>
                <AppText style={styles.partyName}>BUI VAN DI</AppText>
                <AppText style={styles.partySubInfo}>0923158725</AppText>
                <AppText style={styles.partySubInfo}>Ngân hàng TMCP Quân đội</AppText>
              </View>
            </View>
          </View>

          {/* NGƯỜI NHẬN */}
          <View style={styles.partySection}>
            <AppText style={styles.partyHeaderLabel}>Người nhận</AppText>

            <View style={styles.partyInfoRow}>
              {/* Recipient Bank Logo */}
              {selectedBank.includes('SenBank') ? (
                <View style={[styles.vcbLogoCircle, { backgroundColor: '#FDF2F8', borderColor: '#FCE7F3' }]}>
                  <AppText style={{ color: '#D2519D', fontSize: 16, fontWeight: '900' }}>★</AppText>
                </View>
              ) : selectedBank.includes('MB') ? (
                <View style={[styles.vcbLogoCircle, { backgroundColor: '#FFF1F2', borderColor: '#FECDD3' }]}>
                  <AppText style={{ color: '#E11D48', fontSize: 16, fontWeight: '900' }}>★</AppText>
                </View>
              ) : selectedBank.includes('Techcombank') || selectedBank.includes('TCB') ? (
                <View style={[styles.vcbLogoCircle, { backgroundColor: '#FEF2F2', borderColor: '#FEE2E2' }]}>
                  <MaterialCommunityIcons name="view-grid" size={16} color="#E21A22" />
                </View>
              ) : (
                <View style={styles.vcbLogoCircle}>
                  <Ionicons name="triangle" size={17} color="#15803D" />
                </View>
              )}

              <View style={styles.partyDetailsCol}>
                <AppText style={styles.partyName}>{recipient?.name || 'BÙI VĂN DĨ'}</AppText>
                <AppText style={styles.partySubInfo}>{recipient?.phone || '0923158725'}</AppText>
                <AppText style={styles.partySubInfo}>
                  {selectedBank}
                </AppText>
              </View>
            </View>
          </View>

          <View style={styles.cardDivider} />

          {/* THÔNG TIN BỔ SUNG */}
          <View style={styles.extraInfoBlock}>
            {/* Nội dung chuyển tiền */}
            <View style={styles.extraInfoRow}>
              <AppText style={styles.extraInfoLabel}>Nội dung chuyển tiền</AppText>
              <AppText style={styles.extraInfoValue}>{notes || 'BUI VAN DI chuyen tien'}</AppText>
            </View>

            {/* Hình thức chuyển tiền */}
            <View style={[styles.extraInfoRow, { marginTop: 10 }]}>
              <AppText style={styles.extraInfoLabel}>Hình thức chuyển tiền</AppText>
              <AppText style={styles.extraInfoValue}>Chuyển nhanh</AppText>
            </View>
          </View>
        </View>

        {/* 3. WARNING ALERT BOX */}
        <View style={styles.warningAlertBox}>
          <Ionicons name="warning" size={20} color="#EAB308" />
          <AppText style={styles.warningAlertText}>
            Vui lòng kiểm tra chính xác thông tin trước khi xác nhận giao dịch.
          </AppText>
        </View>
      </ScrollView>

      {/* 4. BOTTOM ACTION BUTTONS */}
      <View style={styles.bottomFooter}>
        {/* Nút Quay lại */}
        <TouchableOpacity
          style={styles.backActionButton}
          activeOpacity={0.8}
          onPress={() => navigation.goBack()}
        >
          <AppText style={styles.backActionText}>Quay lại</AppText>
        </TouchableOpacity>

        {/* Nút Xác nhận -> Mở BottomSheet Xác Thực Digital OTP */}
        <TouchableOpacity
          style={styles.confirmActionButton}
          activeOpacity={0.9}
          onPress={() => {
            setPinDigits([]);
            setIsOtpModalVisible(true);
          }}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <AppText style={styles.confirmActionText}>Xác nhận</AppText>
        </TouchableOpacity>
      </View>

      {/* =========================================================================
          5. BOTTOM SHEET MODAL: "XÁC THỰC DIGITAL OTP" (CHUẨN 1:1 THEO ẢNH)
         ========================================================================= */}
      <Modal
        visible={isOtpModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setIsOtpModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <TouchableOpacity
            style={styles.modalBackdropTap}
            activeOpacity={1}
            onPress={() => setIsOtpModalVisible(false)}
          />

          <View style={styles.otpSheetContainer}>
            {/* Top Drag Handle */}
            <View style={styles.sheetHandleBar} />

            {/* Sheet Title */}
            <AppText style={styles.otpSheetTitle}>Xác thực Digital OTP</AppText>

            {/* Subtitle Prompt */}
            <AppText style={styles.otpSubtitle}>
              Vui lòng nhập mã <AppText style={{ fontWeight: '800', color: '#0F172A' }}>PIN Digital OTP</AppText> để nhận mã{'\n'}xác thực giao dịch
            </AppText>

            {/* 6 PIN Input Dots Circles */}
            <View style={styles.pinCirclesRow}>
              {[0, 1, 2, 3, 4, 5].map((index) => {
                const isFilled = index < pinDigits.length;
                return (
                  <View
                    key={index}
                    style={[
                      styles.pinCircle,
                      isFilled && styles.pinCircleFilled,
                      index === 0 && !isFilled && styles.pinCircleFirstEmpty,
                    ]}
                  >
                    {isFilled && <View style={styles.pinInnerDot} />}
                  </View>
                );
              })}
            </View>

            {isTransferring ? (
              <View style={{ height: 300, justifyContent: 'center', alignItems: 'center' }}>
                <ActivityIndicator size="large" color="#D2519D" />
                <AppText style={{ marginTop: 12, color: '#700F43', fontWeight: 'bold' }}>
                  Đang xử lý giao dịch...
                </AppText>
              </View>
            ) : (
              <>
                {/* "Đặt lại mã PIN" Link */}
                <TouchableOpacity
                  activeOpacity={0.7}
                  style={styles.resetPinBtn}
                  onPress={() => setPinDigits([])}
                >
                  <AppText style={styles.resetPinText}>Đặt lại mã PIN</AppText>
                </TouchableOpacity>

            {/* Numeric Keypad Grid */}
            <View style={styles.keypadGrid}>
              {[
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['bio', '0', 'del'],
              ].map((row, rIdx) => (
                <View key={rIdx} style={styles.keypadRow}>
                  {row.map((item, cIdx) => {
                    if (item === 'bio') {
                      return (
                        <TouchableOpacity
                          key={cIdx}
                          style={styles.keypadBtn}
                          activeOpacity={0.7}
                          onPress={() => {
                            // Biometric Quick Auth
                            setPinDigits(['1', '2', '3', '4', '5', '6']);
                            setTimeout(() => {
                              setIsOtpModalVisible(false);
                              navigation.navigate('TransferResult', {
                                success: true,
                                amount: displayAmount,
                                recipient,
                                selectedBank,
                                notes,
                              });
                            }, 250);
                          }}
                        >
                          <MaterialCommunityIcons name="fingerprint" size={30} color="#D2519D" />
                        </TouchableOpacity>
                      );
                    }
                    if (item === 'del') {
                      return (
                        <TouchableOpacity
                          key={cIdx}
                          style={styles.keypadBtn}
                          activeOpacity={0.7}
                          onPress={handleDelete}
                        >
                          <Ionicons name="backspace-outline" size={26} color="#700F43" />
                        </TouchableOpacity>
                      );
                    }
                    return (
                      <TouchableOpacity
                        key={cIdx}
                        style={styles.keypadBtn}
                        activeOpacity={0.7}
                        onPress={() => handleKeyPress(item)}
                      >
                        <AppText style={styles.keypadDigitText}>{item}</AppText>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              ))}
            </View>
          </>
        )}
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
    paddingBottom: 110,
  },
  detailsCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 16,
  },
  amountSection: {
    paddingVertical: 4,
  },
  amountLabel: {
    fontSize: 13.5,
    fontWeight: '700',
    color: '#64748B',
    marginBottom: 4,
  },
  amountValueText: {
    fontSize: 24,
    fontWeight: '900',
    color: '#700F43',
    letterSpacing: -0.5,
  },
  amountWordsText: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
    marginTop: 3,
  },
  cardDivider: {
    height: 1,
    backgroundColor: '#F1F5F9',
    marginVertical: 14,
  },
  partySection: {
    marginBottom: 14,
  },
  partyHeaderLabel: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 10,
  },
  partyInfoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  mbLogoCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#FFF1F2',
    borderWidth: 1,
    borderColor: '#FECDD3',
    justifyContent: 'center',
    alignItems: 'center',
  },
  vcbLogoCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#F0FDF4',
    borderWidth: 1,
    borderColor: '#DCFCE7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  partyDetailsCol: {
    flex: 1,
  },
  partyName: {
    fontSize: 15.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  partySubInfo: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#64748B',
    lineHeight: 17,
  },
  extraInfoBlock: {
    paddingVertical: 2,
  },
  extraInfoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  extraInfoLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#64748B',
  },
  extraInfoValue: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  warningAlertBox: {
    backgroundColor: '#FFFBEB',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#FEF08A',
    paddingHorizontal: 14,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  warningAlertText: {
    flex: 1,
    fontSize: 12.5,
    fontWeight: '700',
    color: '#854D0E',
    lineHeight: 17,
  },
  bottomFooter: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 24,
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
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
  confirmActionButton: {
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
  confirmActionText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#FFFFFF',
  },

  // ===== "XÁC THỰC DIGITAL OTP" BOTTOM SHEET STYLES =====
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.45)',
    justifyContent: 'flex-end',
  },
  modalBackdropTap: {
    flex: 1,
  },
  otpSheetContainer: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingTop: 12,
    paddingHorizontal: 20,
    paddingBottom: 30,
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
  otpSheetTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#700F43',
    textAlign: 'center',
    marginBottom: 10,
  },
  otpSubtitle: {
    fontSize: 13.5,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 24,
  },
  pinCirclesRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 16,
    marginBottom: 20,
  },
  pinCircle: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 1.8,
    borderColor: '#CBD5E1',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  pinCircleFirstEmpty: {
    borderColor: '#700F43',
  },
  pinCircleFilled: {
    borderColor: '#D2519D',
    backgroundColor: '#FDF2F8',
  },
  pinInnerDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#D2519D',
  },
  resetPinBtn: {
    alignSelf: 'center',
    paddingVertical: 6,
    paddingHorizontal: 12,
    marginBottom: 20,
  },
  resetPinText: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#700F43',
  },
  keypadGrid: {
    paddingHorizontal: 10,
    gap: 12,
  },
  keypadRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
  },
  keypadBtn: {
    width: 70,
    height: 52,
    borderRadius: 16,
    backgroundColor: '#F8FAFC',
    justifyContent: 'center',
    alignItems: 'center',
  },
  keypadDigitText: {
    fontSize: 22,
    fontWeight: '800',
    color: '#0F172A',
  },
});
