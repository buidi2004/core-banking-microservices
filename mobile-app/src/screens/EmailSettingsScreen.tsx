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
import { useApp } from '../context/AppContext';

const { width } = Dimensions.get('window');

interface EmailSettingsScreenProps {
  navigation: any;
}

export default function EmailSettingsScreen({ navigation }: EmailSettingsScreenProps) {
  const { user } = useApp();
  const [currentEmail, setCurrentEmail] = useState((user as any)?.email || '');
  const [newEmail, setNewEmail] = useState('');
  const [isEditing, setIsEditing] = useState(false);

  const handleSaveEmail = () => {
    if (!newEmail.includes('@') || !newEmail.includes('.')) {
      Alert.alert('Lỗi', 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }
    setCurrentEmail(newEmail);
    setIsEditing(false);
    setNewEmail('');
    Alert.alert('Thành công', 'Đã cập nhật địa chỉ Email nhận thông báo biến động & biên lai giao dịch.');
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

        <AppText style={styles.headerTitle}>Địa chỉ Email</AppText>

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
        {/* CURRENT EMAIL CARD */}
        <View style={styles.currentEmailCard}>
          <View style={styles.emailIconWrap}>
            <Ionicons name="mail-outline" size={32} color="#700F43" />
          </View>

          <View style={{ flex: 1 }}>
            <AppText style={styles.emailCardLabel}>Email nhận thông báo & sao kê</AppText>
            <AppText style={styles.emailValueText}>{currentEmail}</AppText>
            <View style={styles.verifiedTag}>
              <Ionicons name="checkmark-circle" size={14} color="#10B981" />
              <AppText style={styles.verifiedTagText}>Đã xác thực</AppText>
            </View>
          </View>
        </View>

        {/* EDIT / UPDATE EMAIL SECTION */}
        {isEditing ? (
          <View style={styles.editSectionCard}>
            <AppText style={styles.editCardTitle}>Nhập địa chỉ Email mới</AppText>

            <View style={styles.inputRow}>
              <TextInput
                style={styles.emailInput}
                placeholder="vidu@gmail.com"
                placeholderTextColor="#94A3B8"
                value={newEmail}
                onChangeText={setNewEmail}
                keyboardType="email-address"
                autoCapitalize="none"
              />
            </View>

            <View style={styles.editBtnRow}>
              <TouchableOpacity
                style={styles.cancelBtn}
                activeOpacity={0.7}
                onPress={() => {
                  setIsEditing(false);
                  setNewEmail('');
                }}
              >
                <AppText style={styles.cancelBtnText}>Hủy</AppText>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.saveBtn}
                activeOpacity={0.9}
                onPress={handleSaveEmail}
              >
                <LinearGradient
                  colors={['#D2519D', '#700F43']}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 0 }}
                  style={StyleSheet.absoluteFill}
                />
                <AppText style={styles.saveBtnText}>Lưu Email</AppText>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <TouchableOpacity
            style={styles.changeEmailButton}
            activeOpacity={0.9}
            onPress={() => setIsEditing(true)}
          >
            <LinearGradient
              colors={['#D2519D', '#700F43']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={StyleSheet.absoluteFill}
            />
            <MaterialCommunityIcons name="email-edit-outline" size={20} color="#FFFFFF" style={{ marginRight: 8 }} />
            <AppText style={styles.changeEmailButtonText}>Thay đổi địa chỉ Email</AppText>
          </TouchableOpacity>
        )}

        {/* EMAIL BENEFITS CARD */}
        <View style={styles.infoCard}>
          <AppText style={styles.infoCardTitle}>Lợi ích khi đăng ký Email:</AppText>
          <View style={styles.benefitItem}>
            <Ionicons name="document-text-outline" size={18} color="#D2519D" />
            <AppText style={styles.benefitItemText}>Nhận bản sao kê tài khoản định kỳ hàng tháng</AppText>
          </View>
          <View style={styles.benefitItem}>
            <Ionicons name="receipt-outline" size={18} color="#D2519D" />
            <AppText style={styles.benefitItemText}>Nhận biên lai điện tử cho mọi giao dịch thanh toán</AppText>
          </View>
          <View style={styles.benefitItem}>
            <Ionicons name="shield-checkmark-outline" size={18} color="#D2519D" />
            <AppText style={styles.benefitItemText}>Cảnh báo bảo mật tài khoản tức thì khi đăng nhập lạ</AppText>
          </View>
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
  currentEmailCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 16,
  },
  emailIconWrap: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  emailCardLabel: {
    fontSize: 12.5,
    color: '#64748B',
    fontWeight: '600',
    marginBottom: 3,
  },
  emailValueText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 4,
  },
  verifiedTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  verifiedTagText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#10B981',
  },
  changeEmailButton: {
    height: 48,
    borderRadius: 24,
    overflow: 'hidden',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 6,
    elevation: 4,
  },
  changeEmailButtonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
  editSectionCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 16,
    borderWidth: 1,
    borderColor: '#D2519D',
    marginBottom: 20,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  editCardTitle: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#700F43',
    marginBottom: 12,
  },
  inputRow: {
    borderBottomWidth: 1.5,
    borderBottomColor: '#D2519D',
    paddingBottom: 6,
    marginBottom: 16,
  },
  emailInput: {
    fontSize: 15,
    fontWeight: '700',
    color: '#0F172A',
  },
  editBtnRow: {
    flexDirection: 'row',
    gap: 12,
  },
  cancelBtn: {
    flex: 1,
    height: 42,
    borderRadius: 21,
    borderWidth: 1.5,
    borderColor: '#CBD5E1',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cancelBtnText: {
    fontSize: 14,
    fontWeight: '800',
    color: '#64748B',
  },
  saveBtn: {
    flex: 1.2,
    height: 42,
    borderRadius: 21,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
  },
  saveBtnText: {
    fontSize: 14,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  infoCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  infoCardTitle: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  benefitItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingVertical: 8,
  },
  benefitItemText: {
    fontSize: 13,
    color: '#475569',
    fontWeight: '600',
    flex: 1,
  },
});
