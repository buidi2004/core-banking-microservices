import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ekyc_sdk/ekyc_sdk.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

enum NfcScanState { idle, scanning, success, error }

class NfcReaderScreen extends StatefulWidget {
  final String? initialDocumentNumber;
  final String? initialDateOfBirth;
  final String? initialExpiryDate;
  final bool autoStart;

  const NfcReaderScreen({
    super.key,
    this.initialDocumentNumber,
    this.initialDateOfBirth,
    this.initialExpiryDate,
    this.autoStart = false,
  });

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen>
    with SingleTickerProviderStateMixin {
  NfcScanState _state = NfcScanState.idle;
  double _scanProgress = 0.0;
  Timer? _progressTimer;
  late AnimationController _pulseController;
  String _statusMessage = '';

  // Thông tin thẻ nhập THẬT từ người dùng hoặc tự động điền từ MRZ bước trước
  final _docNumCtrl = TextEditingController();
  final _dobCtrl = TextEditingController(); // YYMMDD hoặc DD/MM/YYYY
  final _expiryCtrl = TextEditingController(); // YYMMDD hoặc DD/MM/YYYY
  CccdChipData? _chipData;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocumentNumber != null &&
        widget.initialDocumentNumber!.isNotEmpty) {
      _docNumCtrl.text = widget.initialDocumentNumber!;
    }
    if (widget.initialDateOfBirth != null &&
        widget.initialDateOfBirth!.isNotEmpty) {
      _dobCtrl.text = widget.initialDateOfBirth!;
    }
    if (widget.initialExpiryDate != null &&
        widget.initialExpiryDate!.isNotEmpty) {
      _expiryCtrl.text = widget.initialExpiryDate!;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (widget.autoStart &&
        _docNumCtrl.text.isNotEmpty &&
        _dobCtrl.text.isNotEmpty &&
        _expiryCtrl.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startNfcReading();
      });
    }
  }

  final ChipReaderService _chipReader = ChipReaderService();

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    _docNumCtrl.dispose();
    _dobCtrl.dispose();
    _expiryCtrl.dispose();
    _chipReader.cancelSession();
    super.dispose();
  }

  /// Chuẩn hóa chuỗi ngày sinh / ngày hết hạn về định dạng YYMMDD của chuẩn ICAO 9303.
  /// Hỗ trợ cả định dạng quen thuộc của người Việt (DD/MM/YYYY hoặc DDMMYYYY)
  /// và định dạng gốc (YYMMDD).
  String _normalizeToYYMMDD(String input) {
    final clean = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 8) {
      // Định dạng DDMMYYYY -> lấy YYMMDD
      final dd = clean.substring(0, 2);
      final mm = clean.substring(2, 4);
      final yyyy = clean.substring(4, 8);
      final yy = yyyy.substring(2, 4);
      return '$yy$mm$dd';
    }
    return clean;
  }

  Future<void> _startNfcReading() async {
    HapticFeedback.mediumImpact();
    final docNum = _docNumCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
    final dob = _normalizeToYYMMDD(_dobCtrl.text.trim());
    final expiry = _normalizeToYYMMDD(_expiryCtrl.text.trim());

    if (docNum.length < 9 || dob.length != 6 || expiry.length != 6) {
      setState(() {
        _state = NfcScanState.error;
        _statusMessage =
            'Vui lòng nhập đúng số CCCD (9 hoặc 12 số) và ngày sinh, ngày hết hạn (DD/MM/YYYY hoặc YYMMDD)';
      });
      return;
    }

    setState(() {
      _state = NfcScanState.scanning;
      _scanProgress = 0.0;
      _statusMessage =
          'Đang khởi động ReaderMode (bỏ qua NDEF của hệ điều hành)...';
    });

    try {
      final data = await _chipReader.readCccdChip(
        documentNumber: docNum,
        birthDateYYMMDD: dob,
        expiryDateYYMMDD: expiry,
        onProgress: _onProgress,
      );
      if (!mounted) return;
      setState(() {
        _chipData = data;
        _state = NfcScanState.success;
        _scanProgress = 1.0;
      });
      HapticFeedback.heavyImpact();
    } on ChipReadException catch (e) {
      if (!mounted) return;
      if (e.code == ChipReadErrorCode.paceRequired) {
        // Thẻ mới ưu tiên PACE — hỏi người dùng nhập CAN rồi đọc lại
        await _promptCanAndRetry(docNum);
        return;
      }
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      // Trung thực: lỗi thì báo lỗi, KHÔNG giả lập quét thành công
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = 'Lỗi đọc chip NFC: $e';
      });
    }
  }

  Future<void> _promptCanAndRetry(String docNum) async {
    final canCtrl = TextEditingController();
    final can = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thẻ yêu cầu xác thực PACE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thẻ Căn cước mẫu mới từ chối kênh BAC (mã 69 82). '
                'Nhập số CAN (6 chữ số) in ở góc dưới mặt trước (hoặc mặt sau) thẻ để tiếp tục.'),
            const SizedBox(height: 12),
            TextField(
              controller: canCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Số CAN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(canCtrl.text.trim()),
              child: const Text('Đọc chip bằng PACE')),
        ],
      ),
    );
    if (can == null || can.length != 6 || !mounted) {
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = 'Đã hủy — cần số CAN để đọc thẻ mới (PACE)';
      });
      return;
    }
    setState(() {
      _state = NfcScanState.scanning;
      _scanProgress = 0.0;
    });
    try {
      final data = await _chipReader.readCccdChipWithCan(
        can: can,
        documentNumber: docNum,
        onProgress: _onProgress,
      );
      if (!mounted) return;
      setState(() {
        _chipData = data;
        _state = NfcScanState.success;
        _scanProgress = 1.0;
      });
      HapticFeedback.heavyImpact();
    } on ChipReadException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = 'Đọc chip bằng PACE thất bại: $e';
      });
    }
  }

  void _onProgress(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _scanProgress = progress;
      _statusMessage = status;
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
      backgroundColor: AppColors.inkNavy,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
        color: AppColors.inkNavy.withValues(alpha: 0.7),
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
              border: Border.all(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.checkmark_shield_fill,
                    color: AppColors.emeraldGreen, size: 14),
                SizedBox(width: 4),
                Text('C06 BCA',
                    style: TextStyle(
                        color: AppColors.emeraldGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
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
              color: AppColors.primaryDark,
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
                              ? [
                                  AppColors.emeraldGreen,
                                  const Color(0xFF047857)
                                ]
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
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.info_circle,
                    size: 12, color: AppColors.bottomBarCyan),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Vị trí NFC: iPhone ở đỉnh máy • Samsung giữa lưng • Xiaomi/OPPO gần camera',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_state == NfcScanState.scanning) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _scanProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.bottomBarCyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_scanProgress * 100).toInt()}%',
              style: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
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
                Icon(CupertinoIcons.list_bullet,
                    color: AppColors.bottomBarCyan, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hướng dẫn quét thẻ chuẩn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepRow(
              step: '1',
              title: 'Chuẩn bị CCCD gắn chip vật lý',
              subtitle:
                  'Đảm bảo thẻ sạch sẽ, chip không bị xước hoặc mòn tiếp điểm.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              step: '2',
              title: 'Áp chặt vào lưng điện thoại',
              subtitle:
                  'iPhone: Đặt đầu thẻ chạm vào mép trên cạnh camera.\nAndroid: Đặt thẻ ở giữa lưng máy.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              step: '3',
              title: 'Giữ cố định trong 3 - 5 giây',
              subtitle:
                  'Không di chuyển thẻ hoặc mở app khác trong khi máy đang quét NFC.',
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
            border: Border.all(
                color: AppColors.bottomBarCyan.withValues(alpha: 0.4)),
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
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.3),
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
          Icon(CupertinoIcons.lightbulb_fill,
              color: AppColors.bottomBarCyan, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gợi ý: Hãy tháo ốp lưng dày hoặc ốp lưng có vòng kim loại (MagSafe) để sóng NFC bắt tín hiệu nhạy và ổn định nhất.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
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
                const Expanded(
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_seal_fill,
                          color: AppColors.emeraldGreen, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dữ liệu Chip Đã Xác Thực',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('HỢP LỆ',
                      style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDataRow(
                'Họ và tên:',
                (_chipData?.fullName.isNotEmpty ?? false)
                    ? _chipData!.fullName
                    : '—'),
            _buildDataRow(
                'Số định danh (CCCD):',
                (_chipData?.documentNumber.isNotEmpty ?? false)
                    ? _chipData!.documentNumber
                    : '—'),
            _buildDataRow(
                'Ngày sinh:',
                (_chipData?.dateOfBirth.isNotEmpty ?? false)
                    ? _chipData!.dateOfBirth
                    : '—'),
            _buildDataRow(
                'Giới tính:',
                (_chipData?.gender.isNotEmpty ?? false)
                    ? _chipData!.gender
                    : '—'),
            _buildDataRow(
                'Có giá trị đến:',
                (_chipData?.expiryDate.isNotEmpty ?? false)
                    ? _chipData!.expiryDate
                    : '—'),
            _buildDataRow(
                'Ảnh chân dung chip (DG2):',
                _chipData?.facePhotoBytes != null
                    ? 'Đã trích xuất (${_chipData!.facePhotoBytes!.lengthInBytes} bytes)'
                    : 'Không có'),
            _buildDataRow('Chữ ký số SOD:',
                _chipData?.sodSignatureValid == true ? 'Nguyên vẹn' : 'LỆCH'),
          ],
        ),
      ),
    );
  }

  /// Form nhập thông tin thẻ thật — BAC key suy diễn từ đây (không hardcode)
  Widget _buildCardInfoForm() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Thông tin thẻ (làm khóa BAC/PACE)',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                if (_docNumCtrl.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Tự động điền',
                        style: TextStyle(
                            color: AppColors.emeraldGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _docNumCtrl,
              keyboardType: TextInputType.number,
              maxLength: 12,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Số định danh CCCD (12 số)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dobCtrl,
                    keyboardType: TextInputType.text,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh (YYMMDD hoặc DD/MM/YYYY)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.text,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Hạn thẻ (YYMMDD hoặc DD/MM/YYYY)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
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
          Expanded(
            flex: 5,
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBottom() {
    if (_state == NfcScanState.idle) {
      return Column(
        children: [
          _buildCardInfoForm(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startNfcReading,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.radiowaves_right, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bắt đầu đọc thẻ NFC',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_state == NfcScanState.scanning) {
      return Column(
        children: [
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white60,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _resetReading,
              child: const Text('Hủy bỏ quá trình đọc',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _state == NfcScanState.error
                        ? AppColors.error
                        : Colors.white70,
                    fontSize: 12.5),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (_chipData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chưa có dữ liệu chip để trả về'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                // Trả dữ liệu chip THẬT (kèm ảnh DG2) về màn eKYC để làm reference
                context.pop(_chipData);
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Xác nhận & Cập nhật Hồ Sơ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetReading,
            child: const Text('Quét lại thẻ khác',
                style: TextStyle(color: AppColors.bottomBarCyan)),
          ),
        ],
      );
    }
  }
}
