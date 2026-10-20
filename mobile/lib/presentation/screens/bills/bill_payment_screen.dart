import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';

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

  final List<Map<String, dynamic>> _savedBills = [
    {
      'label': 'Điện Nhà Riêng (Hà Nội)',
      'service': 'Tiền điện EVN',
      'provider': 'EVN Hà Nội',
      'code': 'PE0100088921',
      'amount': 845000.0,
      'color': AppColors.accentGold,
      'icon': CupertinoIcons.bolt_fill,
      'dueDate': '10/09/2026',
    },
    {
      'label': 'Nước Sinh Hoạt Chung Cư',
      'service': 'Tiền nước sinh hoạt',
      'provider': 'Viwaco Hà Nội',
      'code': '100293847',
      'amount': 165000.0,
      'color': AppColors.primary,
      'icon': CupertinoIcons.drop_fill,
      'dueDate': '05/09/2026',
    },
    {
      'label': 'Cáp Quang FPT Gia Đình',
      'service': 'Internet cáp quang',
      'provider': 'FPT Telecom',
      'code': 'HNI002941',
      'amount': 275000.0,
      'color': AppColors.emeraldGreen,
      'icon': CupertinoIcons.wifi,
      'dueDate': '15/09/2026',
    },
  ];

  final List<Map<String, dynamic>> _essentialCategories = const [
    {'icon': CupertinoIcons.bolt_fill, 'label': 'Tiền điện', 'color': AppColors.accentGold, 'ncc': 'EVN Toàn quốc'},
    {'icon': CupertinoIcons.drop_fill, 'label': 'Tiền nước', 'color': AppColors.primary, 'ncc': 'Sawaco / Viwaco'},
    {'icon': CupertinoIcons.wifi, 'label': 'Internet', 'color': AppColors.emeraldGreen, 'ncc': 'VNPT / FPT / Viettel'},
    {'icon': CupertinoIcons.phone_fill, 'label': 'Nạp ĐT', 'color': AppColors.bottomBarCyan, 'ncc': 'Trả trước & Trả sau'},
    {'icon': CupertinoIcons.tv_fill, 'label': 'Truyền hình', 'color': AppColors.softPurple, 'ncc': 'K+ / VTVCab / FPT Play'},
    {'icon': CupertinoIcons.building_2_fill, 'label': 'Phí chung cư', 'color': AppColors.vividTeal, 'ncc': 'BQL Tòa nhà'},
  ];

  final List<Map<String, dynamic>> _financeCategories = const [
    {'icon': CupertinoIcons.money_dollar_circle_fill, 'label': 'Vay tiêu dùng', 'color': AppColors.accentGold, 'ncc': 'FE Credit, Home Credit, Shinhan'},
    {'icon': CupertinoIcons.creditcard_fill, 'label': 'Thẻ tín dụng', 'color': AppColors.bottomBarCyan, 'ncc': 'Dư nợ Visa / Mastercard'},
    {'icon': CupertinoIcons.shield_fill, 'label': 'Bảo hiểm', 'color': AppColors.emeraldGreen, 'ncc': 'Bảo Việt, Prudential, Manulife'},
    {'icon': CupertinoIcons.car_detailed, 'label': 'Thu phí ETC', 'color': AppColors.primary, 'ncc': 'VETC & ePass tự động'},
  ];

  final List<Map<String, dynamic>> _publicCategories = const [
    {'icon': CupertinoIcons.doc_text_fill, 'label': 'Thuế & Lệ phí', 'color': AppColors.accentGold, 'ncc': 'Thuế TNCN, Trước bạ xe'},
    {'icon': CupertinoIcons.book_fill, 'label': 'Học phí SSC', 'color': AppColors.primary, 'ncc': 'Trường học các cấp & ĐH'},
    {'icon': CupertinoIcons.bandage_fill, 'label': 'Viện phí y tế', 'color': AppColors.emeraldGreen, 'ncc': 'Bệnh viện Bạch Mai, Chợ Rẫy'},
    {'icon': CupertinoIcons.tickets_fill, 'label': 'Vé tàu / Xe', 'color': AppColors.bottomBarCyan, 'ncc': 'Đường sắt VN & Xe khách'},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Thanh Toán Hóa Đơn'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBillData,
          color: AppColors.bottomBarCyan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Promo Cashback 3D Banner
                _buildCashbackBanner(),
                const SizedBox(height: 20),

                // 2. Saved Bill Templates with 1-Tap Pay
                _buildSavedBillsSection(),
                const SizedBox(height: 22),

                // 3. Auto-Debit Switch Card
                _buildAutoDebitCard(),
                const SizedBox(height: 22),

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF132A48), Color(0xFF0C1929), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentGold, width: 1.5),
            ),
            child: const Icon(CupertinoIcons.ticket_fill,
                color: AppColors.accentGold, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOÀN TIỀN 5% HÓA ĐƠN GIA ĐÌNH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Nhập mã SENHONG5 nhận hoàn tiền ngay 50.000đ khi thanh toán tiền điện, nước & internet.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.bookmark_fill,
                    color: AppColors.accentGold, size: 16),
                SizedBox(width: 6),
                Text(
                  'Danh Bạ Hóa Đơn Của Tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
            Text(
              '${_savedBills.length} Mẫu đã lưu',
              style: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._savedBills.map((bill) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (bill['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(bill['icon'] as IconData,
                          color: bill['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${bill['provider']} • ${bill['code']}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                          Text(
                            'Hạn cước: ${bill['dueDate']}',
                            style: const TextStyle(
                                color: AppColors.accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatVND(
                              bill['amount'] as double),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final uri = Uri(
                              path: '/bills/confirm',
                              queryParameters: {
                                'service': bill['service'] as String?,
                                'provider': bill['provider'] as String?,
                                'code': bill['code'] as String?,
                                'amount': bill['amount'].toString(),
                              },
                            );
                            context.push(uri.toString());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Thanh toán',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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
        }),
      ],
    );
  }

  Widget _buildAutoDebitCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.arrow_2_circlepath_circle_fill,
                  color: AppColors.emeraldGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trích Nợ Tự Động (Auto-Debit)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tự động trừ tiền khi nhà cung cấp phát hành cước mới, không lo trễ hạn',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _autoDebitEnabled,
              activeTrackColor: AppColors.bottomBarCyan,
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
      ),
    );
  }

  Widget _buildCategoryTabsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh Mục Dịch Vụ Thanh Toán',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0C1929).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (idx) {
              HapticFeedback.selectionClick();
              setState(() => _selectedTabIdx = idx);
            },
            indicator: BoxDecoration(
              color: AppColors.bottomBarCyan.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.bottomBarCyan),
            ),
            labelColor: AppColors.bottomBarCyan,
            unselectedLabelColor: Colors.white54,
            labelStyle:
                const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Thiết Yếu'),
              Tab(text: 'Tài Chính & Thẻ'),
              Tab(text: 'Dịch Vụ Công'),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
        return GlassCard(
          quality: GlassQuality.minimal,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (cat['label'] == 'Nạp ĐT') {
                context.push('/bills/phone-recharge');
              } else {
                context.push('/bills/input?service=${cat['label']}');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat['icon'] as IconData,
                        color: cat['color'] as Color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat['ncc'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white54),
                        ),
                      ],
                    ),
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
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.chart_bar_alt_fill,
                      color: AppColors.bottomBarCyan, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Phân Tích Chi Tiêu Hóa Đơn 3 Tháng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              Text(
                'TB: 1.450.000 đ/tháng',
                style: TextStyle(color: AppColors.accentGold, fontSize: 11),
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
          child: Text(month,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.bottomBarCyan),
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
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillReminderCalendar() {
    final reminders = [
      {'day': '05', 'title': 'Tiền Nước Sinh Hoạt', 'status': 'Đã thanh toán', 'isDone': true},
      {'day': '10', 'title': 'Tiền Điện Lực EVN', 'status': 'Sắp đến hạn', 'isDone': false},
      {'day': '15', 'title': 'Internet & Truyền Hình', 'status': 'Đang chờ cước', 'isDone': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch Nhắc Cước Định Kỳ Tháng Này',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
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
                  color: isDone
                      ? AppColors.emeraldGreen.withValues(alpha: 0.12)
                      : const Color(0xFF132A48).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone
                        ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ngày ${r['day']}',
                      style: TextStyle(
                        color: isDone
                            ? AppColors.emeraldGreen
                            : AppColors.bottomBarCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r['status'] as String,
                      style: TextStyle(
                        color: isDone ? AppColors.emeraldGreen : Colors.white54,
                        fontSize: 9.5,
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
          'Hóa Đơn Đã Thanh Toán Gần Đây',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.bottomBarCyan)),
          )
        else if (_recentPaidBills.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Center(
              child: Text(
                'Chưa có lịch sử thanh toán hóa đơn trong tháng này.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          )
        else
          ..._recentPaidBills.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(CupertinoIcons.checkmark_seal_fill,
                            color: AppColors.emeraldGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['service'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              '${item['provider']} • ${item['code']} • ${item['date']}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const Text(
                            'Thành công',
                            style: TextStyle(
                                color: AppColors.emeraldGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.checkmark_shield_fill,
              color: AppColors.emeraldGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'SenBank miễn 100% phí xử lý thanh toán mọi loại hóa đơn gia đình. Hóa đơn được gạch nợ tức thì với EVN, Sawaco và các nhà mạng viễn thông.',
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
