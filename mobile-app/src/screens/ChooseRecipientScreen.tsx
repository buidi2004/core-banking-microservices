import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Image,
  Dimensions,
  StatusBar,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, MaterialCommunityIcons, FontAwesome5 } from '@expo/vector-icons';
import { AppText } from '../components/typography/AppText';
import { Colors } from '../theme';

const { width } = Dimensions.get('window');

export default function ChooseRecipientScreen({ navigation }: any) {
  const [keyword, setKeyword] = useState('');

  // 5 Danh mục chuyển tiền ngang với Icon chuẩn từ Expo Vector Icons
  const TRANSFER_METHODS = [
    { id: '1', title: 'Số\ntài khoản', icon: <MaterialCommunityIcons name="bank-outline" size={26} color="#D2519D" /> },
    { id: '2', title: 'Số\nđiện thoại', icon: <Ionicons name="call-outline" size={25} color="#D2519D" /> },
    { id: '3', title: 'Số thẻ', icon: <Ionicons name="card-outline" size={26} color="#D2519D" /> },
    { id: '4', title: 'Mẫu\nchuyển', icon: <Ionicons name="receipt-outline" size={25} color="#D2519D" /> },
    { id: '5', title: 'Thẻ\nquốc tế', icon: <MaterialCommunityIcons name="earth" size={26} color="#D2519D" /> },
  ];

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <StatusBar barStyle="dark-content" backgroundColor="#FDF2F8" />

      {/* TOP BACKGROUND SOFT LOTUS PINK GRADIENT AURA */}
      <LinearGradient
        colors={['#FDF2F8', '#FCE7F3', '#F8FAFC']}
        start={{ x: 0.2, y: 0 }}
        end={{ x: 0.8, y: 0.4 }}
        style={styles.topGradientAura}
      />

      {/* 1. TOP NAVIGATION BAR */}
      <View style={styles.navBar}>
        <TouchableOpacity
          style={styles.navBtn}
          activeOpacity={0.7}
          onPress={() => navigation.goBack()}
        >
          <Ionicons name="chevron-back" size={24} color="#700F43" />
        </TouchableOpacity>

        <View style={styles.navRightActions}>
          <TouchableOpacity
            style={styles.navBtn}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('Notifications')}
          >
            <Ionicons name="notifications-outline" size={22} color="#700F43" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.navBtn}
            activeOpacity={0.7}
            onPress={() => navigation.navigate('Home')}
          >
            <Ionicons name="home-outline" size={22} color="#700F43" />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* 2. PAGE TITLE */}
        <AppText style={styles.pageHeading}>Siêu chuyển tiền</AppText>

        {/* 3. HORIZONTAL METHODS CAROUSEL */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.methodsScroll}
        >
          {TRANSFER_METHODS.map((method) => (
            <TouchableOpacity
              key={method.id}
              style={styles.methodCard}
              activeOpacity={0.8}
              onPress={() => navigation.navigate('EnterAmount', { method: method.title })}
            >
              <View style={styles.methodIconCircle}>
                {method.icon}
              </View>
              <AppText style={styles.methodTitle}>{method.title}</AppText>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* 4. MBAI SMART TRANSFER CARD */}
        <View style={styles.mbaiCard}>
          {/* Top-Left MBAI Pill Badge */}
          <View style={styles.mbaiBadge}>
            <Ionicons name="sparkles" size={11} color="#FFFFFF" />
            <AppText style={styles.mbaiBadgeText}>MBAI</AppText>
          </View>

          {/* Input & QR Scanner Viewfinder Row */}
          <View style={styles.mbaiInputRow}>
            <TextInput
              style={styles.mbaiTextInput}
              placeholder="Nhập số điện thoại cần chuyển"
              placeholderTextColor="#94A3B8"
              value={keyword}
              onChangeText={setKeyword}
              keyboardType="numeric"
              returnKeyType="done"
              onSubmitEditing={() => {
                if (keyword.trim()) {
                  navigation.navigate('EnterAmount', { phone: keyword.trim() });
                }
              }}
            />

            <TouchableOpacity
              style={styles.qrScanBtn}
              activeOpacity={0.7}
              onPress={() => navigation.navigate('QR')}
            >
              <MaterialCommunityIcons name="qrcode-scan" size={22} color="#D2519D" />
            </TouchableOpacity>
          </View>

          {/* Divider */}
          <View style={styles.cardDivider} />

          {/* 3 Action Buttons (Chụp ảnh | Tải ảnh | Dán) */}
          <View style={styles.mbaiActionsRow}>
            {/* Chụp ảnh */}
            <TouchableOpacity
              style={styles.actionCol}
              activeOpacity={0.7}
              onPress={() => navigation.navigate('QR')}
            >
              <View style={styles.actionIconWrap}>
                <Ionicons name="sparkles" size={11} color="#D2519D" />
                <Ionicons name="camera-outline" size={19} color="#D2519D" style={{ marginLeft: 3 }} />
              </View>
              <AppText style={styles.actionBtnLabel}>Chụp ảnh</AppText>
            </TouchableOpacity>

            <View style={styles.verticalDivider} />

            {/* Tải ảnh */}
            <TouchableOpacity
              style={styles.actionCol}
              activeOpacity={0.7}
              onPress={() => navigation.navigate('QR')}
            >
              <View style={styles.actionIconWrap}>
                <Ionicons name="sparkles" size={11} color="#D2519D" />
                <Ionicons name="images-outline" size={19} color="#D2519D" style={{ marginLeft: 3 }} />
              </View>
              <AppText style={styles.actionBtnLabel}>Tải ảnh</AppText>
            </TouchableOpacity>

            <View style={styles.verticalDivider} />

            {/* Dán */}
            <TouchableOpacity
              style={styles.actionCol}
              activeOpacity={0.7}
              onPress={() => setKeyword('0923158725')}
            >
              <View style={styles.actionIconWrap}>
                <Ionicons name="sparkles" size={11} color="#D2519D" />
                <Ionicons name="clipboard-outline" size={19} color="#D2519D" style={{ marginLeft: 3 }} />
              </View>
              <AppText style={styles.actionBtnLabel}>Dán</AppText>
            </TouchableOpacity>
          </View>
        </View>

        {/* 5. 2 QUICK ACCESS CARDS (Gần đây | Ví điện tử & đối tác) */}
        <View style={styles.twoCardsRow}>
          {/* Card Trái: Gần đây */}
          <TouchableOpacity
            style={styles.quickCard}
            activeOpacity={0.8}
            onPress={() => navigation.navigate('EnterAmount')}
          >
            <View style={styles.quickCardHeader}>
              <AppText style={styles.quickCardTitle}>Gần đây</AppText>
              <Ionicons name="chevron-forward" size={16} color="#D2519D" />
            </View>

            <View style={styles.quickCardLogosRow}>
              {/* MB Star mini */}
              <View style={[styles.miniBrandLogo, { backgroundColor: '#E11D48' }]}>
                <AppText style={{ color: '#FFFFFF', fontSize: 11, fontWeight: '900' }}>★</AppText>
              </View>

              {/* MoMo mini */}
              <View style={[styles.miniBrandLogo, { backgroundColor: '#D82D8B' }]}>
                <AppText style={{ color: '#FFFFFF', fontSize: 8, fontWeight: '900', textAlign: 'center' }}>mo{'\n'}mo</AppText>
              </View>

              {/* Badge +8 */}
              <View style={styles.plusCountBadge}>
                <AppText style={styles.plusCountText}>+8</AppText>
              </View>
            </View>
          </TouchableOpacity>

          {/* Card Phải: Ví điện tử & đối tác */}
          <TouchableOpacity
            style={styles.quickCard}
            activeOpacity={0.8}
            onPress={() => navigation.navigate('PaymentMethods')}
          >
            <View style={styles.quickCardHeader}>
              <AppText style={styles.quickCardTitle} numberOfLines={1}>Ví điện tử & đối tác</AppText>
              <Ionicons name="chevron-forward" size={16} color="#D2519D" />
            </View>

            <View style={styles.quickCardLogosRow}>
              {/* Viettel Money Red Circle */}
              <View style={[styles.miniBrandLogo, { backgroundColor: '#EF4444', borderRadius: 12 }]}>
                <AppText style={{ color: '#FFFFFF', fontSize: 10 }}>📱</AppText>
              </View>

              {/* ZaloPay Green Text */}
              <View style={[styles.miniBrandLogo, { backgroundColor: '#ECFDF5' }]}>
                <AppText style={{ color: '#059669', fontSize: 7.5, fontWeight: '900', textAlign: 'center' }}>Zalo{'\n'}pay</AppText>
              </View>

              {/* MoMo mini */}
              <View style={[styles.miniBrandLogo, { backgroundColor: '#D82D8B' }]}>
                <AppText style={{ color: '#FFFFFF', fontSize: 8, fontWeight: '900', textAlign: 'center' }}>mo{'\n'}mo</AppText>
              </View>

              {/* Badge +3 */}
              <View style={styles.plusCountBadge}>
                <AppText style={styles.plusCountText}>+3</AppText>
              </View>
            </View>
          </TouchableOpacity>
        </View>

        {/* 6. MONEY CHAT SECTION */}
        <View style={styles.moneyChatHeader}>
          <AppText style={styles.moneyChatTitle}>Money Chat</AppText>

          <View style={styles.moneyChatActions}>
            <TouchableOpacity style={styles.searchCircleBtn} activeOpacity={0.7}>
              <Ionicons name="search-outline" size={18} color="#700F43" />
            </TouchableOpacity>

            <TouchableOpacity style={styles.newChatPillBtn} activeOpacity={0.8}>
              <AppText style={styles.newChatPillText}>+ Chat mới</AppText>
            </TouchableOpacity>
          </View>
        </View>

        {/* 7. RECENT MONEY CHAT ITEM (BUI VAN DI) */}
        <TouchableOpacity
          style={styles.chatUserCard}
          activeOpacity={0.8}
          onPress={() => navigation.navigate('EnterAmount', { name: 'BUI VAN DI', phone: '0923158725' })}
        >
          <Image
            source={{ uri: 'https://i.pravatar.cc/150?img=11' }}
            style={styles.chatUserAvatar}
          />
          <View style={styles.chatUserInfo}>
            <AppText style={styles.chatUserName}>BUI VAN DI</AppText>
            <AppText style={styles.chatUserSub}>
              0923158725 | <AppText style={{ color: '#64748B' }}>Tài khoản thanh toán</AppText>
            </AppText>
          </View>
        </TouchableOpacity>

        {/* 8. EMPTY SAVED RECIPIENTS SECTION (OFFICIAL VECTOR ICONS) */}
        <View style={styles.emptyContainer}>
          <View style={styles.emptyIconHalo}>
            <MaterialCommunityIcons name="account-search-outline" size={48} color="#D2519D" />
          </View>
          <AppText style={styles.emptyTitle}>Chưa có người nhận đã lưu</AppText>
          <AppText style={styles.emptySub}>
            Thực hiện chuyển tiền để lưu người nhận và dễ dàng quản lý các giao dịch lần sau.
          </AppText>
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
  topGradientAura: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 280,
  },
  navBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  navBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  navRightActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  scrollContent: {
    paddingHorizontal: 16,
    paddingBottom: 40,
  },
  pageHeading: {
    fontSize: 26,
    fontWeight: '800',
    color: '#700F43',
    letterSpacing: -0.5,
    marginTop: 4,
    marginBottom: 20,
  },
  methodsScroll: {
    paddingRight: 10,
    gap: 16,
    marginBottom: 20,
  },
  methodCard: {
    alignItems: 'center',
    width: 68,
  },
  methodIconCircle: {
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  methodTitle: {
    fontSize: 12.5,
    fontWeight: '600',
    color: '#1E293B',
    textAlign: 'center',
    lineHeight: 16,
  },
  mbaiCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: '#D2519D',
    paddingTop: 12,
    paddingBottom: 12,
    paddingHorizontal: 14,
    marginBottom: 16,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 10,
    elevation: 4,
  },
  mbaiBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: '#D2519D',
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 3,
    gap: 3,
    marginBottom: 8,
  },
  mbaiBadgeText: {
    color: '#FFFFFF',
    fontSize: 10.5,
    fontWeight: '900',
    letterSpacing: 0.2,
  },
  mbaiInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  mbaiTextInput: {
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
    color: '#1E293B',
    paddingVertical: 4,
  },
  qrScanBtn: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: '#FDF2F8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cardDivider: {
    height: 1,
    backgroundColor: '#FCE7F3',
    marginVertical: 12,
  },
  mbaiActionsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  actionCol: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  actionIconWrap: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  actionBtnLabel: {
    fontSize: 13.5,
    fontWeight: '700',
    color: '#700F43',
  },
  verticalDivider: {
    width: 1,
    height: 20,
    backgroundColor: '#FCE7F3',
  },
  twoCardsRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 24,
  },
  quickCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  quickCardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  quickCardTitle: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#700F43',
    flex: 1,
  },
  quickCardLogosRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  miniBrandLogo: {
    width: 26,
    height: 26,
    borderRadius: 6,
    justifyContent: 'center',
    alignItems: 'center',
  },
  plusCountBadge: {
    backgroundColor: '#FDF2F8',
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  plusCountText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#D2519D',
  },
  moneyChatHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  moneyChatTitle: {
    fontSize: 19,
    fontWeight: '800',
    color: '#700F43',
  },
  moneyChatActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  searchCircleBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    justifyContent: 'center',
    alignItems: 'center',
  },
  newChatPillBtn: {
    backgroundColor: '#D2519D',
    borderRadius: 18,
    paddingHorizontal: 14,
    paddingVertical: 8,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  newChatPillText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  chatUserCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 32,
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 5,
    elevation: 2,
    borderWidth: 1,
    borderColor: '#FCE7F3',
  },
  chatUserAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
  },
  chatUserInfo: {
    flex: 1,
  },
  chatUserName: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
  },
  chatUserSub: {
    fontSize: 12.5,
    color: '#0F172A',
    fontWeight: '600',
    marginTop: 3,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 20,
  },
  emptyIconHalo: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#FDF2F8',
    borderWidth: 1,
    borderColor: '#FCE7F3',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#D2519D',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 2,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#700F43',
    marginTop: 14,
    textAlign: 'center',
  },
  emptySub: {
    fontSize: 13,
    color: '#64748B',
    textAlign: 'center',
    marginTop: 6,
    paddingHorizontal: 20,
    lineHeight: 18,
  },
});
