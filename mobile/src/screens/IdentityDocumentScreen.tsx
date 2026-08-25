import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  StatusBar,
  Dimensions,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { WalletApi } from '../services/api';

const { width } = Dimensions.get('window');

interface IdentityDocumentScreenProps {
  navigation: any;
}

export default function IdentityDocumentScreen({ navigation }: IdentityDocumentScreenProps) {
  const [showIdNumber, setShowIdNumber] = useState(true);
  const [kycData, setKycData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  React.useEffect(() => {
    const fetchKyc = async () => {
      try {
        const res = await WalletApi.getKycStatus();
        setKycData(res.data);
      } catch (e) {
        setKycData(null);
      } finally {
        setIsLoading(false);
      }
    };
    fetchKyc();
  }, []);

  const handleUpdateDocument = () => {
    navigation.navigate('EKyc');
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

        <AppText style={styles.headerTitle}>Giấy tờ tùy thân</AppText>

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
        {isLoading ? (
          <AppText style={{ textAlign: 'center', marginTop: 20 }}>Đang tải...</AppText>
        ) : !kycData ? (
          <View style={{ alignItems: 'center', marginTop: 40 }}>
            <MaterialCommunityIcons name="card-account-details-outline" size={64} color="#94A3B8" />
            <AppText style={{ fontSize: 18, fontWeight: '600', marginTop: 16, marginBottom: 8 }}>Chưa định danh</AppText>
            <AppText style={{ textAlign: 'center', color: '#64748B', marginBottom: 24 }}>Tài khoản của bạn chưa được định danh. Vui lòng cập nhật giấy tờ tùy thân để sử dụng đầy đủ các tính năng.</AppText>
            <TouchableOpacity 
              style={{ backgroundColor: '#700F43', paddingHorizontal: 24, paddingVertical: 12, borderRadius: 24 }}
              onPress={() => navigation.navigate('EKyc')}
            >
              <AppText style={{ color: '#FFFFFF', fontWeight: '600' }}>Bắt đầu định danh</AppText>
            </TouchableOpacity>
          </View>
        ) : (
          <>
            {/* CCCD CARD MOCKUP WITH LOTUS PINK GRADIENT ACCENT */}
            <View style={styles.cardWrapper}>
              <LinearGradient
                colors={['#700F43', '#D2519D', '#E4ACB2']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.cccdCard}
              >
                {/* Top Row: Quốc hiệu + Chip icon */}
                <View style={styles.cardTopRow}>
                  <View>
                    <AppText style={styles.cardCountry}>CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM</AppText>
                    <AppText style={styles.cardDocType}>CĂN CƯỚC CÔNG DÂN GẮN CHIP</AppText>
                  </View>
                  <MaterialCommunityIcons name="integrated-circuit-chip" size={32} color="#FEF08A" />
                </View>

                {/* Middle Row: CCCD Number with Eye Toggle */}
                <View style={styles.idNumberRow}>
                  <AppText style={styles.idNumberLabel}>Số / No.: </AppText>
                  <AppText style={styles.idNumberValue}>
                    {showIdNumber ? kycData.idCardNumber : kycData.idCardNumber.substring(0, 4) + ' •••• ' + kycData.idCardNumber.slice(-4)}
                  </AppText>
                  <TouchableOpacity
                    onPress={() => setShowIdNumber(!showIdNumber)}
                    style={{ marginLeft: 8 }}
                    hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                  >
                    <Ionicons
                      name={showIdNumber ? "eye-off-outline" : "eye-outline"}
                      size={18}
                      color="#FFFFFF"
                    />
                  </TouchableOpacity>
                </View>

                {/* Full Name */}
                <View style={styles.infoField}>
                  <AppText style={styles.fieldLabel}>Họ và tên / Full name</AppText>
                  <AppText style={styles.fieldValueBold}>{kycData.fullName}</AppText>
                </View>

                {/* Bottom Details (DOB, Gender, Expiry) */}
                <View style={styles.cardBottomRow}>
                  <View>
                    <AppText style={styles.fieldLabel}>Ngày sinh / DOB</AppText>
                    <AppText style={styles.fieldValue}>{kycData.dob}</AppText>
                  </View>

                  <View>
                    <AppText style={styles.fieldLabel}>Giới tính / Sex</AppText>
                    <AppText style={styles.fieldValue}>N/A</AppText>
                  </View>

                  <View>
                    <AppText style={styles.fieldLabel}>Trạng thái</AppText>
                    <AppText style={styles.fieldValue}>{kycData.status}</AppText>
                  </View>
                </View>
              </LinearGradient>
            </View>

            {/* VERIFICATION BADGE */}
            <View style={styles.verifiedBanner}>
              <MaterialCommunityIcons name="check-decagram" size={24} color="#10B981" />
              <View style={{ flex: 1 }}>
                <AppText style={styles.verifiedBannerTitle}>Đã xác thực CCCD thành công</AppText>
                <AppText style={styles.verifiedBannerSub}>Dữ liệu định danh đã được lưu trên hệ thống</AppText>
              </View>
            </View>

        {/* DETAILED INFORMATION CARD */}
        <View style={styles.detailsCard}>
          <AppText style={styles.sectionHeading}>Thông tin chi tiết</AppText>

          <View style={styles.detailRow}>
            <AppText style={styles.detailLabel}>Loại giấy tờ</AppText>
            <AppText style={styles.detailValue}>Thẻ Căn cước công dân gắn chip</AppText>
          </View>
          <View style={styles.divider} />

          <View style={styles.detailRow}>
            <AppText style={styles.detailLabel}>Ngày cấp</AppText>
            <AppText style={styles.detailValue}>20/04/2022</AppText>
          </View>
          <View style={styles.divider} />

          <View style={styles.detailRow}>
            <AppText style={styles.detailLabel}>Nơi cấp</AppText>
            <AppText style={styles.detailValue}>Cục CSQLHC về TTXH</AppText>
          </View>
          <View style={styles.divider} />

          <View style={styles.detailRow}>
            <AppText style={styles.detailLabel}>Nơi thường trú</AppText>
            <AppText style={styles.detailValue}>TP. Hồ Chí Minh, Việt Nam</AppText>
          </View>
        </View>

        {/* UPDATE BUTTON */}
        <TouchableOpacity
          style={styles.updateBtn}
          activeOpacity={0.9}
          onPress={handleUpdateDocument}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <MaterialCommunityIcons name="cellphone-nfc" size={20} color="#FFFFFF" style={{ marginRight: 8 }} />
          <AppText style={styles.updateBtnText}>Cập nhật giấy tờ mới (Quét NFC)</AppText>
        </TouchableOpacity>
        </>
        )}
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
  cardWrapper: {
    borderRadius: 20,
    overflow: 'hidden',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.25,
    shadowRadius: 12,
    elevation: 6,
    marginBottom: 16,
  },
  cccdCard: {
    padding: 18,
    minHeight: 200,
    justifyContent: 'space-between',
  },
  cardTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  cardCountry: {
    fontSize: 11,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.3,
  },
  cardDocType: {
    fontSize: 12,
    fontWeight: '900',
    color: '#FEF08A',
    marginTop: 2,
  },
  idNumberRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 10,
  },
  idNumberLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.85)',
  },
  idNumberValue: {
    fontSize: 18,
    fontWeight: '900',
    color: '#FFFFFF',
    letterSpacing: 0.8,
  },
  infoField: {
    marginBottom: 8,
  },
  fieldLabel: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.75)',
  },
  fieldValueBold: {
    fontSize: 16,
    fontWeight: '900',
    color: '#FFFFFF',
    marginTop: 1,
  },
  cardBottomRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.2)',
    paddingTop: 8,
  },
  fieldValue: {
    fontSize: 13,
    fontWeight: '800',
    color: '#FFFFFF',
    marginTop: 1,
  },
  verifiedBanner: {
    backgroundColor: '#F0FDF4',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#DCFCE7',
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  verifiedBannerTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#15803D',
  },
  verifiedBannerSub: {
    fontSize: 12,
    color: '#166534',
    marginTop: 2,
  },
  detailsCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginBottom: 20,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  sectionHeading: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 10,
  },
  detailLabel: {
    fontSize: 13.5,
    color: '#64748B',
    fontWeight: '600',
  },
  detailValue: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
    flex: 1,
    textAlign: 'right',
  },
  divider: {
    height: 1,
    backgroundColor: '#F1F5F9',
  },
  updateBtn: {
    height: 50,
    borderRadius: 25,
    overflow: 'hidden',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 6,
    elevation: 4,
  },
  updateBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
