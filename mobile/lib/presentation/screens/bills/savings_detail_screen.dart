import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';

class SavingsDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? passbook;

  const SavingsDetailScreen({super.key, this.passbook});

  @override
  State<SavingsDetailScreen> createState() => _SavingsDetailScreenState();
}

class _SavingsDetailScreenState extends State<SavingsDetailScreen> {
  late Map<String, dynamic> _data;
  String _userName = 'NGUYỄN VĂN AN';
  String _userCccd = '079204001234';
  String _userPhone = '0901234567';
  int _rolloverChoice = 0; // 0: Goc + Lai, 1: Chi Goc, 2: Tat toan ve vi
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _data = widget.passbook ?? {
      'code': 'STK2026-088192',
      'product': 'Tiết Kiệm Phát Lộc Online',
      'principal': 50000000.0,
      'term': '12 tháng (7.2%/năm)',
      'rate': 7.2,
      'months': 12,
      'openDate': '15/01/2026',
      'maturityDate': '15/01/2027',
      'expectedInterest': 3600000.0,
      'accruedInterest': 591780.0,
      'rollover': 'Tự động tái tục Gốc + Lãi',
      'status': 'ĐANG SINH LỜI',
      'canWithdrawPart': true,
    };
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    const storage = FlutterSecureStorage();
    try {
      final name = await storage.read(key: AppConstants.keyFullName);
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (mounted) {
        setState(() {
          if (name != null && name.isNotEmpty) _userName = name;
          if (phone != null && phone.isNotEmpty) _userPhone = phone;
        });
      }
      final me = await ProfileRemoteDataSource().getMe();
      final n = me['fullName'] as String? ?? me['name'] as String? ?? '';
      final p = me['phoneNumber'] as String? ?? '';
      final cccd = me['idNumber'] as String? ?? me['citizenId'] as String? ?? '';
      if (mounted) {
        setState(() {
          if (n.isNotEmpty) _userName = n;
          if (p.isNotEmpty) _userPhone = p;
          if (cccd.isNotEmpty) _userCccd = cccd;
        });
      }
    } catch (_) {}
  }

  void _showRolloverDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0C1929),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Thay đổi chỉ thị tái tục đáo hạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chọn phương án xử lý tiền gốc & lãi khi sổ đến ngày đáo hạn (${_data['maturityDate']})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.3,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRolloverOption(
                    title: 'Tự động tái tục cả Gốc và Lãi',
                    subtitle: 'Toàn bộ gốc + lãi nhập vào kỳ hạn mới 12 tháng sinh lời tối đa',
                    value: 0,
                    groupVal: _rolloverChoice,
                    onTap: () => setModalState(() => _rolloverChoice = 0),
                  ),
                  const SizedBox(height: 12),
                  _buildRolloverOption(
                    title: 'Tái tục Gốc, Lãi chuyển vào Ví',
                    subtitle: 'Gốc chuyển sang kỳ hạn mới, tiền lãi tự động rót về Ví SenBank',
                    value: 1,
                    groupVal: _rolloverChoice,
                    onTap: () => setModalState(() => _rolloverChoice = 1),
                  ),
                  const SizedBox(height: 12),
                  _buildRolloverOption(
                    title: 'Tất toán toàn bộ về Ví SenBank',
                    subtitle: 'Không tái tục, thanh toán cả gốc & lãi về tài khoản chính',
                    value: 2,
                    groupVal: _rolloverChoice,
                    onTap: () => setModalState(() => _rolloverChoice = 2),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bottomBarCyan,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          if (_rolloverChoice == 0) {
                            _data['rollover'] = 'Tự động tái tục Gốc + Lãi';
                          } else if (_rolloverChoice == 1) {
                            _data['rollover'] = 'Tái tục Gốc, Lãi về ví $_userPhone';
                          } else {
                            _data['rollover'] = 'Tất toán toàn bộ về ví khi đáo hạn';
                          }
                        });
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã cập nhật chỉ thị tái tục: ${_data['rollover']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Xác nhận thay đổi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRolloverOption({
    required String title,
    required String subtitle,
    required int value,
    required int groupVal,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupVal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.bottomBarCyan.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.bottomBarCyan
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: isSelected ? AppColors.bottomBarCyan : Colors.white54,
              size: 22,
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSettlement() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.accentGold, size: 24),
            SizedBox(width: 10),
            Text(
              'Tất toán sổ trước hạn?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sổ tiết kiệm ${_data['code']} chưa đến ngày đáo hạn (${_data['maturityDate']}).',
              style: const TextStyle(color: Colors.white70, height: 1.3),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gốc hoàn trả:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(CurrencyFormatter.formatVND(_data['principal'] as double), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lãi không kỳ hạn (0.2%):', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text('+ 16.438 đ', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bạn có chắc chắn muốn tất toán và nhận tiền về ví SenBank ngay bây giờ?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isSettling = true);
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!mounted) return;
                setState(() => _isSettling = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tất toán thành công! Tiền đã được chuyển vào Ví SenBank.'),
                    backgroundColor: AppColors.emeraldGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.pop();
              });
            },
            child: const Text('Xác nhận tất toán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareCertificate() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.share_up, color: AppColors.bottomBarCyan, size: 20),
            const SizedBox(width: 10),
            Text(
              'Đang xuất Chứng chỉ tiền gửi điện tử ${_data['code']} (PDF/QR)...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final principal = (_data['principal'] as num).toDouble();
    final expectedInterest = (_data['expectedInterest'] as num).toDouble();
    final accruedInterest = (_data['accruedInterest'] as num).toDouble();
    final rate = (_data['rate'] as num).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF030B17),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
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
                _buildAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      _buildCertificateCard(principal, rate),
                      const SizedBox(height: 20),
                      _buildGrowthProgressCard(principal, accruedInterest, expectedInterest),
                      const SizedBox(height: 20),
                      _buildContractDetailsCard(),
                      const SizedBox(height: 20),
                      _buildLegalNoticeCard(),
                      const SizedBox(height: 28),
                      _buildActionButtons(),
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

  Widget _buildAppBar() {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chứng chỉ Tiết kiệm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                Text(
                  _data['code'] as String,
                  style: const TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _shareCertificate,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.share,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(double principal, double rate) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102847),
            Color(0xFF0B192D),
            Color(0xFF05101E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SENBANK E-CERTIFICATE',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        _data['product'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emeraldGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _data['status'] as String,
                      style: const TextStyle(
                        color: AppColors.emeraldGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Số tiền gửi gốc',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.formatVND(principal).replaceAll(' ₫', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'VND',
                style: TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lãi suất áp dụng', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('$rate% / năm', style: const TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kỳ hạn gửi', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('${_data['months']} tháng', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngày đáo hạn', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(_data['maturityDate'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chủ tài khoản: $_userName',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'CCCD: $_userCccd',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthProgressCard(double principal, double accruedInterest, double expectedInterest) {
    final totalExpected = principal + expectedInterest;
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.chart_bar_alt_fill, color: AppColors.emeraldGreen, size: 20),
                SizedBox(width: 10),
                Text(
                  'Tiến trình Tích lũy Lợi nhuận',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lãi tạm tính đến hôm nay', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '+ ${CurrencyFormatter.formatVND(accruedInterest)}',
                      style: const TextStyle(
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tổng lãi khi đáo hạn', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatVND(expectedInterest),
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (accruedInterest / (expectedInterest > 0 ? expectedInterest : 1)).clamp(0.05, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gửi ngày: ${_data['openDate']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                Text('Đáo hạn: ${_data['maturityDate']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền thực nhận khi đáo hạn:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    CurrencyFormatter.formatVND(totalExpected),
                    style: const TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractDetailsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.doc_plaintext, color: AppColors.bottomBarCyan, size: 20),
                SizedBox(width: 10),
                Text(
                  'Chi tiết Hợp đồng Điện tử',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Số hợp đồng / Sổ:', _data['code'] as String),
            _buildDetailRow('Hình thức trả lãi:', 'Trả lãi cuối kỳ vào ngày đáo hạn'),
            _buildDetailRow('Tài khoản nhận gốc & lãi:', 'Ví SenBank ($_userPhone)'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chỉ thị khi đáo hạn:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          _data['rollover'] as String,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showRolloverDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.pencil, color: AppColors.bottomBarCyan, size: 14),
                          SizedBox(width: 4),
                          Text('Thay đổi', style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildDetailRow('Bảo hiểm tiền gửi:', 'Được bảo hiểm bởi DIV & NHNN'),
            _buildDetailRow('Chữ ký số ngân hàng:', 'SENBANK-CA-SHA256-VERIFIED'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.emeraldGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Áp dụng Thông tư 04/2022/TT-NHNN: Khách hàng có thể rút gốc từng phần trước hạn. Số tiền gốc còn lại trong sổ vẫn được hưởng trọn vẹn mức lãi suất kỳ hạn 7.2%/năm ban đầu.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bottomBarCyan.withValues(alpha: 0.15),
              foregroundColor: AppColors.bottomBarCyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.bottomBarCyan.withValues(alpha: 0.5)),
              ),
              elevation: 0,
            ),
            onPressed: _showRolloverDialog,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.arrow_2_squarepath, color: AppColors.bottomBarCyan, size: 18),
                SizedBox(width: 8),
                Text(
                  'Đổi phương thức tái tục',
                  style: TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSettling ? null : _handleSettlement,
            child: _isSettling
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.money_dollar_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tất toán sổ về Ví SenBank',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
