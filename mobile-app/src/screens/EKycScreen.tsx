import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView, SafeAreaView, StatusBar, Alert, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { WalletApi } from '../services/api';

export default function EKycScreen({ navigation }: { navigation: any }) {
  const [idCardNumber, setIdCardNumber] = useState('');
  const [fullName, setFullName] = useState('');
  const [dob, setDob] = useState('');
  const [frontCardUploaded, setFrontCardUploaded] = useState(false);
  const [backCardUploaded, setBackCardUploaded] = useState(false);
  const [selfieUploaded, setSelfieUploaded] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isFormValid = idCardNumber && fullName && dob && frontCardUploaded && backCardUploaded && selfieUploaded;

  const handleSubmit = async () => {
    if (!isFormValid) return;
    setIsSubmitting(true);
    try {
      await WalletApi.submitKyc(
        idCardNumber,
        fullName,
        dob,
        'https://dummy.url/front.jpg',
        'https://dummy.url/back.jpg',
        'https://dummy.url/selfie.jpg'
      );
      Alert.alert('Thành công', 'Hồ sơ định danh của bạn đã được gửi đi.', [
        { text: 'Đóng', onPress: () => navigation.navigate('Home') }
      ]);
    } catch (e: any) {
      Alert.alert('Lỗi', e.message || 'Không thể nộp hồ sơ eKYC');
    } finally {
      setIsSubmitting(false);
    }
  };

  const simulateUpload = (type: string) => {
    Alert.alert('Mô phỏng Chụp ảnh', `Giả lập việc chụp và tải lên ảnh ${type}.`, [
      { text: 'Hủy', style: 'cancel' },
      { text: 'Chụp thành công', onPress: () => {
          if (type === 'Mặt trước CCCD') setFrontCardUploaded(true);
          if (type === 'Mặt sau CCCD') setBackCardUploaded(true);
          if (type === 'Khuôn mặt (Selfie)') setSelfieUploaded(true);
      }}
    ]);
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} activeOpacity={0.7} onPress={() => navigation.goBack()}>
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Định danh điện tử (eKYC)</AppText>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <AppText style={styles.sectionTitle}>Thông tin cá nhân</AppText>
        <View style={styles.inputGroup}>
          <AppText style={styles.label}>Số CCCD</AppText>
          <TextInput
            style={styles.input}
            placeholder="Ví dụ: 079204012891"
            value={idCardNumber}
            onChangeText={setIdCardNumber}
            keyboardType="number-pad"
          />
        </View>
        <View style={styles.inputGroup}>
          <AppText style={styles.label}>Họ và tên</AppText>
          <TextInput
            style={styles.input}
            placeholder="Ví dụ: BÙI VĂN DĨ"
            value={fullName}
            onChangeText={setFullName}
            autoCapitalize="characters"
          />
        </View>
        <View style={styles.inputGroup}>
          <AppText style={styles.label}>Ngày sinh</AppText>
          <TextInput
            style={styles.input}
            placeholder="Ví dụ: 15/08/2004"
            value={dob}
            onChangeText={setDob}
          />
        </View>

        <AppText style={[styles.sectionTitle, { marginTop: 20 }]}>Hình ảnh xác thực</AppText>
        <TouchableOpacity style={styles.uploadBtn} onPress={() => simulateUpload('Mặt trước CCCD')}>
          <Ionicons name={frontCardUploaded ? 'checkmark-circle' : 'camera'} size={24} color={frontCardUploaded ? '#10B981' : '#700F43'} />
          <AppText style={styles.uploadBtnText}>{frontCardUploaded ? 'Đã chụp Mặt trước CCCD' : 'Chụp Mặt trước CCCD'}</AppText>
        </TouchableOpacity>

        <TouchableOpacity style={styles.uploadBtn} onPress={() => simulateUpload('Mặt sau CCCD')}>
          <Ionicons name={backCardUploaded ? 'checkmark-circle' : 'camera'} size={24} color={backCardUploaded ? '#10B981' : '#700F43'} />
          <AppText style={styles.uploadBtnText}>{backCardUploaded ? 'Đã chụp Mặt sau CCCD' : 'Chụp Mặt sau CCCD'}</AppText>
        </TouchableOpacity>

        <TouchableOpacity style={styles.uploadBtn} onPress={() => simulateUpload('Khuôn mặt (Selfie)')}>
          <Ionicons name={selfieUploaded ? 'checkmark-circle' : 'person'} size={24} color={selfieUploaded ? '#10B981' : '#700F43'} />
          <AppText style={styles.uploadBtnText}>{selfieUploaded ? 'Đã chụp Khuôn mặt' : 'Chụp Selfie khuôn mặt'}</AppText>
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.submitBtn, (!isFormValid || isSubmitting) && styles.submitBtnDisabled]} 
          onPress={handleSubmit}
          disabled={!isFormValid || isSubmitting}
        >
          <AppText style={styles.submitBtnText}>{isSubmitting ? 'Đang gửi...' : 'Gửi hồ sơ'}</AppText>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, height: 56, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderBottomColor: '#F1F5F9' },
  backBtn: { width: 40, height: 40, justifyContent: 'center', alignItems: 'flex-start' },
  headerTitle: { fontSize: 18, fontWeight: '700', color: '#0F172A' },
  content: { padding: 20 },
  sectionTitle: { fontSize: 16, fontWeight: '600', color: '#0F172A', marginBottom: 16 },
  inputGroup: { marginBottom: 16 },
  label: { fontSize: 14, color: '#64748B', marginBottom: 8 },
  input: { backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E2E8F0', borderRadius: 8, padding: 12, fontSize: 16, color: '#0F172A' },
  uploadBtn: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', padding: 16, borderRadius: 8, marginBottom: 12, borderWidth: 1, borderColor: '#E2E8F0' },
  uploadBtnText: { marginLeft: 12, fontSize: 16, color: '#0F172A' },
  submitBtn: { backgroundColor: '#700F43', padding: 16, borderRadius: 30, alignItems: 'center', marginTop: 32 },
  submitBtnDisabled: { backgroundColor: '#CBD5E1' },
  submitBtnText: { color: '#FFFFFF', fontSize: 16, fontWeight: '600' }
});
