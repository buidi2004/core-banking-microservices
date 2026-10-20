import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

class LoanScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? loanData;

  const LoanScheduleScreen({super.key, this.loanData});

  @override
  State<LoanScheduleScreen> createState() => _LoanScheduleScreenState();
}

class _LoanScheduleScreenState extends State<LoanScheduleScreen> {
  bool _autoDebit = true;
  bool _isPaying = false;

  final String _contractNumber = 'HDTD-2026-88391';
  final String _productName = 'Vay Tiêu Dùng Nhanh SenBank';
  final double _totalLoan = 15000000;
  final int _totalTerms = 6;
  final double _interestRatePerMonth = 1.2; // 1.2%/thang

  // 6 ky tra no theo du no giam dan
  final List<Map<String, dynamic>> _schedule = [
    {
      'term': 1,
      'dueDate': '15/08/2026',
      'principal': 2500000.0,
      'interest': 180000.0,
      'total': 2680000.0,
      'remaining': 12500000.0,
      'status': 'PAID', // PAID, DUE, UPCOMING
      'paidDate': '14/08/2026',
    },
    {
      'term': 2,
      'dueDate': '15/09/2026',
      'principal': 2500000.0,
      'interest': 150000.0,
      'total': 2650000.0,
      'remaining': 10000000.0,
      'status': 'PAID',
      'paidDate': '15/09/2026',
    },
    {
      'term': 3,
      'dueDate': '15/10/2026',
      'principal': 2500000.0,
      'interest': 120000.0,
      'total': 2620000.0,
      'remaining': 7500000.0,
      'status': 'DUE',
      'paidDate': null,
    },
    {
      'term': 4,
      'dueDate': '15/11/2026',
      'principal': 2500000.0,
      'interest': 90000.0,
      'total': 2590000.0,
      'remaining': 5000000.0,
      'status': 'UPCOMING',
      'paidDate': null,
    },
    {
      'term': 5,
      'dueDate': '15/12/2026',
      'principal': 2500000.0,
      'interest': 60000.0,
      'total': 2560000.0,
      'remaining': 2500000.0,
      'status': 'UPCOMING',
      'paidDate': null,
    },
    {
      'term': 6,
      'dueDate': '15/01/2027',
      'principal': 2500000.0,
      'interest': 30000.0,
      'total': 2530000.0,
      'remaining': 0.0,
      'status': 'UPCOMING',
      'paidDate': null,
    },
  ];

