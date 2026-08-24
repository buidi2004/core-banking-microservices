import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView, Image } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { StatusChip } from '../components/StatusChip';
import { EmptyState } from '../components/EmptyState';
import { SearchBar } from '../components/SearchBar';
import { AppText } from '../components/typography/AppText';

interface PromotionsScreenProps {
  navigation: any;
}

const mockPromos = [
  { id: '1', title: 'Giảm 20% tại Highlands', expiry: '31/10/2024', isNew: true, image: 'https://picsum.photos/200' },
  { id: '2', title: 'Hoàn 10% khi thanh toán hóa đơn', expiry: '15/11/2024', isNew: false, image: 'https://picsum.photos/201' },
  { id: '3', title: 'Tặng voucher 50k nạp 500k', expiry: '30/10/2024', isNew: true, image: 'https://picsum.photos/202' },
  { id: '4', title: 'Giảm giá GrabFood', expiry: '20/10/2024', isNew: false, image: 'https://picsum.photos/203' },
];

export default function PromotionsScreen({ navigation }: PromotionsScreenProps) {
  const [activeTab, setActiveTab] = useState('all');
  const tabs = ['Tất cả', 'Chuyển tiền', 'Hóa đơn', 'Nạp tiền'];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Ưu đãi</AppText>
        <TouchableOpacity>
            <AppIcon name="search" size="sm" color={Colors.textPrimary} />
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Banner carousel */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.bannerScroll}>
          {mockPromos.slice(0, 2).map((promo) => (
            <TouchableOpacity key={promo.id} style={styles.bannerCard}>
              <Image source={{ uri: promo.image }} style={styles.bannerImage} />
              <View style={styles.bannerOverlay}>
                <AppText style={styles.bannerTitle}>{promo.title}</AppText>
              </View>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Filter tabs */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.tabsScroll}>
          {tabs.map((tab) => (
            <TouchableOpacity
              key={tab}
              style={[styles.tab, activeTab === tab.toLowerCase() && styles.tabActive]}
              onPress={() => setActiveTab(tab.toLowerCase())}
            >
              <AppText style={[styles.tabText, activeTab === tab.toLowerCase() && styles.tabTextActive]}>
                {tab}
              </AppText>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Promo grid */}
        {mockPromos.length === 0 ? (
          <EmptyState
            icon="gift-outline"
            title="Không có ưu đãi nào"
            subtitle="Hãy kiểm tra lại sau nhé!"
          />
        ) : (
          <View style={styles.grid}>
            {mockPromos.map((promo) => (
              <TouchableOpacity key={promo.id} style={styles.card}>
                {promo.isNew && (
                  <View style={styles.newBadge}>
                    <AppText style={styles.newBadgeText}>Mới</AppText>
                  </View>
                )}
                <Image source={{ uri: promo.image }} style={styles.cardImage} />
                <View style={styles.cardContent}>
                  <AppText style={styles.cardTitle}>{promo.title}</AppText>
                  <AppText style={styles.cardExpiry}>Hết hạn: {promo.expiry}</AppText>
                </View>
              </TouchableOpacity>
            ))}
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.bgBase,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
  },
  headerTitle: {
    
    color: Colors.textPrimary,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.md,
  },
  bannerScroll: {
    marginBottom: Spacing.md,
  },
  bannerCard: {
    width: 320,
    height: 140,
    borderRadius: Radius.md,
    overflow: 'hidden',
    marginHorizontal: Spacing.lg,
    ...Shadows.card,
  },
  bannerImage: {
    width: '100%',
    height: '100%',
  },
  bannerOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: Spacing.md,
    backgroundColor: Colors.overlayDark,
  },
  bannerTitle: {
    
    color: Colors.white,
  },
  tabsScroll: {
    paddingHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
  tab: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    marginRight: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: Colors.surface,
  },
  tabActive: {
    backgroundColor: Colors.primary,
  },
  tabText: {
    
    color: Colors.textSecondary,
  },
  tabTextActive: {
    color: Colors.white,
    },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: Spacing.lg,
    gap: Spacing.md,
  },
  card: {
    width: '48%',
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  newBadge: {
    position: 'absolute',
    top: Spacing.sm,
    left: Spacing.sm,
    backgroundColor: Colors.primary,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
    zIndex: 1,
  },
  newBadgeText: {
    
    color: Colors.white,
  },
  cardImage: {
    width: '100%',
    height: 100,
  },
  cardContent: {
    padding: Spacing.sm,
  },
  cardTitle: {
    
    color: Colors.textPrimary,
    marginBottom: 4,
  },
  cardExpiry: {
    
    color: Colors.textSecondary,
  },
});
