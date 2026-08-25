import React from 'react';
import { View, StyleSheet, TouchableOpacity, Modal } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { StatusChip } from '../components/StatusChip';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';
import { AppText } from '../components/typography/AppText';

interface TransferConfirmScreenProps {
  navigation: any;
}

export default function TransferConfirmScreen({ navigation }: TransferConfirmScreenProps) {
  const [isVisible, setIsVisible] = React.useState(true);

  if (!isVisible) {
    return null;
  }

  return (
    <Modal
      visible={isVisible}
      transparent
      animationType="slide"
      onRequestClose={() => setIsVisible(false)}
    >
      <BlurView intensity={40} tint="light" style={styles.backdrop} />
      <View style={styles.container}>
        {/* Drag handle */}
        <View style={styles.dragHandle} />

        {/* Sheet content - only top 2 corners rounded */}
        <View style={styles.sheetContent}>
          <TouchableOpacity style={styles.closeBtn} onPress={() => setIsVisible(false)}>
              <AppIcon name="close" size="md" color={Colors.textSecondary} />
          </TouchableOpacity>

          <AppText variant="headingSm" style={styles.title}>Xác nhận chuyển tiền</AppText>
          <AppText style={styles.subtitle}>Vui lòng kiểm tra thông tin trước khi xác nhận</AppText>

          {/* Summary */}
          <View style={styles.summaryCard}>
            <View style={styles.summaryRow}>
              <AppText style={styles.summaryLabel}>Người nhận</AppText>
              <AppText style={styles.summaryValue}>Nguyễn Văn A</AppText>
            </View>
            <View style={styles.summaryRow}>
              <AppText style={styles.summaryLabel}>Số điện thoại</AppText>
              <AppText style={styles.summaryValue}>0901 234 567</AppText>
            </View>
            <View style={styles.divider} />
            <View style={styles.summaryRow}>
              <AppText style={styles.summaryLabel}>Số tiền</AppText>
              <AppText style={styles.amountValue}>500.000 VNĐ</AppText>
            </View>
            <View style={styles.summaryRow}>
              <AppText style={styles.summaryLabel}>Phí giao dịch</AppText>
              <AppText style={styles.feeValue}>Miễn phí</AppText>
            </View>
          </View>

          {/* Action buttons */}
          <PrimaryButton
            title="Xác nhận chuyển"
            onPress={() => {
              setIsVisible(false);
              navigation.navigate('TransferResult', { success: true });
            }}
          />

          <SecondaryButton
            title="Quay lại"
            onPress={() => setIsVisible(false)}
            style={styles.secondaryBtn}
          />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
  },
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  dragHandle: {
    width: 40,
    height: 4,
    backgroundColor: Colors.dragHandleBg,
    borderRadius: Radius.none,
    alignSelf: 'center',
    marginTop: Spacing.md,
    marginBottom: Spacing.sm,
  },
  sheetContent: {
    backgroundColor: Colors.surface,
    borderTopLeftRadius: Radius.lg,
    borderTopRightRadius: Radius.lg,
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
    paddingBottom: Spacing.xxl,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.md,
    ...Shadows.hero,
  },
  closeBtn: {
    alignSelf: 'flex-end',
    padding: Spacing.xs,
  },
  title: {
    color: Colors.textPrimary,
    textAlign: 'center',
    marginBottom: Spacing.xs,
  },
  subtitle: {
    
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: Spacing.xl,
  },
  summaryCard: {
    backgroundColor: Colors.bgBase,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    marginBottom: Spacing.xl,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
  },
  summaryLabel: {
    
    color: Colors.textSecondary,
  },
  summaryValue: {
    
    color: Colors.textPrimary,
  },
  amountValue: {
    
    color: Colors.primary,
  },
  feeValue: {
    
    color: Colors.success,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.primarySoft,
    marginVertical: Spacing.sm,
  },
  secondaryBtn: {
    marginTop: Spacing.md,
  },
});
