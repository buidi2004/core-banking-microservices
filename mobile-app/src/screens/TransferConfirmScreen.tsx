import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, Modal } from 'react-native';
import { BlurView } from 'expo-blur';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { StatusChip } from '../components/StatusChip';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

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

          <Text style={styles.title}>Xác nhận chuyển tiền</Text>
          <Text style={styles.subtitle}>Vui lòng kiểm tra thông tin trước khi xác nhận</Text>

          {/* Summary */}
          <View style={styles.summaryCard}>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Người nhận</Text>
              <Text style={styles.summaryValue}>Nguyễn Văn A</Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Số điện thoại</Text>
              <Text style={styles.summaryValue}>0901 234 567</Text>
            </View>
            <View style={styles.divider} />
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Số tiền</Text>
              <Text style={styles.amountValue}>500.000 VNĐ</Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Phí giao dịch</Text>
              <Text style={styles.feeValue}>Miễn phí</Text>
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
    fontSize: Typography.headingSm.fontSize,
    fontWeight: '800',
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
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  amountValue: {
    
    fontWeight: '800',
    color: Colors.primary,
  },
  feeValue: {
    
    fontWeight: '600',
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
