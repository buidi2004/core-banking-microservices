import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { GroupedListRow } from '../components/GroupedListRow';
import { BankCardRow } from '../components/BankCardRow';
import { SecondaryButton } from '../components/SecondaryButton';
import { EmptyState } from '../components/EmptyState';

interface BankCardsScreenProps {
  navigation: any;
}

const mockCards = [
  { id: '1', bankName: 'Vietcombank', accountNumber: '****8888', isDefault: true },
  { id: '2', bankName: 'Techcombank', accountNumber: '****1234', isDefault: false },
  { id: '3', bankName: 'MB Bank', accountNumber: '****5678', isDefault: false },
];

export default function BankCardsScreen({ navigation }: BankCardsScreenProps) {
  const cards = mockCards;

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Ngân hàng & thẻ liên kết</Text>
        <View style={styles.spacer} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {cards.length === 0 ? (
          <EmptyState
            icon="card-outline"
            title="Chưa có ngân hàng nào"
            subtitle="Liên kết ngân hàng để nạp/rút tiền dễ dàng hơn"
            actionLabel="Liên kết ngay"
          />
        ) : (
          <>
            <View style={styles.listContainer}>
              {cards.map((card, index) => (
                <BankCardRow
                  key={card.id}
                  bankName={card.bankName}
                  accountNumber={card.accountNumber}
                  isDefault={card.isDefault}
                  onPress={() => navigation.navigate('BankCardDetail', { card })}
                />
              ))}
            </View>
            <View style={styles.actionsContainer}>
              <SecondaryButton
                title="Liên kết ngân hàng/thẻ mới"
                onPress={() => navigation.navigate('AddBankCard')}
                style={styles.addBtn}
              />
            </View>
          </>
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
    
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  spacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  listContainer: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  actionsContainer: {
    marginTop: Spacing.xl,
  },
  addBtn: {
    marginTop: 0,
  },
});
