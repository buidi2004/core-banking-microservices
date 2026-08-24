import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Shadows, Spacing } from '../theme';
import { Typography } from '../theme';
import { PrimaryButton } from '../components/PrimaryButton';
import { GlassCard } from '../components/GlassCard';
import { StatusChip } from '../components/StatusChip';

interface RequestTransferScreenProps {
  navigation: any;
}

const mockRequests = [
  { id: '1', from: 'Trần Thị B', amount: '200.000đ', status: 'pending' as const, date: '12/10/2024' },
  { id: '2', from: 'Lê Văn C', amount: '100.000đ', status: 'accepted' as const, date: '11/10/2024' },
  { id: '3', from: 'Phạm Thị D', amount: '50.000đ', status: 'expired' as const, date: '08/10/2024' },
];

export default function RequestTransferScreen({ navigation }: RequestTransferScreenProps) {
  const [showQR, setShowQR] = useState(false);
  const [amount, setAmount] = useState('');
  const [message, setMessage] = useState('');

  if (showQR) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => setShowQR(false)}>
              <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Yêu cầu đã tạo</Text>
          <View style={styles.spacer} />
        </View>

        <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
          {/* QR Card */}
          <GlassCard intensity={40} tint="light">
            <View style={styles.qrContent}>
                <AppIcon name="qr-code" size="huge" color={Colors.textPrimary} />
              <Text style={styles.qrTitle}>Quét mã để nộp tiền</Text>
              <Text style={styles.qrAmount}>{amount || '500.000'} VNĐ</Text>
              {message ? <Text style={styles.qrMessage}>{message}</Text> : null}
            </View>
          </GlassCard>

          {/* Action buttons */}
          <View style={styles.actions}>
            <TouchableOpacity style={styles.actionBtn}>
                <AppIcon name="share-social" size="sm" color={Colors.primary} />
              <Text style={styles.actionText}>Chia sẻ</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionBtn}>
                <AppIcon name="copy" size="sm" color={Colors.primary} />
              <Text style={styles.actionText}>Sao chép link</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Yêu cầu chuyển tiền</Text>
        <View style={styles.spacer} />
      </View>

      <ScrollView showsVerticalScrollIndicator={false} style={styles.scrollView}>
        {/* Create request form */}
        <View style={styles.formCard}>
          <Text style={styles.formTitle}>Tạo yêu cầu mới</Text>

          <View style={styles.field}>
            <Text style={styles.label}>Người gửi</Text>
            <View style={styles.inputWrapper}>
                <AppIcon name="person-outline" size="sm" color={Colors.textSecondary} />
              <Text style={styles.inputPlaceholder}>Chọn người gửi...</Text>
            </View>
          </View>

          <View style={styles.field}>
            <Text style={styles.label}>Số tiền</Text>
            <View style={styles.amountInput}>
              <Text style={styles.currency}>VNĐ</Text>
              <Text style={styles.amount}>{amount || '...'}</Text>
            </View>
          </View>

          <View style={styles.field}>
            <Text style={styles.label}>Lời nhắn (không bắt buộc)</Text>
            <View style={styles.messageInput}>
              <Text style={styles.messagePlaceholder}>Nhập lời nhắn...</Text>
            </View>
          </View>

          <PrimaryButton
            title="Tạo yêu cầu"
            onPress={() => {
              setShowQR(true);
              setAmount(amount);
              setMessage(message);
            }}
          />
        </View>

        {/* Recent requests */}
        <Text style={styles.sectionTitle}>Yêu cầu gần đây</Text>
        <View style={styles.requestsList}>
          {mockRequests.map((req, index) => (
            <View key={req.id} style={[styles.requestItem, index === mockRequests.length - 1 && styles.requestItemLast]}>
              <View style={styles.requestLeft}>
                <View style={styles.requestAvatar}>
                    <AppIcon name="person" size="sm" color={Colors.primary} />
                </View>
                <View style={styles.requestInfo}>
                  <Text style={styles.requestFrom}>{req.from}</Text>
                  <Text style={styles.requestDate}>{req.date}</Text>
                </View>
              </View>
              <View style={styles.requestRight}>
                <Text style={styles.requestAmount}>{req.amount}</Text>
                <StatusChip
                  text={req.status === 'pending' ? 'Chờ' : req.status === 'accepted' ? 'Đã nhận' : 'Hết hạn'}
                  type={req.status === 'accepted' ? 'success' : req.status === 'pending' ? 'warning' : 'danger'}
                  size="sm"
                />
              </View>
            </View>
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
  spacer: {
    width: 40,
  },
  scrollView: {
    flex: 1,
    paddingTop: Spacing.lg,
    paddingHorizontal: Spacing.lg,
  },
  formCard: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    padding: Spacing.lg,
    marginBottom: Spacing.xl,
    ...Shadows.card,
  },
  formTitle: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.md,
  },
  field: {
    marginBottom: Spacing.md,
  },
  label: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
    marginBottom: Spacing.xs,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.bgBase,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    height: 48,
  },
  inputPlaceholder: {
    flex: 1,
    
    color: Colors.textSecondary,
    marginLeft: Spacing.sm,
  },
  amountInput: {
    flexDirection: 'row',
    alignItems: 'baseline',
    backgroundColor: Colors.bgBase,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    height: 48,
  },
  currency: {
    
    fontWeight: '600',
    color: Colors.textSecondary,
  },
  amount: {
    flex: 1,
    
    fontWeight: '700',
    color: Colors.primary,
  },
  messageInput: {
    backgroundColor: Colors.bgBase,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    minHeight: 80,
  },
  messagePlaceholder: {
    
    color: Colors.textSecondary,
  },
  sectionTitle: {
    
    fontWeight: '700',
    color: Colors.textPrimary,
    marginBottom: Spacing.sm,
  },
  requestsList: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.md,
    overflow: 'hidden',
    ...Shadows.card,
  },
  requestItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.primarySoft,
  },
  requestItemLast: {
    borderBottomWidth: 0,
  },
  requestLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  requestAvatar: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    backgroundColor: Colors.primarySoft,
    justifyContent: 'center',
    alignItems: 'center',
  },
  requestInfo: {
    gap: 4,
  },
  requestFrom: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
  },
  requestDate: {
    
    color: Colors.textSecondary,
  },
  requestRight: {
    alignItems: 'flex-end',
    gap: 4,
  },
  requestAmount: {
    
    fontWeight: '700',
    color: Colors.primary,
  },
  qrContent: {
    alignItems: 'center',
    padding: Spacing.xxl,
  },
  qrTitle: {
    
    fontWeight: '600',
    color: Colors.textPrimary,
    marginTop: Spacing.md,
    marginBottom: Spacing.xs,
  },
  qrAmount: {
    fontSize: Typography.headingLg.fontSize,
    fontWeight: '800',
    color: Colors.primary,
  },
  qrMessage: {
    
    color: Colors.textSecondary,
    marginTop: Spacing.sm,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: Spacing.xxl,
  },
  actionBtn: {
    alignItems: 'center',
    gap: Spacing.xs,
  },
  actionText: {
    
    color: Colors.primary,
    fontWeight: '600',
  },
});
