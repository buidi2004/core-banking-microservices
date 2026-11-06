import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/loan_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';

class LoanScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? loanData;

  const LoanScheduleScreen({super.key, this.loanData});

  @override
  State<LoanScheduleScreen> createState() => _LoanScheduleScreenState();
}

class _LoanScheduleScreenState extends State<LoanScheduleScreen> {
  bool _autoDebit = true;
  bool _isPaying = false;
  bool _isLoading = false;
  String? _effectiveLoanId;

  String _contractNumber = 'HDTD-2026-88391';
  String _productName = 'Vay Tiêu Dùng Nhanh SenBank';
  double _totalLoan = 15000000;
  int _totalTerms = 6;
  final double _interestRatePerMonth = 1.2; // 1.2%/thang

  // 6 ky tra no theo du no giam dan
  List<Map<String, dynamic>> _schedule = [
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

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      String? loanId = widget.loanData?['id']?.toString() ??
          widget.loanData?['loanId']?.toString();
      if (loanId == null || loanId.isEmpty) {
        final loans = await LoanRemoteDataSource().getUserLoans();
        if (loans.isNotEmpty) {
          final active = loans.firstWhere(
            (l) => l['status'] == 'DISBURSED' || l['status'] == 'ACTIVE',
            orElse: () => loans.first,
          );
          loanId = active['id']?.toString() ?? active['loanId']?.toString();
          if (active['contractNumber'] != null) {
            _contractNumber = active['contractNumber'].toString();
          }
          if (active['productType'] != null) {
            _productName = active['productType'] == 'VAY_TIEU_DUNG_NHANH'
                ? 'Vay Tiêu Dùng Nhanh SenBank'
                : active['productType'].toString();
          }
        }
      }

      if (loanId != null && loanId.isNotEmpty) {
        _effectiveLoanId = loanId;
        final res = await LoanRemoteDataSource().getLoanSchedule(loanId);
        if (mounted) {
          setState(() {
            if (res['contractNumber'] != null) {
              _contractNumber = res['contractNumber'].toString();
            }
            if (res['principalAmount'] != null) {
              _totalLoan = (res['principalAmount'] as num).toDouble();
            }
            if (res['termMonths'] != null) {
              _totalTerms = (res['termMonths'] as num).toInt();
            }
            final rawItems = res['schedule'] as List?;
            if (rawItems != null && rawItems.isNotEmpty) {
              _schedule = rawItems.map((item) {
                final m = Map<String, dynamic>.from(item as Map);
                return {
                  'term': (m['termNumber'] ?? m['term'] as num?)?.toInt() ?? 1,
                  'dueDate': m['dueDate']?.toString() ?? '',
                  'principal': (m['principalAmount'] ?? m['principal'] as num?)
                          ?.toDouble() ??
                      0.0,
                  'interest': (m['interestAmount'] ?? m['interest'] as num?)
                          ?.toDouble() ??
                      0.0,
                  'total':
                      (m['totalAmount'] ?? m['total'] as num?)?.toDouble() ??
                          0.0,
                  'remaining': (m['remainingBalance'] ?? m['remaining'] as num?)
                          ?.toDouble() ??
                      0.0,
                  'status': m['status']?.toString() ?? 'UPCOMING',
                  'paidDate': m['paidDate']?.toString(),
                };
              }).toList();
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Keep existing default preview schedule on error or offline
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _payCurrentTerm() {
    HapticFeedback.heavyImpact();
    final dueTerm = _schedule.firstWhere(
      (item) => item['status'] == 'DUE',
      orElse: () => _schedule[2],
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.deepNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.creditcard_fill,
                color: AppColors.bottomBarCyan, size: 24),
            const SizedBox(width: 10),
            Text(
              'Thanh toán Kỳ ${dueTerm['term']}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận trích tiền từ Ví SenBank để thanh toán kỳ hạn ngày ${dueTerm['dueDate']}.',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.3),
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
                      const Text('Gốc kỳ này:',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(
                          CurrencyFormatter.formatVND(
                              dueTerm['principal'] as double),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lãi kỳ này:',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(
                          CurrencyFormatter.formatVND(
                              dueTerm['interest'] as double),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(
                        CurrencyFormatter.formatVND(dueTerm['total'] as double),
                        style: const TextStyle(
                            color: AppColors.bottomBarCyan,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
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
            child:
                const Text('Để sau', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bottomBarCyan,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (!BackendCapabilities.loans) {
                await showFeatureUnavailable(
                  context,
                  feature: 'Thanh toán kỳ vay',
                  reason: 'Hệ thống thanh toán khoản vay đang bảo trì.',
                );
                return;
              }
              setState(() => _isPaying = true);
              try {
                final loanId = _effectiveLoanId ??
                    widget.loanData?['id']?.toString() ??
                    widget.loanData?['loanId']?.toString();
                final termNum = (dueTerm['term'] as num?)?.toInt() ?? 1;
                final payAmount = (dueTerm['total'] as num?)?.toDouble();
                if (loanId != null && loanId.isNotEmpty) {
                  await LoanRemoteDataSource().repayTerm(
                    loanId,
                    termNumber: termNum,
                    amount: payAmount,
                  );
                  await _loadSchedule();
                } else {
                  setState(() {
                    dueTerm['status'] = 'PAID';
                    dueTerm['paidDate'] = 'Hôm nay';
                    if (_schedule.length > 3) {
                      _schedule[3]['status'] = 'DUE';
                    }
                  });
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_seal_fill,
                            color: AppColors.emeraldGreen, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Thanh toán Kỳ ${dueTerm['term']} thành công! Tiền đã được trích từ ví.',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(extractErrorMessage(e)),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                if (mounted) setState(() => _isPaying = false);
              }
            },
            child: const Text('Xác nhận thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettleEarlyDialog() {
    HapticFeedback.heavyImpact();
    double unpaidPrincipal = _schedule
        .where((item) => item['status'] != 'PAID')
        .fold(
            0.0,
            (sum, item) =>
                sum + ((item['principal'] as num?)?.toDouble() ?? 0.0));
    if (unpaidPrincipal <= 0) unpaidPrincipal = _totalLoan;
    final double earlyFee = unpaidPrincipal * 0.01;
    final double totalSettlement = unpaidPrincipal + earlyFee;

    bool isSettling = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.deepNavy,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(CupertinoIcons.checkmark_shield_fill,
                  color: AppColors.bottomBarCyan, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tất Toán Trước Hạn',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tất toán toàn bộ hợp đồng tín dụng và chấm dứt nghĩa vụ nợ. Phí tất toán 1% được áp dụng theo quy định của Ngân hàng Nhà nước.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dư nợ gốc còn lại:',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13)),
                        Text(CurrencyFormatter.formatVND(unpaidPrincipal),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phí phạt trước hạn (1%):',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13)),
                        Text(CurrencyFormatter.formatVND(earlyFee),
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán:',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(
                          CurrencyFormatter.formatVND(totalSettlement),
                          style: const TextStyle(
                              color: AppColors.bottomBarCyan,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
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
              onPressed: isSettling ? null : () => Navigator.pop(ctx),
              child:
                  const Text('Để sau', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bottomBarCyan,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isSettling
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => isSettling = true);
                      try {
                        final loanId = _effectiveLoanId ??
                            widget.loanData?['id']?.toString() ??
                            widget.loanData?['loanId']?.toString();
                        if (loanId != null && loanId.isNotEmpty) {
                          await LoanRemoteDataSource().settleLoanEarly(loanId);
                        }
                        if (mounted) {
                          setState(() {
                            for (var term in _schedule) {
                              term['status'] = 'PAID';
                              term['paidDate'] = 'Hôm nay';
                            }
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        if (messenger.mounted)
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(CupertinoIcons.checkmark_seal_fill,
                                      color: AppColors.emeraldGreen, size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tất toán khoản vay thành công! Bạn đã hoàn thành toàn bộ nghĩa vụ hợp đồng.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.primaryDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() => isSettling = false);
                        }
                        if (!messenger.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(extractErrorMessage(e)),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: isSettling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.primaryDark, strokeWidth: 2),
                    )
                  : const Text('Xác nhận Tất Toán',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _exportSchedulePdf() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.arrow_down_doc_fill,
                color: AppColors.bottomBarCyan, size: 20),
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
      backgroundColor: AppColors.inkNavy,
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
                if (_isLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.bottomBarCyan,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadSchedule,
                    color: AppColors.bottomBarCyan,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 20),
                        _buildBreakdownRatioCard(),
                        const SizedBox(height: 22),
                        _buildSectionHeader(
                            'BẢNG KHẤU HAO TỪNG KỲ (DƯ NỢ GIẢM DẦN)'),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        color: AppColors.bottomBarCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Điểm CIC: 720 (Hạng 1 Chuẩn Tốt)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.emeraldGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'ĐANG VAY',
                  style: TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Dư nợ gốc còn lại',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
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
                  style: TextStyle(
                      color: AppColors.bottomBarCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ],
            ),
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
                Expanded(
                  child: _buildMiniStat(
                      'Gốc ban đầu', CurrencyFormatter.formatVND(_totalLoan)),
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Expanded(
                  child: _buildMiniStat('Kỳ hạn', '$_totalTerms tháng'),
                ),
                Container(height: 24, width: 1, color: Colors.white12),
                Expanded(
                  child: _buildMiniStat(
                      'Lãi suất', '$_interestRatePerMonth%/tháng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(val,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cơ cấu khoản vay toàn kỳ',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đã trả: 2 / $_totalTerms kỳ (33.3%)',
                    style: const TextStyle(
                        color: AppColors.bottomBarCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
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
                      color: AppColors.bottomBarCyan,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Tổng gốc: 15.000.000 đ',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.bottomBarCyan,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Tổng lãi: 630.000 đ',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      badgeBg = AppColors.bottomBarCyan.withValues(alpha: 0.22);
      badgeText = AppColors.bottomBarCyan;
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
            : AppColors.deepNavy.withValues(alpha: 0.75),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDue
                            ? AppColors.bottomBarCyan
                            : Colors.white.withValues(alpha: 0.1),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kỳ hạn ngày $dueDate',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          Text(
                            'Dư nợ sau kỳ: ${CurrencyFormatter.formatVND(remaining)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeText, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                          color: badgeText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gốc: ${CurrencyFormatter.formatVND(principal)}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+ Lãi: ${CurrencyFormatter.formatVND(interest)}',
                    style: const TextStyle(
                        color: AppColors.bottomBarCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '= ${CurrencyFormatter.formatVND(total)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isPaying ? null : _payCurrentTerm,
                child: _isPaying
                    ? const CupertinoActivityIndicator(
                        color: AppColors.primaryDark)
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.creditcard, size: 18),
                            SizedBox(width: 8),
                            Text('Thanh toán kỳ này ngay',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
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
              child: const Icon(CupertinoIcons.arrow_2_squarepath,
                  color: AppColors.bottomBarCyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trích nợ tự động (Auto-Debit)',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tự động trừ ví vào ngày đến hạn để duy trì điểm CIC tốt',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12),
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
    final bool allPaid = _schedule.isNotEmpty &&
        _schedule.every((item) => item['status'] == 'PAID');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bottomBarCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(CupertinoIcons.info_circle_fill,
                  color: AppColors.bottomBarCyan, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  allPaid
                      ? 'Khoản vay đã được tất toán toàn bộ. Bạn không còn nghĩa vụ nợ nào cho hợp đồng này.'
                      : 'Chính sách trả nợ trước hạn: Phí phạt 1% theo quy định NHNN. Tiền lãi chỉ tính trên số ngày thực tế sử dụng vốn đến thời điểm tất toán.',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
          if (!allPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.bottomBarCyan,
                  side: const BorderSide(
                      color: AppColors.bottomBarCyan, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showSettleEarlyDialog,
                icon:
                    const Icon(CupertinoIcons.checkmark_shield_fill, size: 16),
                label: const Text(
                  'Tất toán toàn bộ khoản vay trước hạn',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ),
          ],
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _payCurrentTerm,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
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
      ),
    );
  }
}
