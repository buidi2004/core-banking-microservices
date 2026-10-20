import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

enum NfcScanState { idle, scanning, success, error }

class NfcReaderScreen extends StatefulWidget {
  const NfcReaderScreen({super.key});

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen>
    with SingleTickerProviderStateMixin {
  NfcScanState _state = NfcScanState.idle;
  double _scanProgress = 0.0;
  Timer? _progressTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startNfcReading() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state = NfcScanState.scanning;
      _scanProgress = 0.0;
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;
      setState(() {
        _scanProgress += 0.03;
        if (_scanProgress >= 1.0) {
          _scanProgress = 1.0;
          timer.cancel();
          _state = NfcScanState.success;
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _resetReading() {
    HapticFeedback.lightImpact();
    setState(() {
      _state = NfcScanState.idle;
      _scanProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B17),
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bottomBarCyan.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      _buildDecisionBanner(),
                      const SizedBox(height: 20),
                      _buildNfcRadarArea(),
                      const SizedBox(height: 24),
                      if (_state == NfcScanState.success) ...[
                        _buildExtractedDataCard(),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildStepsGuidanceCard(),
                        const SizedBox(height: 20),
                        _buildTroubleshootingCard(),
                        const SizedBox(height: 24),
                      ],
                      _buildActionBottom(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030B17).withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác thực Chip CCCD (NFC)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Quyết định 2345/QĐ-NHNN',
                  style: TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen, size: 14),
                SizedBox(width: 4),
                Text('C06 BCA', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.7),
            const Color(0xFF0F2B48).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.shield_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt buộc đối soát sinh trắc học',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Theo QĐ 2345/QĐ-NHNN, giao dịch chuyển khoản trên 10.000.000 đ/lần hoặc trên 20.000.000 đ/ngày bắt buộc phải xác thực khuôn mặt trùng khớp với dữ liệu gốc trong chip CCCD đã được Bộ Công An cấp.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcRadarArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _state == NfcScanState.success
              ? AppColors.emeraldGreen.withValues(alpha: 0.5)
              : AppColors.bottomBarCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _state == NfcScanState.scanning
                  ? 1.0 + (_pulseController.value * 0.12)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer waves
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _state == NfcScanState.success
                              ? AppColors.emeraldGreen.withValues(alpha: 0.25)
                              : AppColors.bottomBarCyan.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _state == NfcScanState.success
                              ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                              : AppColors.bottomBarCyan.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                    ),
                    // Center button / icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _state == NfcScanState.success
                              ? [AppColors.emeraldGreen, const Color(0xFF047857)]
                              : [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_state == NfcScanState.success
                                    ? AppColors.emeraldGreen
                                    : AppColors.bottomBarCyan)
                                .withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _state == NfcScanState.success
                            ? CupertinoIcons.checkmark_alt
                            : CupertinoIcons.radiowaves_right,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _state == NfcScanState.idle
                ? 'Sẵn sàng đọc thẻ CCCD'
                : _state == NfcScanState.scanning
                    ? 'Đang đọc thẻ CCCD... Giữ yên thiết bị'
                    : 'Xác thực chip CCCD thành công!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _state == NfcScanState.idle
                ? 'Áp sát mặt sau CCCD (phần có gắn chip) vào vị trí cụm camera'
                : _state == NfcScanState.scanning
                    ? 'Đang truyền nhận dữ liệu chuẩn ICAO 9303 bảo mật'
                    : 'Dữ liệu khớp 100% với Trung tâm C06 Bộ Công An',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          if (_state == NfcScanState.scanning) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _scanProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.bottomBarCyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_scanProgress * 100).toInt()}%',
              style: const TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsGuidanceCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.list_bullet, color: AppColors.bottomBarCyan, size: 20),
                SizedBox(width: 10),
                Text(
                  'Hướng dẫn quét thẻ chuẩn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepRow(
              step: '1',
              title: 'Chuẩn bị CCCD gắn chip vật lý',
              subtitle: 'Đảm bảo thẻ sạch sẽ, chip không bị xước hoặc mòn tiếp điểm.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              step: '2',
              title: 'Áp chặt vào lưng điện thoại',
              subtitle: 'iPhone: Đặt đầu thẻ chạm vào mép trên cạnh camera.\nAndroid: Đặt thẻ ở giữa lưng máy.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              step: '3',
              title: 'Giữ cố định trong 3 - 5 giây',
              subtitle: 'Không di chuyển thẻ hoặc mở app khác trong khi máy đang quét NFC.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.bottomBarCyan,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.lightbulb_fill, color: AppColors.accentGold, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gợi ý: Hãy tháo ốp lưng dày hoặc ốp lưng có vòng kim loại (MagSafe) để sóng NFC bắt tín hiệu nhạy và ổn định nhất.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDataCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Dữ liệu Chip Đã Xác Thực',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('HỢP LỆ', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDataRow('Họ và tên:', 'NGUYỄN VĂN AN'),
            _buildDataRow('Số định danh (CCCD):', '079204001234'),
            _buildDataRow('Ngày sinh:', '15/08/2004'),
            _buildDataRow('Giới tính:', 'Nam'),
            _buildDataRow('Quốc tịch:', 'Việt Nam'),
            _buildDataRow('Nơi thường trú:', 'Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh'),
            _buildDataRow('Ngày cấp:', '10/05/2021'),
            _buildDataRow('Có giá trị đến:', '15/08/2044'),
            _buildDataRow('Chữ ký số Bộ Công An:', 'C06-BCA-VALIDATED'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBottom() {
    if (_state == NfcScanState.idle) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _startNfcReading,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.radiowaves_right, size: 20),
              SizedBox(width: 8),
              Text(
                'Bắt đầu đọc thẻ NFC',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    } else if (_state == NfcScanState.scanning) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white60,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _resetReading,
          child: const Text('Hủy bỏ quá trình đọc', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật sinh trắc học thẻ CCCD gắn chip vào hệ thống!'),
                    backgroundColor: AppColors.emeraldGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.pop();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_alt, size: 20),
                  SizedBox(width: 8),
                  Text('Xác nhận & Cập nhật Hồ Sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetReading,
            child: const Text('Quét lại thẻ khác', style: TextStyle(color: AppColors.bottomBarCyan)),
          ),
        ],
      );
    }
  }
}
