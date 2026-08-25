import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Modal,
  ActivityIndicator,
  Alert
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';
import { WalletApi } from '../services/api';

const { width } = Dimensions.get('window');

function numberToVietnameseWords(numStr: string): string {
  const num = parseInt(numStr.replace(/[^0-9]/g, ''), 10);
  if (isNaN(num) || num === 0) return 'Không Đồng';
  if (num === 2000) return 'Hai nghìn Việt Nam Đồng';
  if (num === 20000) return 'Hai mươi nghìn Việt Nam Đồng';
  if (num === 200000) return 'Hai trăm nghìn Việt Nam Đồng';
  if (num === 2000000) return 'Hai triệu Việt Nam Đồng';
  return `${num.toLocaleString('vi-VN')} Việt Nam Đồng`;
}

interface DepositConfirmScreenProps {
  route: any;
  navigation: any;
}

export default function DepositConfirmScreen({ route, navigation }: DepositConfirmScreenProps) {
  const { user } = useApp();
  const {
    amount = '2,000',
    selectedSource = 'Vietcombank ****8888',
  } = route.params || {};

  const [isOtpModalVisible, setIsOtpModalVisible] = useState(false);
  const [pinDigits, setPinDigits] = useState<string[]>([]);
  const [isTransferring, setIsTransferring] = useState(false);

  const displayAmount = amount.includes('VND') || amount.includes('đ') ? amount : `${amount} VND`;

  const handleKeyPress = async (val: string) => {
    if (pinDigits.length < 6 && !isTransferring) {
      const nextPins = [...pinDigits, val];
      setPinDigits(nextPins);

      if (nextPins.length === 6) {
        setIsTransferring(true);
        
        try {
          if (!user?.walletId) throw new Error('Không tìm thấy ví đích');
          const rawNumAmount = parseInt(amount.replace(/[^0-9]/g, ''), 10) || 0;
          
          const depositRes = await WalletApi.deposit(user.walletId, rawNumAmount, 'VND');
          
          setIsOtpModalVisible(false);
          setPinDigits([]);
          setIsTransferring(false);
          
          // Chuyển hướng tới kết quả với cấu trúc form tương tự giao dịch thành công
          navigation.navigate('TransferResult', {
            success: true,
            amount: displayAmount,
            recipient: { name: user.name || 'Người dùng', phone: user.phoneNumber },
            selectedBank: 'Ví SenBank',
            notes: `Nạp tiền từ ${selectedSource}`,
            transactionId: depositRes.data?.id,
            timestamp: new Date().toISOString(),
          });
        } catch (e: any) {
          setIsTransferring(false);
          setPinDigits([]);
          Alert.alert('Lỗi nạp tiền', e.message || 'Giao dịch thất bại');
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
        <TouchableOpacity style={styles.backBtn} activeOpacity={0.7} onPress={() => navigation.goBack()}>
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Xác nhận nạp tiền</AppText>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        {/* 2. MAIN DETAILS CARD */}
        <View style={styles.detailsCard}>
          <View style={styles.amountSection}>
            <AppText style={styles.amountLabel}>Số tiền nạp</AppText>
            <AppText style={styles.amountValueText}>{displayAmount}</AppText>
            <AppText style={styles.amountWordsText}>{numberToVietnameseWords(amount)}</AppText>
          </View>

          <View style={styles.cardDivider} />

          <View style={styles.partySection}>
            <AppText style={styles.partyHeaderLabel}>Nguồn tiền</AppText>
            <View style={styles.partyInfoRow}>
              <View style={styles.vcbLogoCircle}>
                <Ionicons name="card" size={17} color="#15803D" />
              </View>
              <View style={styles.partyDetailsCol}>
                <AppText style={styles.partyName}>{selectedSource}</AppText>
                <AppText style={styles.partySubInfo}>Thẻ thanh toán nội địa</AppText>
              </View>
            </View>
          </View>

          <View style={styles.cardDivider} />

          <View style={styles.partySection}>
            <AppText style={styles.partyHeaderLabel}>Nạp vào ví</AppText>
            <View style={styles.partyInfoRow}>
              <View style={[styles.mbLogoCircle, { backgroundColor: '#FDF2F8' }]}>
                <AppText style={{ color: '#D2519D', fontSize: 16, fontWeight: '900' }}>★</AppText>
              </View>
              <View style={styles.partyDetailsCol}>
                <AppText style={styles.partyName}>Ví SenBank của tôi</AppText>
                <AppText style={styles.partySubInfo}>{user?.phoneNumber || 'SĐT Của Bạn'}</AppText>
              </View>
            </View>
          </View>
          
          <View style={styles.cardDivider} />

          <View style={styles.extraInfoBlock}>
            <View style={styles.extraInfoRow}>
              <AppText style={styles.extraInfoLabel}>Phí giao dịch</AppText>
              <AppText style={styles.extraInfoValue}>Miễn phí</AppText>
            </View>
          </View>
        </View>
      </ScrollView>

      {/* 3. BOTTOM ACTIONS */}
      <View style={styles.bottomFooter}>
        <TouchableOpacity style={styles.confirmActionButton} activeOpacity={0.9} onPress={() => setIsOtpModalVisible(true)}>
          <LinearGradient colors={['#D2519D', '#700F43']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }} style={StyleSheet.absoluteFill} />
          <AppText style={styles.confirmActionText}>Xác nhận nạp tiền</AppText>
        </TouchableOpacity>
      </View>

      {/* 4. PIN/OTP BOTTOM SHEET */}
      <Modal visible={isOtpModalVisible} transparent animationType="slide" onRequestClose={() => setIsOtpModalVisible(false)}>
        <View style={styles.otpModalOverlay}>
          <TouchableOpacity style={styles.otpBackdropTap} onPress={() => setIsOtpModalVisible(false)} />
          <View style={styles.otpModalContent}>
            <View style={styles.otpModalHeader}>
              <AppText style={styles.otpModalTitle}>Nhập mã PIN</AppText>
              <TouchableOpacity onPress={() => setIsOtpModalVisible(false)}>
                <Ionicons name="close" size={24} color="#0F172A" />
              </TouchableOpacity>
            </View>

            <AppText style={styles.otpModalSubtitle}>
              Mã PIN của bạn dùng để xác thực giao dịch nạp tiền.
            </AppText>

            <View style={styles.pinDotsRow}>
              {[1, 2, 3, 4, 5, 6].map((idx) => {
                const isFilled = pinDigits.length >= idx;
                return (
                  <View key={idx} style={[styles.pinDot, isFilled && styles.pinDotFilled]} />
                );
              })}
            </View>

            {isTransferring && (
              <View style={{ alignItems: 'center', marginTop: 15 }}>
                <ActivityIndicator size="small" color="#D2519D" />
                <AppText style={{ color: '#D2519D', marginTop: 5 }}>Đang xử lý nạp tiền...</AppText>
              </View>
            )}

            <View style={styles.keypadContainer}>
              {[
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['faceid', '0', 'delete']
              ].map((row, rIdx) => (
                <View key={`row-${rIdx}`} style={styles.keypadRow}>
                  {row.map((btn) => {
                    if (btn === 'faceid') {
                      return (
                        <TouchableOpacity key={btn} style={styles.keypadBtn} activeOpacity={0.7}>
                          <Ionicons name="scan" size={28} color="#D2519D" />
                        </TouchableOpacity>
                      );
                    }
                    if (btn === 'delete') {
                      return (
                        <TouchableOpacity key={btn} style={styles.keypadBtn} activeOpacity={0.7} onPress={handleDelete}>
                          <Ionicons name="backspace-outline" size={28} color="#0F172A" />
                        </TouchableOpacity>
                      );
                    }
                    return (
                      <TouchableOpacity key={btn} style={styles.keypadBtn} activeOpacity={0.7} onPress={() => handleKeyPress(btn)}>
                        <AppText style={styles.keypadBtnText}>{btn}</AppText>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              ))}
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 12, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderBottomColor: '#F1F5F9' },
  backBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#FDF2F8', alignItems: 'center', justifyContent: 'center' },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#0F172A' },
  scrollContent: { padding: 16, paddingBottom: 100 },
  detailsCard: { backgroundColor: '#FFFFFF', borderRadius: 16, padding: 20, shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.05, shadowRadius: 12, elevation: 3 },
  amountSection: { alignItems: 'center', marginBottom: 20 },
  amountLabel: { fontSize: 13, color: '#64748B', fontWeight: '500', marginBottom: 8 },
  amountValueText: { fontSize: 32, fontWeight: '800', color: '#700F43', marginBottom: 4 },
  amountWordsText: { fontSize: 13, color: '#94A3B8', fontStyle: 'italic' },
  cardDivider: { height: 1, backgroundColor: '#F1F5F9', marginVertical: 16, borderStyle: 'dashed' },
  partySection: { marginBottom: 4 },
  partyHeaderLabel: { fontSize: 12, color: '#94A3B8', fontWeight: '600', textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 12 },
  partyInfoRow: { flexDirection: 'row', alignItems: 'center' },
  mbLogoCircle: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#FFF1F2', alignItems: 'center', justifyContent: 'center', marginRight: 12, borderWidth: 1, borderColor: '#FFE4E6' },
  vcbLogoCircle: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#ECFCCB', alignItems: 'center', justifyContent: 'center', marginRight: 12, borderWidth: 1, borderColor: '#D9F99D' },
  partyDetailsCol: { flex: 1 },
  partyName: { fontSize: 15, fontWeight: '700', color: '#0F172A', marginBottom: 2 },
  partySubInfo: { fontSize: 13, color: '#64748B' },
  extraInfoBlock: { marginTop: 4 },
  extraInfoRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  extraInfoLabel: { fontSize: 13, color: '#64748B', flex: 1 },
  extraInfoValue: { fontSize: 14, color: '#0F172A', fontWeight: '500', flex: 2, textAlign: 'right' },
  bottomFooter: { position: 'absolute', bottom: 0, left: 0, right: 0, paddingHorizontal: 20, paddingTop: 12, paddingBottom: 30, backgroundColor: '#FFFFFF', borderTopWidth: 1, borderTopColor: '#F1F5F9' },
  confirmActionButton: { height: 50, borderRadius: 25, overflow: 'hidden', alignItems: 'center', justifyContent: 'center' },
  confirmActionText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  otpModalOverlay: { flex: 1, backgroundColor: 'rgba(15, 23, 42, 0.4)', justifyContent: 'flex-end' },
  otpBackdropTap: { flex: 1 },
  otpModalContent: { backgroundColor: '#FFFFFF', borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24, paddingBottom: 40 },
  otpModalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  otpModalTitle: { fontSize: 18, fontWeight: '700', color: '#0F172A' },
  otpModalSubtitle: { fontSize: 14, color: '#64748B', lineHeight: 20, marginBottom: 24 },
  pinDotsRow: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginBottom: 30, gap: 16 },
  pinDot: { width: 16, height: 16, borderRadius: 8, backgroundColor: '#E2E8F0' },
  pinDotFilled: { backgroundColor: '#D2519D' },
  keypadContainer: { gap: 12 },
  keypadRow: { flexDirection: 'row', justifyContent: 'space-between' },
  keypadBtn: { width: '30%', aspectRatio: 2, backgroundColor: '#F8FAFC', borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  keypadBtnText: { fontSize: 24, fontWeight: '600', color: '#0F172A' },
});
