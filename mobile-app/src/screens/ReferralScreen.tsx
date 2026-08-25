import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  StatusBar,
  Dimensions,
  Share,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

const { width } = Dimensions.get('window');

const REFERRAL_HISTORY = [
  { id: '1', name: 'NGUYEN THI DIEM', phone: '0988***123', reward: '+50,000 đ', date: '24/08/2026', status: 'Thành công' },
  { id: '2', name: 'HUA MINH HOANG', phone: '0839***823', reward: '+50,000 đ', date: '22/08/2026', status: 'Thành công' },
  { id: '3', name: 'TRAN VAN NAM', phone: '0912***456', reward: '+50,000 đ', date: '18/08/2026', status: 'Thành công' },
];

export default function ReferralScreen({ navigation }: { navigation: any }) {
  const referralCode = 'MB0923158725';
  const [inputFriendCode, setInputFriendCode] = useState('');

  const handleShare = async () => {
    try {
      await Share.share({
        message: `Mở tài khoản MBBank nhận ngay 50.000đ và tài khoản số đẹp miễn phí! Nhập mã giới thiệu: ${referralCode} hoặc tải App MBBank tại: https://mbbank.com.vn/app`,
      });
    } catch (error) {
      console.log(error);
    }
  };

  const handleApplyCode = () => {
    if (!inputFriendCode.trim()) {
      Alert.alert('Lỗi', 'Vui lòng nhập mã giới thiệu');
      return;
    }
    Alert.alert('Thành công', `Đã áp dụng mã giới thiệu "${inputFriendCode}" thành công! Quà tặng 50.000đ sẽ được chuyển vào tài khoản.`);
    setInputFriendCode('');
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

        <AppText style={styles.headerTitle}>Giới thiệu bạn bè</AppText>

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
        {/* HERO BANNER */}
        <View style={styles.heroCard}>
          <LinearGradient
            colors={['#700F43', '#D2519D', '#E4ACB2']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.heroGradient}
          >
            <View style={styles.giftIconWrap}>
              <Ionicons name="gift" size={32} color="#FEF08A" />
            </View>

            <AppText style={styles.heroTitle}>Giới thiệu bạn - Nhận 50.000đ</AppText>
            <AppText style={styles.heroSub}>
              Nhận ngay 50.000đ tiền mặt không giới hạn cho mỗi lượt giới thiệu bạn bè mở tài khoản MBBank thành công!
            </AppText>

            {/* MY REFERRAL CODE PILL */}
            <View style={styles.codePillBox}>
              <View>
                <AppText style={styles.codeLabel}>Mã giới thiệu của bạn:</AppText>
                <AppText style={styles.codeValue}>{referralCode}</AppText>
              </View>

              <TouchableOpacity
                style={styles.copyBtn}
                activeOpacity={0.8}
                onPress={() => Alert.alert('Đã sao chép', `Đã sao chép mã ${referralCode}`)}
              >
                <Ionicons name="copy-outline" size={16} color="#700F43" style={{ marginRight: 4 }} />
                <AppText style={styles.copyBtnText}>Sao chép</AppText>
              </TouchableOpacity>
            </View>
          </LinearGradient>
        </View>

        {/* STATS OVERVIEW */}
        <View style={styles.statsCard}>
          <View style={styles.statCol}>
            <AppText style={styles.statNumber}>1,250,000 đ</AppText>
            <AppText style={styles.statLabel}>Tổng thưởng tích lũy</AppText>
          </View>

          <View style={styles.statDivider} />

          <View style={styles.statCol}>
            <AppText style={styles.statNumber}>25</AppText>
            <AppText style={styles.statLabel}>Bạn bè đã giới thiệu</AppText>
          </View>
        </View>

        {/* APPLY FRIEND CODE */}
        <View style={styles.applyCard}>
          <AppText style={styles.cardTitle}>Nhập mã giới thiệu từ bạn bè</AppText>
          <View style={styles.inputRow}>
            <TextInput
              style={styles.textInput}
              placeholder="Nhập mã giới thiệu người khác"
              placeholderTextColor="#94A3B8"
              value={inputFriendCode}
              onChangeText={setInputFriendCode}
              autoCapitalize="characters"
            />
            <TouchableOpacity
              style={styles.applyBtn}
              activeOpacity={0.8}
              onPress={handleApplyCode}
            >
              <AppText style={styles.applyBtnText}>Áp dụng</AppText>
            </TouchableOpacity>
          </View>
        </View>

        {/* REFERRAL HISTORY */}
        <View style={styles.historyCard}>
          <AppText style={styles.cardTitle}>Lịch sử nhận thưởng gần đây</AppText>

          {REFERRAL_HISTORY.map((item, index) => (
            <View key={item.id}>
              <View style={styles.historyRow}>
                <View style={styles.historyIconCircle}>
                  <Ionicons name="gift-outline" size={20} color="#D2519D" />
                </View>

                <View style={{ flex: 1 }}>
                  <AppText style={styles.historyName}>{item.name}</AppText>
                  <AppText style={styles.historySub}>{item.phone} • {item.date}</AppText>
                </View>

                <View style={{ alignItems: 'flex-end' }}>
                  <AppText style={styles.historyReward}>{item.reward}</AppText>
                  <AppText style={styles.historyStatus}>{item.status}</AppText>
                </View>
              </View>

              {index < REFERRAL_HISTORY.length - 1 && <View style={styles.divider} />}
            </View>
          ))}
        </View>
      </ScrollView>

      {/* BOTTOM SHARE BUTTON */}
      <View style={styles.bottomFooter}>
        <TouchableOpacity
          style={styles.shareBtn}
          activeOpacity={0.9}
          onPress={handleShare}
        >
          <LinearGradient
            colors={['#D2519D', '#700F43']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={StyleSheet.absoluteFill}
          />
          <Ionicons name="share-social" size={20} color="#FFFFFF" style={{ marginRight: 8 }} />
          <AppText style={styles.shareBtnText}>Chia sẻ liên kết giới thiệu</AppText>
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
    paddingBottom: 110,
  },
  heroCard: {
    borderRadius: 20,
    overflow: 'hidden',
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 5,
    marginBottom: 16,
  },
  heroGradient: {
    padding: 20,
    alignItems: 'center',
  },
  giftIconWrap: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  heroTitle: {
    fontSize: 20,
    fontWeight: '900',
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: 6,
  },
  heroSub: {
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.9)',
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 18,
    paddingHorizontal: 8,
  },
  codePillBox: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  codeLabel: {
    fontSize: 11.5,
    color: '#64748B',
    fontWeight: '600',
  },
  codeValue: {
    fontSize: 18,
    fontWeight: '900',
    color: '#700F43',
    letterSpacing: 0.5,
  },
  copyBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FDF2F8',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  copyBtnText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#700F43',
  },
  statsCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  statCol: {
    flex: 1,
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 18,
    fontWeight: '900',
    color: '#700F43',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '600',
  },
  statDivider: {
    width: 1,
    height: 36,
    backgroundColor: '#F1F5F9',
  },
  applyCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginBottom: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  textInput: {
    flex: 1,
    height: 44,
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingHorizontal: 12,
    fontSize: 14,
    fontWeight: '700',
    color: '#0F172A',
  },
  applyBtn: {
    height: 44,
    paddingHorizontal: 16,
    backgroundColor: '#700F43',
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  applyBtnText: {
    color: '#FFFFFF',
    fontSize: 13.5,
    fontWeight: '800',
  },
  historyCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginBottom: 16,
    shadowColor: '#700F43',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  historyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    gap: 12,
  },
  historyIconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  historyName: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  historySub: {
    fontSize: 12,
    color: '#64748B',
  },
  historyReward: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#15803D',
    marginBottom: 2,
  },
  historyStatus: {
    fontSize: 11,
    fontWeight: '700',
    color: '#10B981',
  },
  divider: {
    height: 1,
    backgroundColor: '#F1F5F9',
  },
  bottomFooter: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 24,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  shareBtn: {
    width: '100%',
    height: 48,
    borderRadius: 24,
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
  shareBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
