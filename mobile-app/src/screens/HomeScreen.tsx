import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
  SafeAreaView,
  StatusBar,
} from 'react-native';
import { Ionicons, FontAwesome5, MaterialCommunityIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

export default function HomeScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" translucent backgroundColor="transparent" />
      
      {/* Top Background Gradient */}
      <LinearGradient
        colors={['#FF6B52', '#FF4E50']}
        style={styles.headerGradient}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
      />

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        
        {/* HEADER */}
        <View style={styles.header}>
          <Image
            source={{ uri: 'https://i.pravatar.cc/100' }}
            style={styles.avatar}
          />
          <Text style={styles.headerTitle}>Trang chủ</Text>
          <TouchableOpacity style={styles.bellIcon}>
            <Ionicons name="notifications-outline" size={28} color="#FFF" />
            <View style={styles.notificationDot} />
          </TouchableOpacity>
        </View>

        {/* WALLET CARD (Glassmorphism) */}
        <View style={styles.walletCardContainer}>
          <LinearGradient
            colors={['rgba(255,255,255,0.3)', 'rgba(255,255,255,0.1)']}
            style={styles.walletCard}
          >
            <View style={styles.walletHeader}>
              <Text style={styles.walletLabel}>Ví của bạn</Text>
              <Ionicons name="eye-off-outline" size={20} color="#FFF" />
            </View>
            <Text style={styles.balanceText}>5.500.000 VNĐ</Text>

            <View style={styles.walletActions}>
              <TouchableOpacity style={styles.actionItem}>
                <View style={styles.actionIconContainer}>
                  <Ionicons name="wallet-outline" size={24} color="#FF4E50" />
                </View>
                <Text style={styles.actionText}>Nạp tiền</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.actionItem}>
                <View style={styles.actionIconContainer}>
                  <Ionicons name="cash-outline" size={24} color="#FF4E50" />
                </View>
                <Text style={styles.actionText}>Rút tiền</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.actionItem}>
                <View style={styles.actionIconContainer}>
                  <Ionicons name="swap-horizontal-outline" size={24} color="#FF4E50" />
                </View>
                <Text style={styles.actionText}>Chuyển tiền</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.actionItem}>
                <View style={styles.actionIconContainer}>
                  <Ionicons name="qr-code-outline" size={24} color="#FF4E50" />
                </View>
                <Text style={styles.actionText}>Quét QR</Text>
              </TouchableOpacity>
            </View>
          </LinearGradient>
        </View>

        {/* SERVICES GRID */}
        <View style={styles.servicesGrid}>
          <TouchableOpacity style={styles.serviceItem}>
            <View style={styles.serviceIconShadow}>
              <MaterialCommunityIcons name="cellphone" size={32} color="#FF4E50" />
            </View>
            <Text style={styles.serviceText}>Điện thoại</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.serviceItem}>
            <View style={styles.serviceIconShadow}>
              <Ionicons name="receipt-outline" size={32} color="#FF4E50" />
            </View>
            <Text style={styles.serviceText}>Hóa đơn</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.serviceItem}>
            <View style={styles.serviceIconShadow}>
              <FontAwesome5 name="piggy-bank" size={28} color="#FF4E50" />
            </View>
            <Text style={styles.serviceText}>Tiết kiệm</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.serviceItem}>
            <View style={styles.serviceIconShadow}>
              <Ionicons name="trending-up" size={32} color="#FF4E50" />
            </View>
            <Text style={styles.serviceText}>Đầu tư</Text>
          </TouchableOpacity>
        </View>

        {/* PROMO BANNER */}
        <LinearGradient
          colors={['#FF6B52', '#FF4E50']}
          style={styles.promoBanner}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.promoContent}>
            <Text style={styles.promoSubtitle}>Ưu đãi tháng 7!</Text>
            <Text style={styles.promoTitle}>Giảm 20% khi thanh toán tại Highlands Coffee</Text>
            <TouchableOpacity style={styles.promoButton}>
              <Text style={styles.promoButtonText}>Xem ngay</Text>
            </TouchableOpacity>
          </View>
          {/* Decorative circles */}
          <View style={styles.promoCircle1} />
          <View style={styles.promoCircle2} />
        </LinearGradient>

        {/* TRANSACTION HISTORY */}
        <View style={styles.historySection}>
          <View style={styles.historyHeader}>
            <Text style={styles.sectionTitle}>Lịch sử giao dịch</Text>
            <TouchableOpacity>
              <Text style={styles.viewAllText}>View all</Text>
            </TouchableOpacity>
          </View>
          
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.historyList}>
            {/* Starbucks */}
            <View style={styles.historyCard}>
              <View style={[styles.historyIconBg, { backgroundColor: '#FFEDF0' }]}>
                <Ionicons name="cafe" size={24} color="#FF4E50" />
              </View>
              <Text style={styles.historyName}>Starbucks</Text>
              <Text style={styles.historyAmount}>-100.000 VNĐ</Text>
              <Text style={styles.historyDate}>12/10/2022</Text>
            </View>
            {/* Grab */}
            <View style={styles.historyCard}>
              <View style={[styles.historyIconBg, { backgroundColor: '#FFEDF0' }]}>
                <Ionicons name="car" size={24} color="#FF4E50" />
              </View>
              <Text style={styles.historyName}>Grab</Text>
              <Text style={styles.historyAmount}>-50.000 VNĐ</Text>
              <Text style={styles.historyDate}>12/10/2022</Text>
            </View>
            {/* Shopee */}
            <View style={styles.historyCard}>
              <View style={[styles.historyIconBg, { backgroundColor: '#FFEDF0' }]}>
                <Ionicons name="bag-handle" size={24} color="#FF4E50" />
              </View>
              <Text style={styles.historyName}>Shopee</Text>
              <Text style={styles.historyAmount}>-200.000 VNĐ</Text>
              <Text style={styles.historyDate}>12/10/2022</Text>
            </View>
          </ScrollView>
        </View>

      </ScrollView>

      {/* BOTTOM NAVIGATION */}
      <View style={styles.bottomNav}>
        <TouchableOpacity style={styles.navItem}>
          <Ionicons name="home" size={24} color="#FF4E50" />
          <Text style={[styles.navText, { color: '#FF4E50' }]}>Trang chủ</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.navItem}>
          <Ionicons name="pricetag-outline" size={24} color="#888" />
          <Text style={styles.navText}>Ưu đãi</Text>
        </TouchableOpacity>
        
        {/* Floating Action Button (QR) */}
        <View style={styles.fabContainer}>
          <TouchableOpacity style={styles.fab}>
            <Ionicons name="qr-code" size={28} color="#FFF" />
          </TouchableOpacity>
          <Text style={styles.fabText}>Quét QR</Text>
        </View>

        <TouchableOpacity style={styles.navItem}>
          <Ionicons name="person-outline" size={24} color="#888" />
          <Text style={styles.navText}>Tài khoản</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.navItem}>
          <Ionicons name="help-circle-outline" size={24} color="#888" />
          <Text style={styles.navText}>Hỗ trợ</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F7F8FA',
  },
  headerGradient: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 300,
    borderBottomLeftRadius: 30,
    borderBottomRightRadius: 30,
  },
  scrollContent: {
    paddingBottom: 100,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 50,
    paddingBottom: 20,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: '#FFF',
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#FFF',
  },
  bellIcon: {
    position: 'relative',
    padding: 5,
  },
  notificationDot: {
    position: 'absolute',
    top: 5,
    right: 5,
    width: 10,
    height: 10,
    backgroundColor: '#FF0000',
    borderRadius: 5,
    borderWidth: 2,
    borderColor: '#FF4E50',
  },
  walletCardContainer: {
    paddingHorizontal: 20,
    marginTop: 10,
  },
  walletCard: {
    borderRadius: 20,
    padding: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.1,
    shadowRadius: 15,
    elevation: 5,
  },
  walletHeader: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 5,
  },
  walletLabel: {
    color: '#FFF',
    fontSize: 16,
    opacity: 0.9,
    marginRight: 8,
  },
  balanceText: {
    color: '#FFF',
    fontSize: 32,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 25,
  },
  walletActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  actionItem: {
    alignItems: 'center',
  },
  actionIconContainer: {
    width: 50,
    height: 50,
    borderRadius: 16,
    backgroundColor: '#FFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 5,
  },
  actionText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '500',
  },
  servicesGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    marginTop: 30,
  },
  serviceItem: {
    alignItems: 'center',
  },
  serviceIconShadow: {
    width: 65,
    height: 65,
    borderRadius: 20,
    backgroundColor: '#FFF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.06,
    shadowRadius: 10,
    elevation: 3,
  },
  serviceText: {
    color: '#333',
    fontSize: 13,
    fontWeight: '500',
  },
  promoBanner: {
    marginHorizontal: 20,
    marginTop: 30,
    borderRadius: 20,
    padding: 20,
    overflow: 'hidden',
    position: 'relative',
  },
  promoContent: {
    width: '70%',
    zIndex: 1,
  },
  promoSubtitle: {
    color: 'rgba(255,255,255,0.9)',
    fontSize: 14,
    marginBottom: 5,
  },
  promoTitle: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    lineHeight: 24,
  },
  promoButton: {
    backgroundColor: '#FFF',
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 20,
    alignSelf: 'flex-start',
  },
  promoButtonText: {
    color: '#FF4E50',
    fontWeight: 'bold',
    fontSize: 14,
  },
  promoCircle1: {
    position: 'absolute',
    right: -30,
    top: -30,
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 20,
    borderColor: 'rgba(255,255,255,0.1)',
  },
  promoCircle2: {
    position: 'absolute',
    right: 30,
    bottom: -40,
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: 'rgba(255,255,255,0.1)',
  },
  historySection: {
    marginTop: 30,
  },
  historyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  viewAllText: {
    color: '#FF4E50',
    fontSize: 14,
    fontWeight: '500',
  },
  historyList: {
    paddingHorizontal: 15,
  },
  historyCard: {
    backgroundColor: '#FFF',
    width: 130,
    padding: 15,
    borderRadius: 20,
    alignItems: 'center',
    marginHorizontal: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 3,
  },
  historyIconBg: {
    width: 50,
    height: 50,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  historyName: {
    color: '#333',
    fontWeight: '600',
    fontSize: 14,
    marginBottom: 4,
  },
  historyAmount: {
    color: '#333',
    fontWeight: '700',
    fontSize: 13,
    marginBottom: 4,
  },
  historyDate: {
    color: '#999',
    fontSize: 12,
  },
  bottomNav: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 80,
    backgroundColor: '#FFF',
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    paddingBottom: 20,
    borderTopWidth: 1,
    borderTopColor: '#F0F0F0',
  },
  navItem: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 60,
  },
  navText: {
    fontSize: 11,
    marginTop: 4,
    color: '#888',
  },
  fabContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: -40,
  },
  fab: {
    width: 65,
    height: 65,
    borderRadius: 35,
    backgroundColor: '#FF4E50',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#FF4E50',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 5,
  },
  fabText: {
    fontSize: 12,
    marginTop: 5,
    color: '#333',
    fontWeight: '500',
  },
});
