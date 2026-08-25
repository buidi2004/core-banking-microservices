import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, Alert, SafeAreaView, StatusBar, Dimensions } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { WalletApi } from '../services/api';
import { useApp } from '../context/AppContext';

const { width } = Dimensions.get('window');

interface BillConfirmScreenProps {
  route: any;
  navigation: any;
}

export default function BillConfirmScreen({ route, navigation }: BillConfirmScreenProps) {
  const { provider = 'Tiền điện', billId = 'BILL-12345', amount = 350000 } = route.params || {};
  const { user } = useApp();
  const [pinDigits, setPinDigits] = useState<string[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);

  const displayAmount = amount.toLocaleString('vi-VN') + ' VND';

  const handleKeyPress = async (val: string) => {
    if (pinDigits.length < 6 && !isProcessing) {
      const nextPins = [...pinDigits, val];
      setPinDigits(nextPins);

      if (nextPins.length === 6) {
        setIsProcessing(true);
        try {
          if (!user?.walletId) throw new Error('Không tìm thấy ví');

          // Directly call payBill 
          const res = await WalletApi.payBill(user.walletId, billId, amount);

          navigation.navigate('TransferResult', {
            success: true,
            amount: displayAmount,
            recipient: { name: provider, phone: billId },
            selectedBank: 'Thanh toán hóa đơn',
            notes: `Thanh toán ${provider}`,
            transactionId: res.data?.id || 'TXN-BILL-000',
            timestamp: new Date().toISOString(),
          });
        } catch (e: any) {
          setIsProcessing(false);
          setPinDigits([]);
          Alert.alert('Lỗi thanh toán', e.message || 'Thanh toán thất bại');
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
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} activeOpacity={0.7} onPress={() => navigation.goBack()}>
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Xác nhận thanh toán</AppText>
        <View style={{ width: 40 }} />
      </View>

      <View style={styles.content}>
        <AppText style={styles.title}>Nhập mã PIN</AppText>
        <AppText style={styles.subtitle}>Thanh toán {displayAmount} cho {provider}</AppText>
        
        <View style={styles.pinCirclesRow}>
          {[0, 1, 2, 3, 4, 5].map((index) => {
            const isFilled = index < pinDigits.length;
            return (
              <View key={index} style={[styles.pinCircle, isFilled && styles.pinCircleFilled]}>
                {isFilled && <View style={styles.pinInnerDot} />}
              </View>
            );
          })}
        </View>

        {isProcessing && <AppText style={styles.processingText}>Đang xử lý giao dịch...</AppText>}

        <View style={styles.keyboardContainer}>
          {[
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ].map((row, rowIndex) => (
            <View key={rowIndex} style={styles.keyboardRow}>
              {row.map((key) => (
                <TouchableOpacity key={key} style={styles.keyBtn} onPress={() => handleKeyPress(key)}>
                  <AppText style={styles.keyText}>{key}</AppText>
                </TouchableOpacity>
              ))}
            </View>
          ))}
          <View style={styles.keyboardRow}>
            <View style={styles.keyBtn} />
            <TouchableOpacity style={styles.keyBtn} onPress={() => handleKeyPress('0')}>
              <AppText style={styles.keyText}>0</AppText>
            </TouchableOpacity>
            <TouchableOpacity style={styles.keyBtn} onPress={handleDelete}>
              <Ionicons name="backspace-outline" size={28} color="#0F172A" />
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, height: 56, borderBottomWidth: 1, borderBottomColor: '#F1F5F9' },
  backBtn: { width: 40, height: 40, justifyContent: 'center', alignItems: 'flex-start' },
  headerTitle: { fontSize: 18, fontWeight: '700', color: '#0F172A' },
  content: { flex: 1, alignItems: 'center', paddingTop: 40 },
  title: { fontSize: 22, fontWeight: '700', color: '#0F172A', marginBottom: 8 },
  subtitle: { fontSize: 14, color: '#64748B', marginBottom: 32 },
  pinCirclesRow: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 16, marginBottom: 40 },
  pinCircle: { width: 16, height: 16, borderRadius: 8, borderWidth: 1.5, borderColor: '#CBD5E1', justifyContent: 'center', alignItems: 'center' },
  pinCircleFilled: { borderColor: '#700F43' },
  pinInnerDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: '#700F43' },
  processingText: { fontSize: 14, color: '#700F43', marginBottom: 20 },
  keyboardContainer: { width: '100%', paddingHorizontal: 24, marginTop: 'auto', paddingBottom: 40 },
  keyboardRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
  keyBtn: { width: (width - 48 - 32) / 3, height: 60, justifyContent: 'center', alignItems: 'center', borderRadius: 30, backgroundColor: '#F8FAFC' },
  keyText: { fontSize: 28, fontWeight: '600', color: '#0F172A' },
});
