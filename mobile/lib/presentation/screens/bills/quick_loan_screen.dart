import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

class QuickLoanScreen extends StatefulWidget {
  const QuickLoanScreen({super.key});

  @override
  State<QuickLoanScreen> createState() => _QuickLoanScreenState();
}

class _QuickLoanScreenState extends State<QuickLoanScreen> {
  double _loanAmount = 15000000;
  int _loanMonths = 6;
  final double _monthlyInterestRate = 0.012; // 1.2%/tháng (tính theo dư nợ giảm dần)

  double get _monthlyPrincipal => _loanAmount / _loanMonths;
  double get _monthlyInterest => _loanAmount * _monthlyInterestRate;
  double get _monthlyTotal => _monthlyPrincipal + _monthlyInterest;

  bool _agreeTerms = true;
  bool _isLoading = false;

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

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Nộp Hồ Sơ Thành Công!', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            'Hồ sơ vay tiêu dùng nhanh ${CurrencyFormatter.formatVND(_loanAmount)} (Kỳ hạn $_loanMonths tháng) của bạn đã được tiếp nhận. Hệ thống AI chấm điểm tín dụng tự động phê duyệt và giải ngân vào ví Sen Hồng trong vòng 15 phút.',
            style: const TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Vay Tiêu Dùng Tức Thì'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Limit Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.bottomBarCyan],
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
                    const Icon(CupertinoIcons.sparkles, color: AppColors.accentGold, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HẠN MỨC PHÊ DUYỆT TỰ ĐỘNG AI', style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          const Text('Lên đến 50.000.000 đ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          Text('Giải ngân thần tốc sau 15 phút • Không cần thế chấp tài sản', style: AppTypography.bodySmall(color: Colors.white70).copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Loan Packages Comparison
              Text('Các gói vay ưu đãi', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _loanPackages.map((pkg) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 200,
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
                                Icon(pkg['icon'] as IconData, color: AppColors.primary, size: 22),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(pkg['tag'] as String, style: const TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(pkg['title'] as String, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Hạn mức: ${pkg['limit']}', style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('Lãi suất: ${pkg['rate']}', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
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
                      Text('Số tiền muốn vay', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.formatVND(_loanAmount),
                        style: AppTypography.displayMedium(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(_loanAmount)} đồng',
                        style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
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
                          Text('Tối thiểu: 5.000.000 đ', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                          Text('Tối đa: 50.000.000 đ', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('Kỳ hạn trả góp', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [3, 6, 9, 12, 18].map((m) {
                            final isSelected = _loanMonths == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$m tháng'),
                                selected: isSelected,
                                onSelected: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _loanMonths = m);
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
                      Text('Lịch trả nợ ước tính hàng tháng', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Trả hàng tháng (Gốc + Lãi):', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
                          Text(CurrencyFormatter.formatVND(_monthlyTotal), style: AppTypography.titleLarge(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.cardBorderLight),
                      _buildRow('Tiền gốc hàng tháng', CurrencyFormatter.formatVND(_monthlyPrincipal)),
                      const SizedBox(height: 8),
                      _buildRow('Tiền lãi hàng tháng (1.2%)', CurrencyFormatter.formatVND(_monthlyInterest)),
                      const SizedBox(height: 8),
                      _buildRow('Tổng tiền lãi cả kỳ ($_loanMonths tháng)', CurrencyFormatter.formatVND(_monthlyInterest * _loanMonths)),
                      const SizedBox(height: 8),
                      _buildRow('Phí thẩm định & hồ sơ', 'Miễn phí (0đ)', isGreen: true),
                      const SizedBox(height: 8),
                      _buildRow('Phí bảo hiểm khoản vay', 'Được Sen Hồng tài trợ', isGreen: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => context.push('/loan/schedule'),
                          icon: const Icon(CupertinoIcons.calendar_today, size: 16, color: AppColors.primary),
                          label: const Text(
                            'Xem bảng khấu hao 12 kỳ chi tiết',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 Steps Process
              Text('Quy trình giải ngân 4 bước', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 12),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStepItem('1', 'Đăng ký khoản vay', 'Chọn số tiền và kỳ hạn trả góp phù hợp với nhu cầu.'),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildStepItem('2', 'AI thẩm định tự động', 'Hệ thống đối chiếu CCCD và điểm tín dụng CIC trong 3 phút.'),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildStepItem('3', 'Ký hợp đồng điện tử', 'Xác thực ký số an toàn bằng Smart OTP trực tiếp trên app.'),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildStepItem('4', 'Nhận tiền ngay', 'Tiền giải ngân vào số dư ví Sen Hồng, có thể rút về ngân hàng ngay.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Eligibility Criteria
              Text('Điều kiện duyệt vay', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCheckItem('Công dân Việt Nam trong độ tuổi từ 18 đến 60 tuổi.'),
                      const SizedBox(height: 8),
                      _buildCheckItem('Đã hoàn tất định danh điện tử eKYC bằng CCCD gắn chip chính chủ.'),
                      const SizedBox(height: 8),
                      _buildCheckItem('Thu nhập ổn định từ 5.000.000 đ/tháng trở lên.'),
                      const SizedBox(height: 8),
                      _buildCheckItem('Không có nợ xấu tại các tổ chức tín dụng (CIC Nhóm 1).'),
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
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Nộp hồ sơ vay ngay'),
                ),
              ),
              const SizedBox(height: 24),

              // Frequently Asked Questions
              Text('Câu hỏi thường gặp', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
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

  Widget _buildRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isGreen ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
          child: Text(step, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
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
        const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.emeraldGreen, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.35)),
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
        title: Text(q, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13)),
        children: [
          Text(a, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
