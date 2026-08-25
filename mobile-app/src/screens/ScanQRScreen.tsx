import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  StatusBar,
  ScrollView,
  Dimensions,
  Animated,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';
import { WalletApi } from '../services/api';
import { Alert, ActivityIndicator } from 'react-native';

interface ScanQRScreenProps {
  navigation: any;
}

const { width } = Dimensions.get('window');
const SCANNER_SIZE = Math.round(width * 0.88);

export default function ScanQRScreen({ navigation }: ScanQRScreenProps) {
  const [flashlightOn, setFlashlightOn] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const scanAnim = useRef(new Animated.Value(0)).current;

  // Running Laser Scan Beam Effect
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(scanAnim, {
          toValue: 1,
          duration: 2200,
          useNativeDriver: true,
        }),
        Animated.timing(scanAnim, {
          toValue: 0,
          duration: 2200,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [scanAnim]);

  const translateY = scanAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [10, SCANNER_SIZE - 20],
  });

  const handleSimulateScan = async () => {
    if (isScanning) return;
    setIsScanning(true);
    try {
      // Dummy VietQR string for test
      const testQrString = "00020101021238570010A00000072701270006970422011309881234560208QRIBFTTA53037045405500005802VN6304E85C";
      
      // 1. Decode QR
      const decodeRes = await WalletApi.decodeVietQr(testQrString);
      const payload = decodeRes.data;

      // 2. Fetch Recipient Info to get real Name using accountNumber (phone)
      const infoRes = await WalletApi.getRecipientInfo(undefined, payload.accountNumber);
      
      // 3. Navigate
      navigation.navigate('EnterAmount', {
        name: infoRes.data.maskedName,
        phone: payload.accountNumber,
        selectedBank: payload.bankBin,
        recipient: {
          name: infoRes.data.maskedName,
          phone: payload.accountNumber,
          walletId: infoRes.data.walletId
        }
      });

    } catch (e: any) {
      Alert.alert('Lỗi quét mã', e.message || 'Mã QR không hợp lệ hoặc lỗi kết nối.');
    } finally {
      setIsScanning(false);
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0B1329" translucent />

      {/* Deep Dark Space Background with Blueish Vignette */}
      <LinearGradient
        colors={['#0B1329', '#080E1E', '#030712']}
        style={StyleSheet.absoluteFill}
      />

      <SafeAreaView style={styles.safeArea} edges={['top', 'bottom']}>
        {/* 1. TOP HEADER (BACK BUTTON + TITLE + FLASH TOGGLE) */}
        <View style={styles.topHeader}>
          <TouchableOpacity
            style={styles.circleHeaderBtn}
            onPress={() => navigation.goBack()}
            hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
            activeOpacity={0.7}
          >
            <Ionicons name="chevron-back" size={24} color="#FFFFFF" />
          </TouchableOpacity>

          <AppText style={styles.headerTitle}>Quét mã QR</AppText>

          <TouchableOpacity
            style={[styles.circleHeaderBtn, flashlightOn && styles.circleHeaderBtnActive]}
            onPress={() => setFlashlightOn(!flashlightOn)}
            hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
            activeOpacity={0.7}
          >
            <Ionicons
              name={flashlightOn ? "flash" : "flash-outline"}
              size={20}
              color={flashlightOn ? "#F59E0B" : "#FFFFFF"}
            />
          </TouchableOpacity>
        </View>

        <ScrollView
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.scrollContent}
        >
          {/* 2. SCANNER VIEWFINDER BOX WITH LASER BEAM */}
          <View style={styles.scannerWrapper}>
            <TouchableOpacity
              style={styles.scannerBox}
              activeOpacity={0.9}
              onPress={handleSimulateScan}
            >
              {/* Corner Brackets */}
              <View style={[styles.cornerBracket, styles.bracketTopLeft]} />
              <View style={[styles.cornerBracket, styles.bracketTopRight]} />
              <View style={[styles.cornerBracket, styles.bracketBottomLeft]} />
              <View style={[styles.cornerBracket, styles.bracketBottomRight]} />

              {isScanning ? (
                <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
                  <ActivityIndicator size="large" color="#D2519D" />
                  <AppText style={{ color: '#FFFFFF', marginTop: 12 }}>Đang giải mã...</AppText>
                </View>
              ) : (
                /* Animated Laser Beam */
                <Animated.View
                  style={[
                    styles.laserBeamContainer,
                    {
                      transform: [{ translateY }],
                    },
                  ]}
                >
                  <LinearGradient
                    colors={['rgba(210, 81, 157, 0)', '#D2519D', '#F472B6', 'rgba(210, 81, 157, 0)']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 0 }}
                    style={styles.laserBeamLine}
                  />
                </Animated.View>
              )}
            </TouchableOpacity>

            {/* Prompt instruction text under viewfinder */}
            <AppText style={styles.instructionText}>
              Di chuyển camera đến vùng chứa mã QR SenBank / VietQR để quét
            </AppText>
          </View>

          {/* 3. 3 ACTION BUTTONS (QR CỦA TÔI | CHUYỂN TIỀN BẰNG ẢNH | TẢI ẢNH LÊN) */}
          <View style={styles.actionsContainer}>
            {/* Action 1: QR của tôi */}
            <TouchableOpacity
              style={styles.actionCard}
              onPress={() => navigation.navigate('MyQR')}
              activeOpacity={0.8}
            >
              <View style={styles.actionIconWrapper}>
                <MaterialCommunityIcons name="qrcode-scan" size={26} color="#700F43" />
              </View>
              <AppText style={styles.actionCardText}>QR của tôi</AppText>
            </TouchableOpacity>

            {/* Action 2: Chuyển tiền bằng ảnh */}
            <TouchableOpacity
              style={styles.actionCard}
              onPress={() =>
                navigation.navigate('EnterAmount', {
                  name: 'HỨA MINH HOÀNG',
                  phone: '0839888823',
                  selectedBank: 'SenBank (Nội bộ)',
                })
              }
              activeOpacity={0.8}
            >
              <View style={styles.actionIconWrapper}>
                <Ionicons name="camera-outline" size={26} color="#700F43" />
              </View>
              <AppText style={styles.actionCardText}>Chuyển tiền{'\n'}bằng ảnh</AppText>
            </TouchableOpacity>

            {/* Action 3: Tải ảnh lên */}
            <TouchableOpacity
              style={styles.actionCard}
              onPress={() =>
                navigation.navigate('EnterAmount', {
                  name: 'TRẦN VĂN NAM',
                  phone: '0912345678',
                  selectedBank: 'SenBank (Nội bộ)',
                })
              }
              activeOpacity={0.8}
            >
              <View style={styles.actionIconWrapper}>
                <Ionicons name="images-outline" size={26} color="#700F43" />
              </View>
              <AppText style={styles.actionCardText}>Tải ảnh lên</AppText>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0B1329',
  },
  safeArea: {
    flex: 1,
  },
  topHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 16,
  },
  circleHeaderBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255, 255, 255, 0.12)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  circleHeaderBtnActive: {
    backgroundColor: 'rgba(245, 158, 11, 0.25)',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.2,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'space-between',
    paddingBottom: 24,
  },
  scannerWrapper: {
    alignItems: 'center',
    marginTop: 20,
  },
  scannerBox: {
    width: SCANNER_SIZE,
    height: SCANNER_SIZE,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.03)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    position: 'relative',
    overflow: 'hidden',
  },
  cornerBracket: {
    position: 'absolute',
    width: 32,
    height: 32,
    borderColor: '#D2519D',
  },
  bracketTopLeft: {
    top: -1,
    left: -1,
    borderTopWidth: 4,
    borderLeftWidth: 4,
    borderTopLeftRadius: 18,
  },
  bracketTopRight: {
    top: -1,
    right: -1,
    borderTopWidth: 4,
    borderRightWidth: 4,
    borderTopRightRadius: 18,
  },
  bracketBottomLeft: {
    bottom: -1,
    left: -1,
    borderBottomWidth: 4,
    borderLeftWidth: 4,
    borderBottomLeftRadius: 18,
  },
  bracketBottomRight: {
    bottom: -1,
    right: -1,
    borderBottomWidth: 4,
    borderRightWidth: 4,
    borderBottomRightRadius: 18,
  },
  laserBeamContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 4,
    alignItems: 'center',
    justifyContent: 'center',
  },
  laserBeamLine: {
    width: '90%',
    height: 3,
    borderRadius: 2,
    shadowColor: '#F472B6',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.9,
    shadowRadius: 8,
    elevation: 6,
  },
  instructionText: {
    color: '#E2E8F0',
    fontSize: 14,
    fontWeight: '600',
    textAlign: 'center',
    marginTop: 24,
    paddingHorizontal: 30,
    lineHeight: 20,
  },
  actionsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 16,
    paddingHorizontal: 16,
    marginTop: 36,
  },
  actionCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    paddingVertical: 18,
    paddingHorizontal: 8,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 115,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  actionIconWrapper: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  actionCardText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
    textAlign: 'center',
    lineHeight: 16,
  },
});
