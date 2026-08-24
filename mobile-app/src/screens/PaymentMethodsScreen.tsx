import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { StatusChip } from '../components/StatusChip';

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
        <Text style={styles.headerTitle}>Phương thức thanh toán</Text>
        <TouchableOpacity>
          <Text style={styles.addBtn}>+ Thêm</Text>
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
            <Text style={styles.cardType}>VISA</Text>
              <AppIcon name="wifi" size="md" color={Colors.white} />
          </View>
          <Text style={styles.cardNumber}>**** **** **** 8888</Text>
          <View style={styles.cardFooter}>
            <View>
              <Text style={styles.cardLabel}>Chủ thẻ</Text>
              <Text style={styles.cardName}>NGUYEN VAN A</Text>
            </View>
            <View>
              <Text style={styles.cardLabel}>Hết hạn</Text>
              <Text style={styles.cardExpiry}>12/26</Text>
            </View>
          </View>
        </LinearGradient>

        {/* Card list */}
        <Text style={styles.sectionTitle}>Thẻ đã lưu</Text>
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
                  <Text style={styles.cardItemName}>
                    {card.type === 'visa' ? 'Visa' : 'Mastercard'} ****{card.last4}
                  </Text>
                  <Text style={styles.cardItemExpiry}>Hết hạn: {card.expiry}</Text>
                </View>
              </View>
              {card.current && <StatusChip text="Mặc định" type="success" size="sm" />}
            </View>
          ))}
        </View>

        {/* Other payment methods */}
        <Text style={styles.sectionTitle}>Phương thức khác</Text>
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
              <Text style={styles.methodLabel}>{method.label}</Text>
              <Text style={styles.methodValue}>{method.value}</Text>
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
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  addBtn: {
    
    color: Colors.primary,
    fontWeight: '600',
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
    fontSize: Typography.headingSm.fontSize,
    fontWeight: '800',
    color: Colors.white,
    letterSpacing: 1,
  },
  chipIcon: {
    opacity: 0.8,
  },
  cardNumber: {
    fontSize: Typography.headingSm.fontSize,
    color: Colors.white,
    fontWeight: '600',
    letterSpacing: 2,
    textAlign: 'center',
    marginVertical: Spacing.lg,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  cardLabel: {
    fontSize: Typography.captionXs.fontSize,
    color: 'rgba(255,255,255,0.7)',
    textTransform: 'uppercase',
  },
  cardName: {
    
    color: Colors.white,
    fontWeight: '600',
    marginTop: 4,
  },
  cardExpiry: {
    
    color: Colors.white,
    fontWeight: '600',
    marginTop: 4,
  },
  sectionTitle: {
    
    fontWeight: '700',
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
    
    fontWeight: '600',
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
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  methodValue: {
    
    color: Colors.textSecondary,
  },
});