  void _payCurrentTerm() {
    HapticFeedback.heavyImpact();
    final dueTerm = _schedule.firstWhere(
      (item) => item['status'] == 'DUE',
      orElse: () => _schedule[2],
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.creditcard_fill, color: AppColors.bottomBarCyan, size: 24),
            const SizedBox(width: 10),
            Text(
              'Thanh toán Kỳ ${dueTerm['term']}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận trích tiền từ Ví SenBank để thanh toán kỳ hạn ngày ${dueTerm['dueDate']}.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gốc kỳ này:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(CurrencyFormatter.formatVND(dueTerm['principal'] as double), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lãi kỳ này:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(CurrencyFormatter.formatVND(dueTerm['interest'] as double), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        CurrencyFormatter.formatVND(dueTerm['total'] as double),
                        style: const TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bottomBarCyan,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isPaying = true);
              Future.delayed(const Duration(milliseconds: 900), () {
                if (!mounted) return;
                setState(() {
                  _isPaying = false;
                  dueTerm['status'] = 'PAID';
                  dueTerm['paidDate'] = 'Hôm nay';
                  if (_schedule.length > 3) {
                    _schedule[3]['status'] = 'DUE';
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Thanh toán Kỳ ${dueTerm['term']} thành công! Điểm tín dụng SenBank của bạn đã tăng.',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              });
            },
            child: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportSchedulePdf() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.arrow_down_doc_fill, color: AppColors.bottomBarCyan, size: 20),
            const SizedBox(width: 10),
            Text(
              'Đang tải file Lịch trả nợ & Bảng khấu hao $_contractNumber (PDF)...',
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
    return Scaffold(
      backgroundColor: const Color(0xFF030B17),
      body: Stack(
        children: [
          // Ambient backgrounds
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.26),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      _buildOverviewCard(),
                      const SizedBox(height: 20),
                      _buildBreakdownRatioCard(),
                      const SizedBox(height: 22),
                      _buildSectionHeader('BẢNG KHẤU HAO TỪNG KỲ (DƯ NỢ GIẢM DẦN)'),
                      const SizedBox(height: 12),
                      _buildScheduleList(),
                      const SizedBox(height: 20),
                      _buildAutoDebitToggle(),
                      const SizedBox(height: 20),
                      _buildPrepaymentTermsCard(),
                      const SizedBox(height: 28),
                      _buildBottomActions(),
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
                  'Lịch trả nợ & Khấu hao',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                Text(
                  _contractNumber,
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
            onTap: _exportSchedulePdf,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.arrow_down_doc,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2C4C),
            Color(0xFF0B1F37),
            Color(0xFF061324),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                      CupertinoIcons.shield_lefthalf_fill,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _productName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Điểm CIC: 720 (Hạng 1 Chuẩn Tốt)',
                        style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'ĐANG VAY',
                  style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Dư nợ gốc còn lại', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '10.000.000',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'VND',
                style: TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Gốc ban đầu', CurrencyFormatter.formatVND(_totalLoan)),
                Container(height: 24, width: 1, color: Colors.white12),
                _buildMiniStat('Kỳ hạn', '$_totalTerms tháng'),
                Container(height: 24, width: 1, color: Colors.white12),
                _buildMiniStat('Lãi suất', '$_interestRatePerMonth%/tháng'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildBreakdownRatioCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cơ cấu khoản vay toàn kỳ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Đã trả: 2 / $_totalTerms kỳ (33.3%)',
                  style: const TextStyle(color: AppColors.bottomBarCyan, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Expanded(
                    flex: 88,
                    child: Container(
                      height: 10,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 12,
                    child: Container(
                      height: 10,
                      color: AppColors.accentGold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Tổng gốc: 15.000.000 đ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentGold, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Tổng lãi: 630.000 đ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.bottomBarCyan,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      children: _schedule.map((item) => _buildScheduleItem(item)).toList(),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> item) {
    final term = item['term'] as int;
    final dueDate = item['dueDate'] as String;
    final principal = item['principal'] as double;
    final interest = item['interest'] as double;
    final total = item['total'] as double;
    final remaining = item['remaining'] as double;
    final status = item['status'] as String;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (status == 'PAID') {
      badgeBg = AppColors.emeraldGreen.withValues(alpha: 0.18);
      badgeText = AppColors.emeraldGreen;
      badgeLabel = 'ĐÃ TRẢ';
      badgeIcon = CupertinoIcons.checkmark_alt_circle_fill;
    } else if (status == 'DUE') {
      badgeBg = AppColors.accentGold.withValues(alpha: 0.22);
      badgeText = AppColors.accentGold;
      badgeLabel = 'ĐẾN HẠN';
      badgeIcon = CupertinoIcons.clock_fill;
    } else {
      badgeBg = Colors.white.withValues(alpha: 0.08);
      badgeText = Colors.white60;
      badgeLabel = 'CHƯA ĐẾN';
      badgeIcon = CupertinoIcons.circle;
    }

    final isDue = status == 'DUE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDue
            ? const Color(0xFF142944)
            : const Color(0xFF0C1929).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDue
              ? AppColors.bottomBarCyan.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: isDue ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDue ? AppColors.bottomBarCyan : Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$term',
                        style: TextStyle(
                          color: isDue ? AppColors.primaryDark : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kỳ hạn ngày $dueDate',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Dư nợ sau kỳ: ${CurrencyFormatter.formatVND(remaining)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeText, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gốc: ${CurrencyFormatter.formatVND(principal)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '+ Lãi: ${CurrencyFormatter.formatVND(interest)}',
                  style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '= ${CurrencyFormatter.formatVND(total)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isDue) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bottomBarCyan,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isPaying ? null : _payCurrentTerm,
                child: _isPaying
                    ? const CupertinoActivityIndicator(color: AppColors.primaryDark)
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.creditcard, size: 18),
                          SizedBox(width: 8),
                          Text('Thanh toán kỳ này ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoDebitToggle() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(CupertinoIcons.arrow_2_squarepath, color: AppColors.bottomBarCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trích nợ tự động (Auto-Debit)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tự động trừ ví vào ngày đến hạn để duy trì điểm CIC tốt',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _autoDebit,
              activeTrackColor: AppColors.bottomBarCyan,
              onChanged: (val) {
                setState(() => _autoDebit = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepaymentTermsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.info_circle_fill, color: AppColors.accentGold, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chính sách trả nợ trước hạn: Phí phạt 0% từ kỳ thứ 3 trở đi. Tiền lãi chỉ tính trên số ngày thực tế sử dụng vốn đến thời điểm tất toán.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _payCurrentTerm,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.money_dollar_circle_fill, size: 20),
            SizedBox(width: 8),
            Text(
              'Thanh toán Kỳ 3 (2.620.000 đ)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
