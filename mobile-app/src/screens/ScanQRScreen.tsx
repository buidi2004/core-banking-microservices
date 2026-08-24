import React from 'react';
import { View, StyleSheet, TouchableOpacity, SafeAreaView, StatusBar } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';
import { AppText } from '../components/typography/AppText';

interface ScanQRScreenProps {
  navigation: any;
}

export default function ScanQRScreen({ navigation }: ScanQRScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.black} />

      {/* Camera placeholder */}
      <View style={styles.cameraArea}>
          <AppIcon name="camera" size="xxl" color={Colors.glassMedium} />
        <AppText style={styles.cameraHint}>Đưa máy ảnh vào khung hình QR code</AppText>
      </View>

      {/* Scanner frame */}
      <View style={styles.scannerFrame}>
        <View style={[styles.corner, styles.cornerTL]} />
        <View style={[styles.corner, styles.cornerTR]} />
        <View style={[styles.corner, styles.cornerBL]} />
        <View style={[styles.corner, styles.cornerBR]} />
      </View>

      {/* Support labels */}
      <View style={styles.supportLabels}>
        <AppText style={styles.supportLabel}>Hỗ trợ mã:</AppText>
        <View style={styles.labelIcons}>
          {['qr-code', 'barcode', 'wallet'].map((icon, i) => (
            <AppIcon key={i} name={icon as any} size="sm" color={Colors.glassStrong} />
          ))}
        </View>
      </View>

      {/* Bottom controls */}
      <View style={styles.controls}>
        <TouchableOpacity style={styles.controlBtn}>
            <AppIcon name="qr-code" size="lg" color={Colors.black} />
          <AppText style={styles.controlText}>QR của tôi</AppText>
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlBtn}>
            <AppIcon name="image" size="lg" color={Colors.black} />
          <AppText style={styles.controlText}>Chuyển tiền bằng ảnh</AppText>
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlBtn}>
            <AppIcon name="folder-open" size="lg" color={Colors.black} />
          <AppText style={styles.controlText}>Tải ảnh lên</AppText>
        </TouchableOpacity>
      </View>

      {/* Top buttons */}
      <View style={styles.topControls}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.white} />
        </TouchableOpacity>
        <AppText style={styles.headerTitle}>Quét mã QR</AppText>
        <TouchableOpacity style={styles.flashBtn}>
            <AppIcon name="flash" size="md" color={Colors.black} />
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.black,
  },
  cameraArea: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cameraHint: {
    marginTop: Spacing.md,
    
    color: Colors.glassStrong,
  },
  scannerFrame: {
    width: 280,
    height: 280,
    position: 'absolute',
    top: '40%',
    left: '50%',
    marginLeft: -140,
    borderWidth: 2,
    borderColor: Colors.glassMedium,
    borderRadius: Radius.md,
  },
  corner: {
    position: 'absolute',
    width: 30,
    height: 30,
    borderColor: Colors.primary,
    borderWidth: 4,
  },
  cornerTL: { top: 0, left: 0, borderRightWidth: 0, borderBottomWidth: 0 },
  cornerTR: { top: 0, right: 0, borderLeftWidth: 0, borderBottomWidth: 0 },
  cornerBL: { bottom: 0, left: 0, borderRightWidth: 0, borderTopWidth: 0 },
  cornerBR: { bottom: 0, right: 0, borderLeftWidth: 0, borderTopWidth: 0 },
  supportLabels: {
    position: 'absolute',
    top: '58%',
    alignSelf: 'center',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  supportLabel: {
    
    color: Colors.glassHeavy,
  },
  labelIcons: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  controls: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: Spacing.xxl,
    paddingHorizontal: Spacing.lg,
  },
  controlBtn: {
    alignItems: 'center',
    gap: Spacing.xs,
  },
  controlText: {
    
    color: Colors.white,
    },
  topControls: {
    position: 'absolute',
    top: 60,
    left: 0,
    right: 0,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: Spacing.lg,
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    backgroundColor: Colors.glassLight,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    
    color: Colors.white,
  },
  flashBtn: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    backgroundColor: Colors.glassOpaque,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
