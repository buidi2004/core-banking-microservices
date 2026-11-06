import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/loan_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';
import 'package:sen_hong_bank/presentation/widgets/app_bar_seam_fade.dart';

class QuickLoanScreen extends StatefulWidget {
  const QuickLoanScreen({super.key});

  @override
  State<QuickLoanScreen> createState() => _QuickLoanScreenState();
}

class _QuickLoanScreenState extends State<QuickLoanScreen> {
  double _loanAmount = 15000000;
  int _loanMonths = 6;
  final double _monthlyInterestRate =
      0.012; // 1.2%/tháng (tính theo dư nợ giảm dần)

  double get _monthlyPrincipal => _loanAmount / _loanMonths;
  double get _monthlyInterest => _loanAmount * _monthlyInterestRate;
  double get _monthlyTotal => _monthlyPrincipal + _monthlyInterest;

  bool _agreeTerms = true;
  bool _isLoading = false;
  Map<String, dynamic>? _activeLoan;

  @override
  void initState() {
    super.initState();
    _checkActiveLoan();
  }

  Future<void> _checkActiveLoan() async {
    try {
      final loans = await LoanRemoteDataSource().getUserLoans();
      if (loans.isNotEmpty && mounted) {
        setState(() {
          _activeLoan = loans.firstWhere(
            (l) =>
                l['status'] == 'DISBURSED' ||
                l['status'] == 'ACTIVE' ||
                l['status'] == 'PENDING_APPROVAL',
            orElse: () => loans.first,
          );
        });
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _loanPackages = const [
    {
      'title': 'Vay Tiêu Dùng Nhanh',
      'limit': '50.000.000 đ',
      'rate': '1.2% / tháng',
      'tag': 'Phổ biến nhất',
      'icon': CupertinoIcons.rocket_fill,
    },
    {
      'title': 'Vay Mua Sắm Trả Góp',
      'limit': '30.000.000 đ',
      'rate': '0% lãi kỳ đầu',
      'tag': 'Ưu đãi 0%',
      'icon': CupertinoIcons.bag_fill,
    },
    {
      'title': 'Thấu Chi Lương Linh Hoạt',
      'limit': '100.000.000 đ',
      'rate': '1.0% / tháng',
      'tag': 'Hạn mức cao',
      'icon': CupertinoIcons.creditcard_fill,
    },
  ];

  void _submitApplication() {
    if (!BackendCapabilities.loans) {
      showFeatureUnavailable(
        context,
        feature: 'Vay tiêu dùng',
        reason: 'Hệ thống tín dụng tiêu dùng đang bảo trì.',
      );
      return;
    }
    if (!_agreeTerms) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản hợp đồng tín dụng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _showSigningModal();
  }

  void _showSigningModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LoanSigningModal(
        loanAmount: _loanAmount,
        loanMonths: _loanMonths,
        onVerified: (pinToken, otpToken) {
          Navigator.pop(ctx);
          _executeLoanApply(pinToken: pinToken, otpToken: otpToken);
        },
      ),
    );
  }

  Future<void> _executeLoanApply({String? pinToken, String? otpToken}) async {
    setState(() => _isLoading = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final res = await LoanRemoteDataSource().applyLoan(
        walletId: wallet.walletId,
        productType: 'VAY_TIEU_DUNG_NHANH',
        amount: _loanAmount,
        termMonths: _loanMonths,
        purpose: 'Vay tiêu dùng cá nhân',
        pinToken: pinToken,
        otpToken: otpToken,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.emeraldGreen, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Nộp Hồ Sơ Thành Công!',
                      style: TextStyle(
                          color: AppColors.textPrimaryLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Text(
              'Hợp đồng số ${res['contractNumber'] ?? ''} với số tiền ${CurrencyFormatter.formatVND(_loanAmount)} (kỳ hạn $_loanMonths tháng) đã được tiếp nhận thành công và gửi tới hệ thống phê duyệt.',
              style: const TextStyle(
                  color: AppColors.textSecondaryLight, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                child: const Text('Về màn hình chính'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(extractErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Vay Tiêu Dùng Tức Thì'),
        backgroundColor: Colors.transparent,
        flexibleSpace: const AppBarSeamFade(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActiveLoanBanner(),
              // Loan Limit Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF003859),
                      Color(0xFF005580),
                      Color(0xFF006D9E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bottomBarGlow.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.sparkles,
                        color: AppColors.bottomBarCyan, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HẠN MỨC PHÊ DUYỆT TỰ ĐỘNG AI',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          const Text('Lên đến 50.000.000 đ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          Text(
                              'Giải ngân thần tốc sau 15 phút • Không cần thế chấp tài sản',
                              style:
                                  AppTypography.bodySmall(color: Colors.white)
                                      .copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Loan Packages Comparison
              Text('Các gói vay ưu đãi',
                  style: AppTypography.titleLarge(
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _loanPackages.map((pkg) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(pkg['icon'] as IconData,
                                    color: AppColors.primary, size: 22),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.25),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(pkg['tag'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(pkg['title'] as String,
                                style: AppTypography.titleSmall(
                                        color: AppColors.textPrimaryLight)
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Hạn mức: ${pkg['limit']}',
                                style: const TextStyle(
                                    color: AppColors.successTextLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            Text('Lãi suất: ${pkg['rate']}',
                                style: AppTypography.bodySmall(
                                        color: AppColors.textSecondaryLight)
                                    .copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Loan Amount Slider Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số tiền muốn vay',
                          style: AppTypography.titleMedium(
                              color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.formatVND(_loanAmount),
                        style: AppTypography.displayMedium(
                                color: AppColors.primaryDark)
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(_loanAmount)} đồng',
                        style: AppTypography.bodySmall(
                                color: AppColors.primaryDark)
                            .copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: _loanAmount,
                        min: 5000000,
                        max: 50000000,
                        divisions: 9,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.borderSubtle,
                        onChanged: (val) {
                          if (val != _loanAmount) {
                            HapticFeedback.selectionClick();
                          }
                          setState(() => _loanAmount = val);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Tối thiểu: 5.000.000 đ',
                                style: AppTypography.bodySmall(
                                        color: AppColors.textSecondaryLight)
                                    .copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Tối đa: 50.000.000 đ',
                                textAlign: TextAlign.right,
                                style: AppTypography.bodySmall(
                                        color: AppColors.textSecondaryLight)
                                    .copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Kỳ hạn trả góp',
                          style: AppTypography.titleMedium(
                              color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [3, 6, 9, 12, 18].map((m) {
                            final isSelected = _loanMonths == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _loanMonths = m);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.cardBorderLight,
                                    ),
                                  ),
                                  child: Text(
                                    '$m tháng',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Monthly Repayment Details Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lịch trả nợ ước tính hàng tháng',
                          style: AppTypography.titleLarge(
                              color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text('Trả hàng tháng (Gốc + Lãi):',
                                style: AppTypography.bodyMedium(
                                    color: AppColors.textSecondaryLight)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 6,
                            child: Text(
                                CurrencyFormatter.formatVND(_monthlyTotal),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleLarge(
                                        color: AppColors.successTextLight)
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(
                          height: 24, color: AppColors.cardBorderLight),
                      _buildRow('Tiền gốc hàng tháng',
                          CurrencyFormatter.formatVND(_monthlyPrincipal)),
                      const SizedBox(height: 8),
                      _buildRow('Tiền lãi hàng tháng (1.2%)',
                          CurrencyFormatter.formatVND(_monthlyInterest)),
                      const SizedBox(height: 8),
                      _buildRow(
                          'Tổng tiền lãi cả kỳ ($_loanMonths tháng)',
                          CurrencyFormatter.formatVND(
                              _monthlyInterest * _loanMonths)),
                      const SizedBox(height: 8),
                      _buildRow('Phí thẩm định & hồ sơ', 'Miễn phí (0đ)',
                          isGreen: true),
                      const SizedBox(height: 8),
                      _buildRow(
                          'Phí bảo hiểm khoản vay', 'Được Sen Hồng tài trợ',
                          isGreen: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => context.push('/loan/schedule',
                              extra: _activeLoan),
                          icon: const Icon(CupertinoIcons.calendar_today,
                              size: 16, color: AppColors.primary),
                          label: const Text(
                            'Xem bảng khấu hao 12 kỳ chi tiết',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 Steps Process
              Text('Quy trình giải ngân 4 bước',
                  style: AppTypography.titleLarge(
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 12),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStepItem('1', 'Đăng ký khoản vay',
                          'Chọn số tiền và kỳ hạn trả góp phù hợp với nhu cầu.'),
                      const Divider(
                          height: 16, color: AppColors.cardBorderLight),
                      _buildStepItem('2', 'AI thẩm định tự động',
                          'Hệ thống đối chiếu CCCD và điểm tín dụng CIC trong 3 phút.'),
                      const Divider(
                          height: 16, color: AppColors.cardBorderLight),
                      _buildStepItem('3', 'Ký hợp đồng điện tử',
                          'Xác thực ký số an toàn bằng Smart OTP trực tiếp trên app.'),
                      const Divider(
                          height: 16, color: AppColors.cardBorderLight),
                      _buildStepItem('4', 'Nhận tiền ngay',
                          'Tiền giải ngân vào số dư ví Sen Hồng, có thể rút về ngân hàng ngay.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Eligibility Criteria
              Text('Điều kiện duyệt vay',
                  style: AppTypography.titleLarge(
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCheckItem(
                          'Công dân Việt Nam trong độ tuổi từ 18 đến 60 tuổi.'),
                      const SizedBox(height: 8),
                      _buildCheckItem(
                          'Đã hoàn tất định danh điện tử eKYC bằng CCCD gắn chip chính chủ.'),
                      const SizedBox(height: 8),
                      _buildCheckItem(
                          'Thu nhập ổn định từ 5.000.000 đ/tháng trở lên.'),
                      const SizedBox(height: 8),
                      _buildCheckItem(
                          'Không có nợ xấu tại các tổ chức tín dụng (CIC Nhóm 1).'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Terms Agreement
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _agreeTerms,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _agreeTerms = v ?? true),
                title: const Text(
                  'Tôi đồng ý với điều khoản hợp đồng tín dụng và ủy quyền cho Sen Hồng Bank tra cứu điểm tín dụng CIC tự động.',
                  style: TextStyle(
                      color: AppColors.textSecondaryLight, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Nộp hồ sơ vay ngay'),
                ),
              ),
              const SizedBox(height: 24),

              // Frequently Asked Questions
              Text('Câu hỏi thường gặp',
                  style: AppTypography.titleLarge(
                      color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              _buildFaqItem(
                q: 'Tôi có thể tất toán khoản vay trước hạn không?',
                a: 'Có, bạn có thể thanh toán toàn bộ khoản vay bất kỳ lúc nào ngay trên app mà không phải chịu thêm bất kỳ khoản phí phạt tất toán nào.',
              ),
              const SizedBox(height: 8),
              _buildFaqItem(
                q: 'Cách thức thanh toán nợ hàng tháng như thế nào?',
                a: 'Hệ thống sẽ tự động nhắc nợ trước 3 ngày và trích tiền từ ví Sen Hồng vào đúng ngày thanh toán. Bạn cũng có thể chủ động thanh toán sớm.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLoanBanner() {
    if (_activeLoan == null) return const SizedBox.shrink();
    final contractNo = _activeLoan!['contractNumber'] ?? 'Hợp đồng';
    final status = _activeLoan!['status'] ?? '';
    final statusLabel = status == 'DISBURSED'
        ? 'ĐANG GIẢI NGÂN'
        : (status == 'PENDING_APPROVAL' ? 'CHỜ DUYỆT' : status.toString());
    final amt =
        (_activeLoan!['amount'] ?? _activeLoan!['principalAmount'] as num?)
                ?.toDouble() ??
            0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.doc_checkmark_fill,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contractNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'DISBURSED'
                            ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: status == 'DISBURSED'
                              ? AppColors.emeraldGreen
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Dư nợ gốc: ${CurrencyFormatter.formatVND(amt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push('/loan/schedule', extra: _activeLoan),
            child: const Text('Lịch trả nợ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 5,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondaryLight, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isGreen
                  ? AppColors.successTextLight
                  : AppColors.textPrimaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String step, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(step,
              style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.titleSmall(
                          color: AppColors.textPrimaryLight)
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc,
                  style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight)
                      .copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(CupertinoIcons.checkmark_alt_circle_fill,
            color: AppColors.successTextLight, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                  height: 1.35)),
        ),
      ],
    );
  }

  Widget _buildFaqItem({required String q, required String a}) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(q,
            style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)
                .copyWith(fontSize: 13)),
        children: [
          Text(a,
              style:
                  AppTypography.bodySmall(color: AppColors.textSecondaryLight)
                      .copyWith(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

class _LoanSigningModal extends StatefulWidget {
  final double loanAmount;
  final int loanMonths;
  final Function(String? pinToken, String? otpToken) onVerified;

  const _LoanSigningModal({
    required this.loanAmount,
    required this.loanMonths,
    required this.onVerified,
  });

  @override
  State<_LoanSigningModal> createState() => _LoanSigningModalState();
}

class _LoanSigningModalState extends State<_LoanSigningModal> {
  int _selectedTab = 0; // 0: Mã PIN, 1: Smart OTP
  String _pin = '';
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isSendingOtp = false;
  String? _errorMessage;
  String? _otpSuccessMessage;
  int _countdown = 0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  Future<void> _handlePinChange(String val) async {
    if (_isVerifying) return;
    setState(() {
      _pin = val;
      _errorMessage = null;
    });

    if (val.length == 6) {
      HapticFeedback.mediumImpact();
      setState(() => _isVerifying = true);
      try {
        final pinToken =
            await WalletTransactionRemoteDataSource().verifyPin(val);
        if (mounted) {
          widget.onVerified(pinToken, null);
        }
      } catch (err) {
        if (mounted) {
          HapticFeedback.vibrate();
          setState(() {
            _pin = '';
            _isVerifying = false;
            _errorMessage = extractErrorMessage(err);
          });
        }
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_countdown > 0 || _isSendingOtp) return;
    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });
    try {
      final res = await AuthRemoteDataSource().requestLoanOtp();
      if (mounted) {
        final email = res['maskedEmail'] ?? 'Gmail';
        setState(() {
          _isSendingOtp = false;
          _otpSuccessMessage = 'Mã OTP 6 số đã được gửi tới $email';
        });
        _startCountdown();
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _errorMessage = extractErrorMessage(err);
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã OTP');
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      final otpToken = await AuthRemoteDataSource().verifyLoanOtp(code);
      if (mounted) {
        widget.onVerified(null, otpToken);
      }
    } catch (err) {
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() {
          _isVerifying = false;
          _errorMessage = extractErrorMessage(err);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ký Số Hợp Đồng Tín Dụng',
                style:
                    AppTypography.titleMedium(color: AppColors.textPrimaryLight)
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill,
                    color: Colors.black38, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khoản giải ngân:',
                        style: TextStyle(
                            color: AppColors.textSecondaryLight, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatVND(widget.loanAmount),
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Kỳ hạn ${widget.loanMonths} tháng',
                  style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Segment Tab: Mã PIN vs Smart OTP
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedTab = 0;
                      _errorMessage = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Text(
                        'Mã PIN Giao Dịch',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTab == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTab == 0
                              ? AppColors.primaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedTab = 1;
                      _errorMessage = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Text(
                        'Smart OTP (Gmail)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedTab == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTab == 1
                              ? AppColors.primaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle_fill,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // TAB 0: PIN
          if (_selectedTab == 0) ...[
            const Text(
              'Nhập mã PIN 6 số để ký số phê duyệt hợp đồng',
              style:
                  TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // PIN Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled
                          ? AppColors.primary
                          : AppColors.cardBorderLight,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            if (_isVerifying)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              CustomPinNumpad(
                pin: _pin,
                maxDigits: 6,
                showBiometric: false,
                onPinChanged: _handlePinChange,
              ),
          ]
          // TAB 1: Smart OTP
          else ...[
            if (_otpSuccessMessage != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                        color: AppColors.emeraldGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _otpSuccessMessage!,
                        style: const TextStyle(
                            color: AppColors.emeraldGreen, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // OTP Input
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: const TextStyle(
                  color: Colors.black26,
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Send/Resend OTP Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed:
                      (_countdown > 0 || _isSendingOtp) ? null : _sendOtp,
                  icon: _isSendingOtp
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(CupertinoIcons.mail_solid, size: 16),
                  label: Text(
                    _countdown > 0
                        ? 'Gửi lại mã OTP sau ${_countdown}s'
                        : (_otpSuccessMessage == null
                            ? 'Gửi mã OTP về Gmail'
                            : 'Gửi lại mã OTP'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Xác nhận & Ký số hợp đồng'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
