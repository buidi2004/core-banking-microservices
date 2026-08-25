import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Share,
  Alert,
  TextInput,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';
import { WalletApi } from '../services/api';
import QRCode from 'react-native-qrcode-svg';
import { ActivityIndicator } from 'react-native';

const { width } = Dimensions.get('window');

interface QRMyScreenProps {
  navigation: any;
}

export default function QRMyScreen({ navigation }: QRMyScreenProps) {
  const { user } = useApp();
  const [customAmount, setCustomAmount] = useState('');
  const [isSettingAmount, setIsSettingAmount] = useState(false);
  const [qrPayload, setQrPayload] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);

  React.useEffect(() => {
    const fetchQr = async () => {
      try {
        const res = await WalletApi.getMyQrCode();
        setQrPayload(res.data.fullQrPayload || res.data.qrData);
      } catch (e) {
        console.error('Failed to get QR code', e);
      } finally {
        setIsLoading(false);
      }
    };
    fetchQr();
  }, []);

  const accountInfo = {
    bankName: 'SenBank (Nội bộ SenBank)',
    accountNumber: user?.phoneNumber || '0923158725', // Phone as Account Number
    accountHolder: user?.name || 'BÙI VĂN DĨ',
  };

  const handleShare = async () => {
    try {
      await Share.share({
        message: `Mã QR nhận tiền SenBank:\n- Ngân hàng: SenBank\n- STK (Số ĐT): ${accountInfo.accountNumber}\n- Chủ TK: ${accountInfo.accountHolder}${customAmount ? `\n- Số tiền: ${parseInt(customAmount, 10).toLocaleString('vi-VN')} đ` : ''}`,
      });
    } catch (e) {
      console.log(e);
    }
  };

  const handleCopyAccount = () => {
    Alert.alert('Đã sao chép', `Đã sao chép STK SenBank: ${accountInfo.accountNumber}`);
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="light-content" backgroundColor="#700F43" />

      {/* HEADER WITH GRADIENT */}
      <LinearGradient
        colors={['#700F43', '#D2519D']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 0 }}
        style={styles.headerGradient}
      >
        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#FFFFFF" />
        </TouchableOpacity>

        <AppText style={styles.headerTitle}>Mã QR nhận tiền SenBank</AppText>

        <TouchableOpacity
          style={styles.headerBtn}
          activeOpacity={0.7}
          onPress={() => navigation.navigate('Home')}
        >
          <Ionicons name="home-outline" size={22} color="#FFFFFF" />
        </TouchableOpacity>
      </LinearGradient>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* MAIN QR CARD */}
        <View style={styles.qrMainCard}>
          {/* Card Header: SenBank Logo & VietQR */}
          <View style={styles.cardHeaderRow}>
            <View style={styles.bankBrandRow}>
              <View style={styles.senbankStarCircle}>
                <AppText style={{ color: '#E11D48', fontSize: 16, fontWeight: '900' }}>★</AppText>
              </View>
              <View>
                <AppText style={styles.brandTitle}>SenBank</AppText>
                <AppText style={styles.brandSubtitle}>Thanh toán siêu tốc 24/7</AppText>
              </View>
            </View>

            <View style={styles.napasVietQrBadge}>
              <AppText style={styles.vietQrText}>Viet<AppText style={{ color: '#E11D48' }}>QR</AppText></AppText>
            </View>
          </View>

          {/* QR CODE DISPLAY BOX */}
          <View style={styles.qrCodeWrapper}>
            {/* Visual QR Code Representation with Center Pinwheel */}
            <View style={styles.qrCanvas}>
              {/* Corner Targets */}
              <View style={[styles.qrCorner, { top: 12, left: 12 }]} />
              <View style={[styles.qrCorner, { top: 12, right: 12 }]} />
              <View style={[styles.qrCorner, { bottom: 12, left: 12 }]} />

              {isLoading ? (
                <View style={{ height: 170, justifyContent: 'center', alignItems: 'center' }}>
                  <ActivityIndicator size="large" color="#D2519D" />
                </View>
              ) : (
                <QRCode
                  value={
                    qrPayload 
                      ? (customAmount ? `${qrPayload}&amount=${customAmount}` : qrPayload)
                      : 'senbank://error'
                  }
                  size={170}
                  color="#0F172A"
                  backgroundColor="transparent"
                />
              )}

              {/* Center SenBank Logo in QR */}
              <View style={styles.qrCenterBadge}>
                <AppText style={{ color: '#E11D48', fontSize: 13, fontWeight: '900' }}>★</AppText>
              </View>
            </View>

            {customAmount ? (
              <View style={styles.amountPill}>
                <AppText style={styles.amountPillText}>
                  Số tiền: {parseInt(customAmount, 10).toLocaleString('vi-VN')} đ
                </AppText>
              </View>
            ) : null}
          </View>

          {/* ACCOUNT INFO */}
          <View style={styles.accountDetailsBlock}>
            <AppText style={styles.holderName}>{accountInfo.accountHolder}</AppText>

            <TouchableOpacity
              style={styles.accountNumRow}
              activeOpacity={0.7}
              onPress={handleCopyAccount}
            >
              <AppText style={styles.accountNumberLabel}>STK (Số ĐT):</AppText>
              <AppText style={styles.accountNumberText}>{accountInfo.accountNumber}</AppText>
              <Ionicons name="copy-outline" size={16} color="#700F43" />
            </TouchableOpacity>

            <AppText style={styles.bankNameText}>{accountInfo.bankName}</AppText>
          </View>
        </View>

        {/* SET CUSTOM AMOUNT TOGGLE */}
        <View style={styles.amountSettingCard}>
          <TouchableOpacity
            style={styles.settingToggleRow}
            activeOpacity={0.7}
            onPress={() => setIsSettingAmount(!isSettingAmount)}
          >
            <View style={styles.toggleLeft}>
              <MaterialCommunityIcons name="cash-plus" size={22} color="#700F43" />
              <AppText style={styles.toggleTitle}>Đặt số tiền chuyển</AppText>
            </View>
            <Ionicons
              name={isSettingAmount ? "chevron-up" : "chevron-down"}
              size={20}
              color="#700F43"
            />
          </TouchableOpacity>

          {isSettingAmount && (
            <View style={styles.inputAmountBlock}>
              <View style={styles.inputAmountRow}>
                <TextInput
                  style={styles.amountInput}
                  placeholder="Nhập số tiền cần nhận"
                  placeholderTextColor="#94A3B8"
                  keyboardType="numeric"
                  value={customAmount}
                  onChangeText={(val) => setCustomAmount(val.replace(/[^0-9]/g, ''))}
                />
                <AppText style={styles.currencyVnd}>VND</AppText>
              </View>
              {customAmount ? (
                <TouchableOpacity
                  style={styles.clearAmountBtn}
                  onPress={() => setCustomAmount('')}
                >
                  <AppText style={styles.clearAmountText}>Xóa số tiền</AppText>
                </TouchableOpacity>
              ) : null}
            </View>
          )}
        </View>

        {/* UTILITY ACTIONS ROW */}
        <View style={styles.actionButtonsRow}>
          {/* Download QR */}
          <TouchableOpacity
            style={styles.actionCircleBtn}
            activeOpacity={0.8}
            onPress={() => Alert.alert('Thành công', 'Đã lưu ảnh mã QR vào Thư viện ảnh!')}
          >
            <View style={styles.actionIconWrap}>
              <Ionicons name="download-outline" size={22} color="#700F43" />
            </View>
            <AppText style={styles.actionLabel}>Lưu ảnh QR</AppText>
          </TouchableOpacity>

          {/* Share QR */}
          <TouchableOpacity
            style={styles.actionCircleBtn}
            activeOpacity={0.8}
            onPress={handleShare}
          >
            <View style={styles.actionIconWrap}>
              <Ionicons name="share-social-outline" size={22} color="#700F43" />
            </View>
            <AppText style={styles.actionLabel}>Chia sẻ</AppText>
          </TouchableOpacity>

          {/* Transfer to someone */}
          <TouchableOpacity
            style={styles.actionCircleBtn}
            activeOpacity={0.8}
            onPress={() => navigation.navigate('Transfer')}
          >
            <View style={styles.actionIconWrap}>
              <MaterialCommunityIcons name="bank-transfer" size={24} color="#700F43" />
            </View>
            <AppText style={styles.actionLabel}>Chuyển tiền</AppText>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  headerGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
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
    color: '#FFFFFF',
    letterSpacing: -0.3,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 40,
    alignItems: 'center',
  },
  qrMainCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 20,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 4,
    marginBottom: 16,
  },
  cardHeaderRow: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    paddingBottom: 14,
    marginBottom: 16,
  },
  bankBrandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  senbankStarCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FFF1F2',
    borderWidth: 1,
    borderColor: '#FECDD3',
    justifyContent: 'center',
    alignItems: 'center',
  },
  brandTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: '#700F43',
  },
  brandSubtitle: {
    fontSize: 11,
    color: '#64748B',
    fontWeight: '600',
  },
  napasVietQrBadge: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  vietQrText: {
    fontSize: 12,
    fontWeight: '900',
    color: '#0284C7',
  },
  qrCodeWrapper: {
    padding: 16,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    borderWidth: 2,
    borderColor: '#FCE7F3',
    alignItems: 'center',
    marginBottom: 16,
  },
  qrCanvas: {
    width: 200,
    height: 200,
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  qrCorner: {
    position: 'absolute',
    width: 24,
    height: 24,
    borderWidth: 3,
    borderColor: '#700F43',
    borderRadius: 4,
  },
  qrCenterBadge: {
    position: 'absolute',
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#FFFFFF',
    borderWidth: 1.5,
    borderColor: '#D2519D',
    justifyContent: 'center',
    alignItems: 'center',
  },
  amountPill: {
    backgroundColor: '#FDF2F8',
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 12,
    marginTop: 10,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  amountPillText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#700F43',
  },
  accountDetailsBlock: {
    alignItems: 'center',
    width: '100%',
    paddingTop: 8,
  },
  holderName: {
    fontSize: 18,
    fontWeight: '900',
    color: '#0F172A',
    marginBottom: 6,
    letterSpacing: 0.5,
  },
  accountNumRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#FDF2F8',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    marginBottom: 6,
  },
  accountNumberLabel: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '600',
  },
  accountNumberText: {
    fontSize: 15,
    fontWeight: '900',
    color: '#700F43',
  },
  bankNameText: {
    fontSize: 12.5,
    color: '#64748B',
    fontWeight: '600',
  },
  amountSettingCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 20,
  },
  settingToggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  toggleLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  toggleTitle: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  inputAmountBlock: {
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  inputAmountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  amountInput: {
    flex: 1,
    height: 44,
    fontSize: 15,
    fontWeight: '700',
    color: '#0F172A',
  },
  currencyVnd: {
    fontSize: 13,
    fontWeight: '800',
    color: '#700F43',
  },
  clearAmountBtn: {
    alignSelf: 'flex-end',
    marginTop: 6,
    paddingVertical: 4,
  },
  clearAmountText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#E11D48',
  },
  actionButtonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    paddingHorizontal: 10,
  },
  actionCircleBtn: {
    alignItems: 'center',
    gap: 6,
  },
  actionIconWrap: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  actionLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: '#64748B',
  },
});
