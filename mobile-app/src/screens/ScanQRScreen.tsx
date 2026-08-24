import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, StatusBar } from 'react-native';
import { AppIcon } from '../components/icons/AppIcon';
import { Colors, Radius, Spacing } from '../theme';

interface ScanQRScreenProps {
  navigation: any;
}

export default function ScanQRScreen({ navigation }: ScanQRScreenProps) {
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={Colors.black} />

      {/* Camera placeholder */}
      <View style={styles.cameraArea}>
          <AppIcon name="camera" size="xxl" color="rgba(255,255,255,0.5)" />
        <Text style={styles.cameraHint}>Đưa máy ảnh vào khung hình QR code</Text>
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
        <Text style={styles.supportLabel}>Hỗ trợ mã:</Text>
        <View style={styles.labelIcons}>
          {['qr-code', 'barcode', 'wallet'].map((icon, i) => (
            <AppIcon key={i} name={icon as any} size="sm" color="rgba(255,255,255,0.7)" />
          ))}
        </View>
      </View>

      {/* Bottom controls */}
      <View style={styles.controls}>
        <TouchableOpacity style={styles.controlBtn}>
            <AppIcon name="qr-code" size="lg" color={Colors.black} />
          <Text style={styles.controlText}>QR của tôi</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlBtn}>
            <AppIcon name="image" size="lg" color={Colors.black} />
          <Text style={styles.controlText}>Chuyển tiền bằng ảnh</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlBtn}>
            <AppIcon name="folder-open" size="lg" color={Colors.black} />
          <Text style={styles.controlText}>Tải ảnh lên</Text>
        </TouchableOpacity>
      </View>

      {/* Top buttons */}
      <View style={styles.topControls}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
            <AppIcon name="arrow-back" size="md" color={Colors.white} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Quét mã QR</Text>
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
    
    color: 'rgba(255,255,255,0.7)',
  },
  scannerFrame: {
    width: 280,
    height: 280,
    position: 'absolute',
    top: '40%',
    left: '50%',
    marginLeft: -140,
    borderWidth: 2,
    borderColor: 'rgba(255,255,255,0.5)',
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
    
    color: 'rgba(255,255,255,0.8)',
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
    fontWeight: '500',
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
    backgroundColor: 'rgba(255,255,255,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    
    fontWeight: '700',
    color: Colors.white,
  },
  flashBtn: {
    width: 40,
    height: 40,
    borderRadius: Radius.md,
    backgroundColor: 'rgba(255,255,255,0.9)',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
