import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/bill_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';
import 'package:sen_hong_bank/presentation/widgets/app_bar_seam_fade.dart';

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTabIdx = 0;
  bool _autoDebitEnabled = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _recentPaidBills = [];

  List<Map<String, dynamic>> _savedBills = [
    {
      'label': 'Điện Nhà Riêng (Hà Nội)',
      'service': 'Tiền điện EVN',
      'provider': 'EVN Hà Nội',
      'code': 'PE0100088921',
      'amount': 845000.0,
      'icon': LucideIcons.zap,
      'dueDate': '10/09/2026',
    },
    {
      'label': 'Nước Sinh Hoạt Chung Cư',
      'service': 'Tiền nước sinh hoạt',
      'provider': 'Viwaco Hà Nội',
      'code': '100293847',
      'amount': 165000.0,
      'icon': LucideIcons.droplets,
      'dueDate': '05/09/2026',
    },
    {
      'label': 'Cáp Quang FPT Gia Đình',
      'service': 'Internet cáp quang',
      'provider': 'FPT Telecom',
      'code': 'HNI002941',
      'amount': 275000.0,
      'icon': LucideIcons.wifi,
      'dueDate': '15/09/2026',
    },
  ];

  final List<Map<String, dynamic>> _essentialCategories = const [
    {
      'icon': LucideIcons.zap,
      'label': 'Tiền điện',
      'ncc': 'EVN Toàn quốc',
    },
    {
      'icon': LucideIcons.droplets,
      'label': 'Tiền nước',
      'ncc': 'Sawaco / Viwaco',
    },
    {
      'icon': LucideIcons.wifi,
      'label': 'Internet',
      'ncc': 'VNPT / FPT / Viettel',
    },
    {
      'icon': LucideIcons.smartphone,
      'label': 'Nạp ĐT',
      'ncc': 'Trả trước & Trả sau',
    },
    {
      'icon': LucideIcons.tv,
      'label': 'Truyền hình',
      'ncc': 'K+ / VTVCab / FPT Play',
    },
    {
      'icon': LucideIcons.building2,
      'label': 'Phí chung cư',
      'ncc': 'BQL Tòa nhà',
    },
  ];

  final List<Map<String, dynamic>> _financeCategories = const [
    {
      'icon': LucideIcons.handCoins,
      'label': 'Vay tiêu dùng',
      'ncc': 'FE Credit, Home Credit, Shinhan',
    },
    {
      'icon': LucideIcons.creditCard,
      'label': 'Thẻ tín dụng',
      'ncc': 'Dư nợ Visa / Mastercard',
    },
    {
      'icon': LucideIcons.shieldCheck,
      'label': 'Bảo hiểm',
      'ncc': 'Bảo Việt, Prudential, Manulife',
    },
    {
      'icon': LucideIcons.car,
      'label': 'Thu phí ETC',
      'ncc': 'VETC & ePass tự động',
    },
  ];

  final List<Map<String, dynamic>> _publicCategories = const [
    {
      'icon': LucideIcons.fileText,
      'label': 'Thuế & Lệ phí',
      'ncc': 'Thuế TNCN, Trước bạ xe',
    },
    {
      'icon': LucideIcons.graduationCap,
      'label': 'Học phí SSC',
      'ncc': 'Trường học các cấp & ĐH',
    },
    {
      'icon': LucideIcons.heartPulse,
      'label': 'Viện phí y tế',
      'ncc': 'Bệnh viện Bạch Mai, Chợ Rẫy',
    },
    {
      'icon': LucideIcons.ticket,
      'label': 'Vé tàu / Xe',
      'ncc': 'Đường sắt VN & Xe khách',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBillData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBillData() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final txs = await TransactionRemoteDataSource().getTransactions(
        walletId: wallet.walletId,
        type: 'BILL',
        size: 5,
      );
      if (!mounted) return;

      // Nạp danh sách hóa đơn ủy thác trích nợ tự động thực tế từ Backend
      try {
        final subs = await BillRemoteDataSource().getSubscriptions();
        if (subs.isNotEmpty && mounted) {
          _savedBills = subs.map((s) {
            final billType = (s['billType'] ?? '').toString();
            IconData icon = LucideIcons.receipt;
            String serviceName = 'Hóa đơn dịch vụ';
            if (billType.contains('ELEC')) {
              icon = LucideIcons.zap;
              serviceName = 'Tiền điện sinh hoạt';
            } else if (billType.contains('WATER')) {
              icon = LucideIcons.droplets;
              serviceName = 'Tiền nước sinh hoạt';
            } else if (billType.contains('INTERNET')) {
              icon = LucideIcons.wifi;
              serviceName = 'Internet & Truyền hình';
            }
            return {
              'id': s['id']?.toString() ?? '',
              'label': '${s['providerCode'] ?? ''} - ${s['customerCode'] ?? ''}',
              'service': serviceName,
              'provider': s['providerCode']?.toString() ?? 'Nhà cung cấp',
              'code': s['customerCode']?.toString() ?? '',
              'amount': (s['lastAmount'] as num?)?.toDouble() ?? 0.0,
              'icon': icon,
              'dueDate': 'Ngày ${s['autoDebitDay'] ?? 5} hàng tháng',
              'autoDebit': s['active'] ?? true,
            };
          }).toList();
        }
      } catch (_) {}

      setState(() {
        _recentPaidBills = txs.map((tx) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final timeStr = tx['createdAt'] as String? ?? '';
          final desc = tx['description'] as String? ?? 'Thanh toán hóa đơn';
          return {
            'service': desc,
            'provider': 'Hệ thống Sen Hồng',
            'code': tx['referenceCode'] ?? tx['id']?.toString() ?? '',
            'amount': amt,
            'date': timeStr.length >= 10 ? timeStr.substring(0, 10) : timeStr,
            'status': 'Đã thanh toán',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payBill(Map<String, dynamic> bill) async {
    if (!BackendCapabilities.bills) {
      await showFeatureUnavailable(
        context,
        feature: 'Thanh toán hóa đơn',
        reason: 'Backend chưa cung cấp API hóa đơn (BE-REQ-06).',
      );
      return;
    }
    HapticFeedback.selectionClick();
    final billId = (bill['id'] ?? bill['billId'] ?? bill['code'] ?? '').toString();
    final uri = Uri(
      path: '/bills/confirm',
      queryParameters: {
        if (billId.isNotEmpty) 'billId': billId,
        'service': bill['service'] as String?,
        'provider': bill['provider'] as String?,
        'code': bill['code'] as String?,
        'amount': bill['amount'].toString(),
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: const Text(
          'Thanh Toán Hóa Đơn',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: const Color(0xFFFFFDF9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
        flexibleSpace: const AppBarSeamFade(),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBillData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Promo Cashback Minimalist Banner
                _buildCashbackBanner(),
                const SizedBox(height: 22),

                // 2. Saved Bill Templates with 1-Tap Pay
                _buildSavedBillsSection(),
                const SizedBox(height: 22),

                // 3. Auto-Debit Switch Card
                _buildAutoDebitCard(),
                const SizedBox(height: 24),

                // 4. Categorized Service Grid with 3 Tabs
                _buildCategoryTabsSection(),
                const SizedBox(height: 24),

                // 5. Monthly Bill Spending Analysis Chart
                _buildSpendingAnalysisSection(),
                const SizedBox(height: 22),

                // 6. Smart Bill Reminder Calendar
                _buildBillReminderCalendar(),
                const SizedBox(height: 22),

                // 7. Recent Paid Bills Log
                _buildRecentPaidBillsLog(),
                const SizedBox(height: 20),

                // 8. Zero-Fee Commitment Footer
                _buildZeroFeeNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashbackBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            LucideIcons.sparkles,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOÀN TIỀN 5% HÓA ĐƠN GIA ĐÌNH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Nhập mã SENHONG5 nhận hoàn tiền ngay 50.000đ khi thanh toán tiền điện, nước & internet.',
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedBillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Danh bạ hóa đơn của tôi',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_savedBills.length} mẫu đã lưu',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _savedBills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, idx) {
            final bill = _savedBills[idx];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _payBill(bill),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      // Bare Icon nét đơn màu #616161 size 22
                      Icon(
                        bill['icon'] as IconData,
                        size: 22,
                        color: const Color(0xFF616161),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill['label'] as String,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${bill['provider']} • ${bill['code']}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hạn cước: ${bill['dueDate']}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatVND(
                                (bill['amount'] as num?)?.toDouble() ?? 0.0),
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.06),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              'Thanh toán',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAutoDebitCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.repeat,
            size: 22,
            color: Color(0xFF616161),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trích nợ tự động (Auto-Debit)',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tự động trừ tiền khi có cước mới, không lo trễ hạn',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _autoDebitEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _autoDebitEnabled = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.emeraldGreen,
                  content: Text(v
                      ? 'Đã bật tính năng trích nợ tự động hàng tháng'
                      : 'Đã tắt trích nợ tự động'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục dịch vụ thanh toán',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (idx) {
              HapticFeedback.selectionClick();
              setState(() => _selectedTabIdx = idx);
            },
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            labelColor: const Color(0xFF111827),
            unselectedLabelColor: const Color(0xFF6B7280),
            labelStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Thiết yếu'),
              Tab(text: 'Tài chính & Thẻ'),
              Tab(text: 'Dịch vụ công'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedTabIdx),
            child: _selectedTabIdx == 0
                ? _buildCategoryGrid(_essentialCategories)
                : (_selectedTabIdx == 1
                    ? _buildCategoryGrid(_financeCategories)
                    : _buildCategoryGrid(_publicCategories)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final cat = items[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (cat['label'] == 'Nạp ĐT') {
                context.push('/bills/phone-recharge');
              } else {
                context.push('/bills/input?service=${cat['label']}');
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withOpacity(0.06),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 22,
                    color: const Color(0xFF616161),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat['ncc'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpendingAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.barChart3,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phân Tích Chi Tiêu Hóa Đơn 3 Tháng',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                'TB: 1.450.000 đ/tháng',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMonthSpendingBar('Tháng 06/2026', 1250000, 0.72),
          const SizedBox(height: 8),
          _buildMonthSpendingBar('Tháng 07/2026', 1680000, 0.95),
          const SizedBox(height: 8),
          _buildMonthSpendingBar('Tháng 08/2026', 1420000, 0.82),
        ],
      ),
    );
  }

  Widget _buildMonthSpendingBar(String month, double amount, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            month,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            CurrencyFormatter.formatVND(amount),
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillReminderCalendar() {
    final reminders = [
      {
        'day': '05',
        'title': 'Tiền Nước Sinh Hoạt',
        'status': 'Đã thanh toán',
        'isDone': true
      },
      {
        'day': '10',
        'title': 'Tiền Điện Lực EVN',
        'status': 'Sắp đến hạn',
        'isDone': false
      },
      {
        'day': '15',
        'title': 'Internet & Truyền Hình',
        'status': 'Đang chờ cước',
        'isDone': false
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch nhắc cước định kỳ',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: reminders.map((r) {
            final isDone = r['isDone'] as bool;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF059669).withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ngày ${r['day']}',
                      style: TextStyle(
                        color: isDone
                            ? const Color(0xFF059669)
                            : const Color(0xFF1F2937),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r['status'] as String,
                      style: TextStyle(
                        color: isDone
                            ? const Color(0xFF059669)
                            : const Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentPaidBillsLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hóa đơn đã thanh toán gần đây',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF616161),
              ),
            ),
          )
        else if (_recentPaidBills.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
            ),
            child: const Center(
              child: Text(
                'Chưa có lịch sử thanh toán hóa đơn trong tháng này.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
              ),
            ),
          )
        else
          ..._recentPaidBills.map((item) {
            return Material(
              color: Colors.transparent,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.checkCircle2,
                      size: 22,
                      color: Color(0xFF616161),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['service'] as String,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['provider']} • ${item['code']} • ${item['date']}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatVND(
                              (item['amount'] as num?)?.toDouble() ?? 0.0),
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Thành công',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildZeroFeeNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
          width: 0.5,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            LucideIcons.shieldCheck,
            color: Color(0xFF616161),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'SenBank miễn 100% phí xử lý thanh toán mọi loại hóa đơn gia đình. Hóa đơn được gạch nợ tức thì với EVN, Sawaco và các nhà mạng viễn thông.',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
