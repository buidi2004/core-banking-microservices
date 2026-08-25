import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { useApp } from '../context/AppContext';
import { ActivityIndicator, Alert } from 'react-native';

const { width } = Dimensions.get('window');

interface RegisterScreenProps {
  navigation: any;
}

export default function RegisterScreen({ navigation }: any) {
  const { register, isLoading, lastError, clearError } = useApp();
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [idNumber, setIdNumber] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [agreed, setAgreed] = useState(false);

  const handleRegister = async () => {
    if (!fullName || !phone || !idNumber || !password) {
      Alert.alert('Lỗi', 'Vui lòng điền đầy đủ thông tin');
      return;
    }
    try {
      await register(phone, password);
      // Wait for 500ms to show success before navigating to KYC or SetPin
      setTimeout(() => {
        navigation.navigate('SetPin');
      }, 500);
    } catch (e: any) {
      Alert.alert('Đăng ký thất bại', lastError || e.message);
      clearError();
    }
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

        <AppText style={styles.headerTitle}>Mở tài khoản MBBank</AppText>

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
        {/* HERO BADGE */}
        <View style={styles.heroLogoWrap}>
          <View style={styles.mbLogoCircle}>
            <AppText style={{ color: '#E11D48', fontSize: 24, fontWeight: '900' }}>★</AppText>
          </View>
          <AppText style={styles.heroHeading}>Tài khoản số đẹp miễn phí</AppText>
          <AppText style={styles.heroSub}>Đăng ký trực tuyến siêu tốc chỉ trong 1 phút</AppText>
        </View>

        {/* INPUT 1: HỌ VÀ TÊN */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Họ và tên (In hoa không dấu)</AppText>
          <View style={styles.inputRow}>
            <Ionicons name="person-outline" size={20} color="#700F43" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.textInput}
              placeholder="VD: BUI VAN DI"
              placeholderTextColor="#94A3B8"
              value={fullName}
              onChangeText={(text) => setFullName(text.toUpperCase())}
              autoCapitalize="characters"
            />
          </View>
        </View>

        {/* INPUT 2: SỐ ĐIỆN THOẠI */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Số điện thoại chính chủ</AppText>
          <View style={styles.inputRow}>
            <Ionicons name="call-outline" size={20} color="#700F43" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.textInput}
              placeholder="Nhập số điện thoại"
              placeholderTextColor="#94A3B8"
              value={phone}
              onChangeText={setPhone}
              keyboardType="phone-pad"
            />
          </View>
        </View>

        {/* INPUT 3: SỐ CCCD */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Số CCCD gắn chip (12 số)</AppText>
          <View style={styles.inputRow}>
            <MaterialCommunityIcons name="card-account-details-outline" size={20} color="#700F43" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.textInput}
              placeholder="Nhập 12 số CCCD"
              placeholderTextColor="#94A3B8"
              value={idNumber}
              onChangeText={setIdNumber}
              keyboardType="number-pad"
              maxLength={12}
            />
          </View>
        </View>

        {/* INPUT 4: MẬT KHẨU */}
        <View style={styles.inputCard}>
          <AppText style={styles.inputLabel}>Mật khẩu đăng nhập</AppText>
          <View style={styles.inputRow}>
            <MaterialCommunityIcons name="lock-outline" size={20} color="#700F43" style={{ marginRight: 8 }} />
            <TextInput
              style={styles.textInput}
              placeholder="Tối thiểu 8 ký tự"
              placeholderTextColor="#94A3B8"
              value={password}
              onChangeText={setPassword}
              secureTextEntry={!showPassword}
            />
            <TouchableOpacity onPress={() => setShowPassword(!showPassword)}>
              <Ionicons
                name={showPassword ? "eye-off-outline" : "eye-outline"}
                size={20}
                color="#64748B"
              />
            </TouchableOpacity>
          </View>
        </View>

        {/* TERMS AGREEMENT NOTE */}
        <View style={styles.termsNoteBox}>
          <TouchableOpacity onPress={() => setAgreed(!agreed)}>
            <Ionicons 
              name={agreed ? "checkbox" : "square-outline"} 
              size={20} 
              color="#700F43" 
            />
          </TouchableOpacity>
          <AppText style={styles.termsNoteText}>
            Bằng việc nhấn "Tiếp tục", bạn xác nhận đã đọc và đồng ý vô điều kiện với{' '}
            <AppText
              style={styles.termsLinkText}
              onPress={() => navigation.navigate('TermsOfService')}
            >
              Điều khoản & Điều kiện sử dụng dịch vụ MBBank
            </AppText>
            .
          </AppText>
        </View>

        {/* SUBMIT BUTTON */}
        <TouchableOpacity
          style={[styles.submitBtn, (!agreed || isLoading) && { opacity: 0.5 }]}
          activeOpacity={0.8}
          disabled={!agreed || isLoading}
          onPress={handleRegister}
        >
          <LinearGradient
            colors={['#D2519D', '#E11D48']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          {isLoading ? (
            <ActivityIndicator color="#FFF" />
          ) : (
            <AppText style={styles.submitBtnText}>Tiếp tục</AppText>
          )}
        </TouchableOpacity>

        {/* BACK TO LOGIN */}
        <TouchableOpacity
          style={styles.loginLinkBtn}
          activeOpacity={0.7}
          onPress={() => navigation.navigate('Login')}
        >
          <AppText style={styles.loginLinkText}>
            Đã có tài khoản? <AppText style={{ color: '#700F43', fontWeight: '800' }}>Đăng nhập ngay</AppText>
          </AppText>
        </TouchableOpacity>
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
  heroLogoWrap: {
    alignItems: 'center',
    marginBottom: 20,
  },
  mbLogoCircle: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#FFF1F2',
    borderWidth: 1.5,
    borderColor: '#FECDD3',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  heroHeading: {
    fontSize: 19,
    fontWeight: '900',
    color: '#700F43',
    marginBottom: 4,
  },
  heroSub: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '600',
  },
  inputCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 12,
  },
  inputLabel: {
    fontSize: 12.5,
    fontWeight: '700',
    color: '#64748B',
    marginBottom: 6,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1.5,
    borderBottomColor: '#D2519D',
    paddingBottom: 4,
  },
  textInput: {
    flex: 1,
    fontSize: 15,
    fontWeight: '700',
    color: '#0F172A',
  },
  termsNoteBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    backgroundColor: '#FDF2F8',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FCE7F3',
    padding: 12,
    marginVertical: 14,
  },
  termsNoteText: {
    flex: 1,
    fontSize: 12.5,
    color: '#64748B',
    lineHeight: 18,
  },
  termsLinkText: {
    color: '#700F43',
    fontWeight: '800',
    textDecorationLine: 'underline',
  },
  submitBtn: {
    height: 50,
    borderRadius: 25,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 4,
    marginBottom: 16,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
  loginLinkBtn: {
    alignItems: 'center',
    paddingVertical: 8,
  },
  loginLinkText: {
    fontSize: 14,
    color: '#64748B',
    fontWeight: '600',
  },
});
