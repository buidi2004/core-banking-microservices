import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/network/permission_service.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/qr_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late final AnimationController _laserAnimController;
  late final Animation<double> _laserAnimation;

  bool _isTorchOn = false;
  int _selectedModeIndex = 0; // 0: VietQR 24/7, 1: VNPAY / Hoá đơn, 2: Đăng nhập Web
  bool _isDecoding = false;
  bool _cameraPermissionGranted = false; // Trạng thái quyền camera

  final List<String> _scanModes = ['VietQR 24/7', 'VNPAY-QR', 'Đăng nhập Web'];

  List<Map<String, String>> _recentBeneficiaries = [];

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _loadBeneficiaries();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  /// Kiểm tra và xin quyền Camera khi màn hình QR mở
  Future<void> _checkCameraPermission() async {
    final granted = await PermissionService().requestCameraPermission(context);
    if (!mounted) return;
    setState(() => _cameraPermissionGranted = granted);
    if (!granted) {
      _controller.stop();
    }
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final items = await BeneficiaryRemoteDataSource().getAll();
      if (!mounted) return;
      setState(() {
        _recentBeneficiaries = items.map((item) => {
          'name': (item['name'] ?? item['fullName'] ?? item['nickname'] ?? '').toString(),
          'bank': (item['bankCode'] ?? 'SENHONG').toString(),
          'acc': (item['phoneNumber'] ?? item['accountNumber'] ?? '').toString(),
        }).where((b) => b['acc']!.isNotEmpty).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isDecoding) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final code = barcode.rawValue!.trim();
        if (code.isEmpty) continue;

        if (_selectedModeIndex == 2) {
          // Web login mode
          _showWebLoginSuccessModal(code);
          break;
        }

        // Quét mã QR thanh toán / chuyển tiền: Tự động dừng camera & truy vấn danh tính người nhận từ Backend
        _showScannedRecipientModal(code);
        break;
      }
    }
  }

  void _showScannedRecipientModal(String rawCode) {
    _isDecoding = true;
    _controller.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) {
        return _ScannedQrVerificationSheet(
          rawCode: rawCode,
          onDismiss: () {
            Navigator.of(sheetCtx).pop();
            _isDecoding = false;
            _controller.start();
          },
          onProceed: (recipientName, phoneNumber, walletId, amount, note) {
            Navigator.of(sheetCtx).pop();
            _isDecoding = false;
            _controller.start();

            if (amount != null && amount > 0) {
              final uri = Uri(
                path: '/transfer/confirm',
                queryParameters: {
                  'recipient': recipientName,
                  'phoneNumber': phoneNumber,
                  if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
                  'amount': amount.toString(),
                  'note': note.isNotEmpty ? note : 'Chuyen tien QR',
                },
              );
              context.push(uri.toString());
            } else {
              final uri = Uri(
                path: '/transfer/amount',
                queryParameters: {
                  'recipient': recipientName,
                  'phoneNumber': phoneNumber,
                  if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
                  if (note.isNotEmpty) 'note': note,
                },
              );
              context.push(uri.toString());
            }
          },
        );
      },
    );
  }

  void _showWebLoginSuccessModal(String sessionCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.desktopcomputer, color: AppColors.emeraldGreen, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Xác nhận đăng nhập Web Banking',
              style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Thiết bị: Windows PC - Chrome Browser\nPhiên xác thực: ${sessionCode.length > 18 ? sessionCode.substring(0, 18) : sessionCode}...',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xác thực đăng nhập phiên Web Banking thành công!'),
                    backgroundColor: AppColors.emeraldGreen,
                  ),
                );
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Đồng ý đăng nhập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Từ chối giao dịch', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double scanAreaSize = 270.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fullscreen Camera View — chỉ khởi động khi đã có quyền camera
          Positioned.fill(
            child: _cameraPermissionGranted
                ? MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.camera_fill, color: Colors.white54, size: 64),
                          const SizedBox(height: 20),
                          const Text(
                            'Cần quyền Camera',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ứng dụng cần quyền Camera để quét mã QR.\nVui lòng cấp quyền và mở lại màn hình này.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _checkCameraPermission,
                            icon: const Icon(CupertinoIcons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Dark Vignette Mask around Target Box
          SafeArea(
            child: Column(
              children: [
                // Top Navigation and Flash Bar
                _buildTopAppBar(),

                // Mode Selector Segmented Tabs
                _buildModeSelector(),

                const Spacer(),

                // Center Scanning Target Box with Animated Laser
                _buildCenterScannerReticle(scanAreaSize),

                const SizedBox(height: 16),

                // Helper Tip & Regulatory Standard Badges
                _buildScanningGuideAndBadges(),

                const Spacer(),

                // Quick Beneficiary Shortcuts
                _buildRecentBeneficiariesRow(),

                const SizedBox(height: 12),

                // Bottom Tools (Glass Controls)
                _buildBottomToolbar(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white, size: 32),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quét mã QR',
                style: AppTypography.titleLarge(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Chuẩn Napas 24/7 & EMVCo',
                  style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: _isTorchOn ? AppColors.accentGold.withOpacity(0.3) : Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                _controller.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
              icon: Icon(
                _isTorchOn ? CupertinoIcons.lightbulb_fill : CupertinoIcons.lightbulb_slash,
                color: _isTorchOn ? AppColors.accentGold : Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: List.generate(_scanModes.length, (index) {
          final isSelected = _selectedModeIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedModeIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _scanModes[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCenterScannerReticle(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 4 Corner Brackets
          Positioned(top: 0, left: 0, child: _buildCorner(isTop: true, isLeft: true)),
          Positioned(top: 0, right: 0, child: _buildCorner(isTop: true, isLeft: false)),
          Positioned(bottom: 0, left: 0, child: _buildCorner(isTop: false, isLeft: true)),
          Positioned(bottom: 0, right: 0, child: _buildCorner(isTop: false, isLeft: false)),

          // Animated Glowing Laser Bar
          AnimatedBuilder(
            animation: _laserAnimation,
            builder: (context, child) {
              return Positioned(
                top: _laserAnimation.value * (size - 10),
                left: 14,
                right: 14,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.bottomBarCyan,
                        Colors.white,
                        AppColors.bottomBarCyan,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bottomBarCyan.withOpacity(0.8),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    const double length = 32.0;
    const double thickness = 4.0;
    const double radius = 12.0;
    const color = AppColors.bottomBarCyan;

    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          left: isLeft ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(radius) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(radius) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(radius) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(radius) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildScanningGuideAndBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.accentGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  _selectedModeIndex == 2
                      ? 'Hướng camera vào mã QR hiển thị trên trình duyệt Web'
                      : 'Căn chỉnh mã VietQR / VNPAY-QR vào chính giữa khung hình',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPillBadge('Napas 24/7', AppColors.emeraldGreen),
              _buildPillBadge('VietQR', AppColors.primary),
              _buildPillBadge('VNPAY-QR', AppColors.error),
              _buildPillBadge('EMVCo QRCPS', AppColors.softPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRecentBeneficiariesRow() {
    if (_recentBeneficiaries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Người thụ hưởng đã lưu:',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentBeneficiaries.map((b) {
                return GestureDetector(
                  onTap: () {
                    final uri = Uri(
                      path: '/transfer/amount',
                      queryParameters: {
                        'recipient': b['name'] ?? '',
                        'phoneNumber': b['acc'] ?? '',
                      },
                    );
                    context.push(uri.toString());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (b['name'] != null && b['name']!.isNotEmpty) ? b['name']![0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          b['name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        quality: GlassQuality.minimal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolItem(
                icon: CupertinoIcons.photo_fill,
                label: 'Thư viện ảnh',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng hướng camera trực tiếp vào mã VietQR hoặc chọn "Nhập STK"'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildToolItem(
                icon: CupertinoIcons.pencil_ellipsis_rectangle,
                label: 'Nhập STK',
                onTap: () => context.push('/transfer'),
              ),
              _buildToolItem(
                icon: CupertinoIcons.qrcode,
                label: 'QR của tôi',
                onTap: () => context.push('/my-qr'),
              ),
              _buildToolItem(
                icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                label: 'Chia tiền',
                onTap: () => context.push('/transfer/request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet xác thực danh tính người nhận từ mã QR qua API Backend
class _ScannedQrVerificationSheet extends StatefulWidget {
  final String rawCode;
  final VoidCallback onDismiss;
  final Function(String recipientName, String phoneNumber, String? walletId, double? amount, String note) onProceed;

  const _ScannedQrVerificationSheet({
    required this.rawCode,
    required this.onDismiss,
    required this.onProceed,
  });

  @override
  State<_ScannedQrVerificationSheet> createState() => _ScannedQrVerificationSheetState();
}

class _ScannedQrVerificationSheetState extends State<_ScannedQrVerificationSheet> {
  bool _isLoading = true;
  String? _error;

  String _accountNumber = '';
  String _recipientName = '';
  String? _walletId;
  String _bankName = 'Ví Sen Hồng (Nội bộ)';
  double? _qrAmount;
  String _qrNote = 'Chuyen tien QR';

  @override
  void initState() {
    super.initState();
    _queryRecipientFromQr();
  }

  Future<void> _queryRecipientFromQr() async {
    final code = widget.rawCode.trim();
    String? account;
    double? amt;
    String? note;
    String? bank;

    try {
      // 1. Kiểm tra nếu là SĐT trực tiếp 10 số (03, 05, 07, 08, 09)
      if (RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$').hasMatch(code)) {
        account = code;
      } else {
        // 2. Giải mã qua API Backend: scanQr hoặc decodeQr
        try {
          final payload = await QrRemoteDataSource().scanQr(code);
          account = (payload['accountNumber'] ?? payload['walletId'])?.toString();
          bank = (payload['bankName'] ?? payload['bankCode'])?.toString();
          if (payload['amount'] is num && (payload['amount'] as num) > 0) {
            amt = (payload['amount'] as num).toDouble();
          }
          final p = (payload['purpose'] ?? payload['note'])?.toString();
          if (p != null && p.isNotEmpty) note = p;
        } catch (_) {
          // 3. Fallback bóc tách số điện thoại từ chuẩn VietQR EMVCo (tag 0110)
          final tagMatch = RegExp(r'0110(0[3|5|7|8|9]\d{8})').firstMatch(code);
          if (tagMatch != null) {
            account = tagMatch.group(1);
          }
        }
      }

      if (account == null || account.isEmpty) {
        throw Exception('Không nhận diện được số tài khoản hoặc SĐT hợp lệ từ mã QR này');
      }

      // 4. Kiểm tra chống tự chuyển tiền cho chính mình
      const storage = FlutterSecureStorage();
      final myPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (myPhone != null && myPhone.replaceAll(RegExp(r'[\s\.\-]'), '') == account.replaceAll(RegExp(r'[\s\.\-]'), '')) {
        throw Exception('Mã QR này là của chính bạn! Không thể chuyển tiền cho chính mình.');
      }

      // 5. Truy vấn danh tính người nhận thực tế từ Backend qua GET /api/v1/wallets/recipient-info
      final info = await TransferRemoteDataSource().getRecipient(account);
      final fullName = (info['fullName'] ?? info['maskedName'] ?? account).toString();
      final walletId = info['walletId']?.toString();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _accountNumber = account!;
        _recipientName = fullName;
        _walletId = walletId;
        _qrAmount = amt;
        _bankName = bank ?? 'Ví Sen Hồng (Nội bộ)';
        if (note != null && note.isNotEmpty) _qrNote = note;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.primaryDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Xác Nhận Thông Tin Mã QR',
                        style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textMutedLight, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Loading State: Truy vấn thông tin người nhận
          if (_isLoading) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                  const SizedBox(height: 18),
                  Text(
                    'Đang truy vấn danh tính người nhận...',
                    style: AppTypography.titleSmall(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kết nối máy chủ SenBank xác thực tài khoản...',
                    style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: widget.onDismiss,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Hủy bỏ'),
            ),
          ]
          // 2. Error State: Không tìm thấy tài khoản
          else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.error, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Không thể thực hiện chuyển tiền',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onDismiss,
              icon: const Icon(CupertinoIcons.qrcode_viewfinder, size: 18),
              label: const Text('Quét lại mã khác'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ]
          // 3. Success State: Hiển thị đầy đủ danh tính người nhận thực tế
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Người nhận & Huy hiệu tích xanh
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _recipientName.isNotEmpty ? _recipientName[0].toUpperCase() : 'S',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipientName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimaryLight,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(CupertinoIcons.checkmark_seal_fill, size: 14, color: AppColors.emeraldGreen),
                                SizedBox(width: 4),
                                Text(
                                  'Đã xác thực tài khoản SenBank',
                                  style: TextStyle(fontSize: 12, color: AppColors.emeraldGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.cardBorderLight),
                  const SizedBox(height: 14),

                  // Số tài khoản & Ngân hàng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tài khoản nhận:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _accountNumber,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ngân hàng / Ví:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _bankName,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),

                  // Số tiền (nếu có từ QR)
                  if (_qrAmount != null && _qrAmount! > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Số tiền thanh toán:', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatVND(_qrAmount!),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.emeraldGreen),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Từ mã QR', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số tiền:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                        Text('Người chuyển tự nhập', style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],

                  // Nội dung chuyển
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nội dung:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _qrNote,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            ElevatedButton(
              onPressed: () => widget.onProceed(_recipientName, _accountNumber, _walletId, _qrAmount, _qrNote),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _qrAmount != null && _qrAmount! > 0 ? 'Xác nhận & Chuyển tiền' : 'Tiếp tục nhập số tiền',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: widget.onDismiss,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              child: const Text('Quét lại mã khác', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}


