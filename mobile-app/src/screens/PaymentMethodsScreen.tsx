import React from 'react';
import { View, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing, Opacity } from '../theme';
import { Typography } from '../theme';
import { StatusChip } from '../components/StatusChip';
import { AppText } from '../components/typography/AppText';

interface PaymentMethodsScreenProps {
  navigation: any;
}

const mockCards = [
  { id: '1', type: 'visa' as const, last4: '8888', expiry: '12/26', current: true },
  { id: '2', type: 'mastercard' as const, last4: '1234', expiry: '06/25', current: false },
];

export default function PaymentMethodsScreen({ navigation }: PaymentMethodsScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Phương thức thanh toán</AppText>
        <TouchableOpacity>
          <AppText style={styles.addBtn}>+ Thêm</AppText>
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Current card display */}
        <LinearGradient
          colors={[Colors.primary, Colors.heroGradMid]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.cardDisplay}
        >
          <View style={styles.cardHeader}>
            <AppText variant="headingSm" style={styles.cardType}>VISA</AppText>
              <AppIcon name="wifi" size="md" color={Colors.white} />
          </View>
          <AppText variant="headingSm" style={styles.cardNumber}>**** **** **** 8888</AppText>
          <View style={styles.cardFooter}>
            <View>
              <AppText variant="captionXs" style={styles.cardLabel}>Chủ thẻ</AppText>
              <AppText style={styles.cardName}>NGUYEN VAN A</AppText>
            </View>
            <View>
              <AppText variant="captionXs" style={styles.cardLabel}>Hết hạn</AppText>
              <AppText style={styles.cardExpiry}>12/26</AppText>
            </View>
          </View>
        </LinearGradient>

        {/* Card list */}
        <AppText style={styles.sectionTitle}>Thẻ đã lưu</AppText>
        <View style={styles.cardList}>
          {mockCards.map((card) => (
            <View key={card.id} style={styles.cardItem}>
              <View style={styles.cardItemLeft}>
                <View style={styles.cardIconBg}>
                  <AppIcon
                    name={card.type === 'visa' ? 'card' : 'card-outline'}
                    size="sm"
                    color={Colors.primary}
                  />
                </View>
                <View>
                  <AppText style={styles.cardItemName}>
                    {card.type === 'visa' ? 'Visa' : 'Mastercard'} ****{card.last4}
                  </AppText>
                  <AppText style={styles.cardItemExpiry}>Hết hạn: {card.expiry}</AppText>
                </View>
              </View>
              {card.current && <StatusChip text="Mặc định" type="success" size="sm" />}
            </View>
          ))}
        </View>

        {/* Other payment methods */}
        <AppText style={styles.sectionTitle}>Phương thức khác</AppText>
        <View style={styles.methodsList}>
          {[
            { icon: 'wallet-outline', label: 'Ví E-Wallet', value: '5.500.000đ' },
            { icon: 'bank-outline', label: 'Tài khoản ngân hàng', value: '3 tài khoản' },
            { icon: 'cash-outline', label: 'Tiền mặt tại ATM', value: 'Có sẵn' },
          ].map((method, i) => (
            <TouchableOpacity key={i} style={styles.methodItem}>
              <View style={styles.methodIcon}>
                  <AppIcon name={method.icon as any} size="sm" color={Colors.primary} />
              </View>
              <AppText style={styles.methodLabel}>{method.label}</AppText>
              <AppText style={styles.methodValue}>{method.value}</AppText>
            </TouchableOpacity>
          ))}
        </View>
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
  addBtn: {
    
    color: Colors.primary,
    },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  cardDisplay: {
    borderRadius: Radius.lg,
    padding: Spacing.xl,
    minHeight: 180,
    justifyContent: 'space-between',
    ...Shadows.hero,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  cardType: {
    color: Colors.white,
    letterSpacing: 1,
  },
  chipIcon: {
    opacity: Opacity.muted,
  },
  cardNumber: {
    color: Colors.white,
    letterSpacing: 2,
    textAlign: 'center',
    marginVertical: Spacing.lg,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  cardLabel: {
    color: Colors.glassStrong,
    textTransform: 'uppercase',
  },
  cardName: {
    
    color: Colors.white,
    marginTop: 4,
  },
  cardExpiry: {
    
    color: Colors.white,
    marginTop: 4,
  },
  sectionTitle: {
    
    color: Colors.textPrimary,
    marginTop: Spacing.xl,
    marginBottom: Spacing.sm,
  },
  cardList: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  cardItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
  },
  cardItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.md,
  },
  cardIconBg: {
    width: 40,
    height: 40,
    borderRadius: Radius.sm,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cardItemName: {
    
    color: Colors.textPrimary,
  },
  cardItemExpiry: {
    
    color: Colors.textSecondary,
    marginTop: 2,
  },
  methodsList: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    marginTop: Spacing.sm,
    ...Shadows.card,
  },
  methodItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
    gap: Spacing.md,
  },
  methodIcon: {
    width: 36,
    height: 36,
    borderRadius: Radius.xs,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  methodLabel: {
    flex: 1,
    
    color: Colors.textPrimary,
  },
  methodValue: {
    
    color: Colors.textSecondary,
  },
});
