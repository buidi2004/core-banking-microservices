import React from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Share,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

const { width } = Dimensions.get('window');

interface TransferResultScreenProps {
  route: any;
  navigation: any;
}

import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { WalletApi, getAuthToken } from '../services/api';

export default function TransferResultScreen({ route, navigation }: TransferResultScreenProps) {
  const {
    amount = '0 VND',
    recipient = { name: 'Người nhận', phone: '' },
    selectedBank = 'Ngân hàng Nội bộ',
    notes = 'Chuyển tiền',
    transactionId = '',
    timestamp = '',
  } = route.params || {};

  const displayAmount = amount.includes('VND') || amount.includes('đ') ? amount : `${amount} VND`;
  const cleanBankName = selectedBank.includes('VCB') || selectedBank.includes('Ngoại thương')
    ? 'Vietcombank (VCB)'
    : selectedBank;

  const displayDate = timestamp ? new Date(timestamp).toLocaleString('vi-VN') : new Date().toLocaleString('vi-VN');
  const [isDownloading, setIsDownloading] = React.useState(false);

  const handleShare = async () => {
    try {
      await Share.share({
        message: `[MBBank] Giao dịch chuyển tiền thành công số tiền ${displayAmount} đến ${recipient?.name || 'Người nhận'} (${cleanBankName}). Mã GD: ${transactionId}`,
      });
    } catch (error) {
      console.log(error);
    }
  };

  const handleSavePhoto = async () => {
    if (!transactionId) {
      Alert.alert('Lỗi', 'Không tìm thấy mã giao dịch để tải biên lai.');
      return;
    }
    
    setIsDownloading(true);
    try {
      const url = WalletApi.downloadReceipt(transactionId);
      const token = getAuthToken();
      const fileUri = `${FileSystem.documentDirectory}receipt_${transactionId}.pdf`;
      
      const { uri, status } = await FileSystem.downloadAsync(url, fileUri, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      
      if (status === 200) {
        const isAvailable = await Sharing.isAvailableAsync();
        if (isAvailable) {
          await Sharing.shareAsync(uri, {
            mimeType: 'application/pdf',
            dialogTitle: 'Chia sẻ biên lai giao dịch',
            UTI: 'com.adobe.pdf' // iOS support
          });
        } else {
          Alert.alert('Thành công', 'Biên lai đã được tải xuống thiết bị của bạn!');
        }
      } else {
        throw new Error(`Failed to download, status: ${status}`);
      }
    } catch (e: any) {
      console.error(e);
      Alert.alert('Lỗi', 'Không thể tải biên lai ngay lúc này. ' + e.message);
    } finally {
      setIsDownloading(false);
    }
  };

  const handleSaveTemplate = () => {
    Alert.alert('Thông báo', 'Đã lưu mẫu chuyển tiền thành công!');
  };

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <StatusBar barStyle="dark-content" backgroundColor="#F8FAFC" />

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* 1. OFFICIAL VECTOR CHECKMARK WITH GLOW HALO */}
        <View style={styles.checkIconWrapper}>
          <View style={styles.checkGlowHalo}>
            <Ionicons name="checkmark-circle" size={72} color="#0284C7" />
          </View>
        </View>

        {/* 2. SUCCESS HEADER & AMOUNT */}
        <AppText style={styles.successHeading}>Chuyển tiền thành công</AppText>
        <AppText style={styles.amountDisplay}>{displayAmount}</AppText>
        <AppText style={styles.dateTimeText}>{displayDate}</AppText>

        {/* Chevron Indicator */}
        <View style={styles.chevronWrap}>
          <Ionicons name="chevron-down" size={18} color="#700F43" />
        </View>

        {/* 3. TRANSACTION RECEIPT CARD */}
        <View style={styles.receiptCardWrapper}>
          <View style={styles.receiptCard}>
            {/* Recipient Name */}
            <AppText style={styles.recipientName}>{recipient?.name || 'Người nhận'}</AppText>

            {/* Bank Row */}
            <View style={styles.bankRow}>
              {cleanBankName.includes('SenBank') ? (
                <View style={[styles.vcbLogoSmall, { backgroundColor: '#FDF2F8' }]}>
                  <AppText style={{ color: '#D2519D', fontSize: 11, fontWeight: '900' }}>★</AppText>
                </View>
              ) : (
                <View style={styles.vcbLogoSmall}>
                  <Ionicons name="triangle" size={13} color="#15803D" />
                </View>
              )}
              <AppText style={styles.bankNameText}>{cleanBankName}</AppText>
            </View>

            {/* Account Number */}
            <AppText style={styles.accountNumberText}>{recipient?.phone}</AppText>

            {/* Transfer Message */}
            <AppText style={styles.transferMessageText}>{notes}</AppText>

            {/* Transaction ID */}
            {transactionId ? (
              <View style={{ marginTop: 15, paddingTop: 15, borderTopWidth: 1, borderStyle: 'dashed', borderColor: '#E2E8F0' }}>
                 <AppText style={{ fontSize: 12, color: '#64748B', textAlign: 'center' }}>Mã giao dịch: {transactionId}</AppText>
              </View>
            ) : null}
          </View>

          {/* Bottom Center Hanging Pill */}
          <View style={styles.hangingPillBtn}>
            <Ionicons name="chevron-down" size={16} color="#700F43" />
          </View>
        </View>

        {/* 4. THANK YOU TEXT & MB LOGO */}
        <AppText style={styles.thankYouText}>
          Cảm ơn bạn đã sử dụng dịch vụ của MBBank
        </AppText>

        <View style={styles.mbLogoRow}>
          <View style={styles.mbStarIcon}>
            <AppText style={{ color: '#E11D48', fontSize: 18, fontWeight: '900' }}>★</AppText>
          </View>
          <AppText style={styles.mbBrandText}>MB</AppText>
        </View>

        {/* 5. 3 ACTION BUTTONS (CHIA SẺ | LƯU ẢNH | LƯU MẪU) */}
        <View style={styles.threeActionsRow}>
          {/* Chia sẻ */}
          <TouchableOpacity
            style={styles.actionCol}
            activeOpacity={0.8}
            onPress={handleShare}
          >
            <View style={styles.circleActionBtn}>
              <Ionicons name="share-social-outline" size={22} color="#700F43" />
            </View>
            <AppText style={styles.actionLabel}>Chia sẻ</AppText>
          </TouchableOpacity>

          {/* Lưu ảnh */}
          <TouchableOpacity
            style={styles.actionCol}
            activeOpacity={0.8}
            onPress={handleSavePhoto}
          >
            <View style={styles.circleActionBtn}>
              <Ionicons name="camera-outline" size={22} color="#700F43" />
            </View>
            <AppText style={styles.actionLabel}>Lưu ảnh</AppText>
          </TouchableOpacity>

          {/* Lưu mẫu */}
          <TouchableOpacity
            style={styles.actionCol}
            activeOpacity={0.8}
            onPress={handleSaveTemplate}
          >
            <View style={styles.circleActionBtn}>
              <Ionicons name="receipt-outline" size={22} color="#700F43" />
            </View>
            <AppText style={styles.actionLabel}>Lưu mẫu</AppText>
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* 6. BOTTOM FULL-WIDTH CTA BUTTON */}
      <View style={styles.bottomFooter}>
        <TouchableOpacity
          style={styles.anotherTransactionBtn}
          activeOpacity={0.9}
          onPress={() => navigation.navigate('MainTabs')}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <AppText style={styles.anotherTransactionText}>
            Thực hiện giao dịch khác
          </AppText>
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
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 30,
    paddingBottom: 110,
    alignItems: 'center',
  },
  checkIconWrapper: {
    marginBottom: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkGlowHalo: {
    width: 86,
    height: 86,
    borderRadius: 43,
    backgroundColor: '#F0F9FF',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#BAE6FD',
    shadowColor: '#0284C7',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 10,
    elevation: 4,
  },
  successHeading: {
    fontSize: 20,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 6,
    textAlign: 'center',
  },
  amountDisplay: {
    fontSize: 32,
    fontWeight: '900',
    color: '#700F43',
    letterSpacing: -0.5,
    marginBottom: 6,
    textAlign: 'center',
  },
  dateTimeText: {
    fontSize: 13.5,
    fontWeight: '600',
    color: '#64748B',
    marginBottom: 6,
    textAlign: 'center',
  },
  chevronWrap: {
    marginBottom: 16,
    alignItems: 'center',
  },
  receiptCardWrapper: {
    width: '100%',
    position: 'relative',
    marginBottom: 24,
  },
  receiptCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    paddingVertical: 20,
    paddingHorizontal: 16,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 3,
  },
  recipientName: {
    fontSize: 17,
    fontWeight: '900',
    color: '#0F172A',
    marginBottom: 8,
  },
  bankRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  vcbLogoSmall: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: '#F0FDF4',
    borderWidth: 1,
    borderColor: '#DCFCE7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  bankNameText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
  },
  accountNumberText: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 8,
    letterSpacing: 0.3,
  },
  transferMessageText: {
    fontSize: 14.5,
    fontWeight: '700',
    color: '#0F172A',
  },
  hangingPillBtn: {
    position: 'absolute',
    bottom: -14,
    alignSelf: 'center',
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#FDF2F8',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  thankYouText: {
    fontSize: 13.5,
    fontWeight: '600',
    color: '#64748B',
    textAlign: 'center',
    marginBottom: 10,
  },
  mbLogoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    marginBottom: 30,
  },
  mbStarIcon: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  mbBrandText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#700F43',
    letterSpacing: 0.5,
  },
  threeActionsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    width: '100%',
    paddingHorizontal: 16,
  },
  actionCol: {
    alignItems: 'center',
    gap: 8,
  },
  circleActionBtn: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 3,
  },
  actionLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
  },
  bottomFooter: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#F8FAFC',
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 24,
  },
  anotherTransactionBtn: {
    width: '100%',
    height: 50,
    borderRadius: 14,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 5,
  },
  anotherTransactionText: {
    fontSize: 16,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.2,
  },
});
