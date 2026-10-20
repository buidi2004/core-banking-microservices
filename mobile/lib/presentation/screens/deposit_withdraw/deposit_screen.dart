import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountCtrl =
      TextEditingController(text: '500000');
  int _selectedSource = 0;
  int _selectedDepositMethod = 0; // 0: Thẻ liên kết, 1: VietQR Napas, 2: Cây CDM 24/7
  bool _isLoading = true;
  bool _isSubmitting = false;

  final double _dailyLimit = 50000000;
  final double _usedLimitToday = 10000000;

  final List<double> _quickAmounts = [
    100000,
    200000,
    500000,
    1000000,
    2000000,
    5000000
  ];

  List<Map<String, String>> _sources = [
    {
      'bank': 'Vietcombank',
      'num': '*8899',
      'type': 'Tài khoản liên kết chính chủ (Miễn phí)',
      'logo': 'VCB',
    },
  ];

  List<Map<String, dynamic>> _recentDeposits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Nạp danh sách tài khoản ngân hàng liên kết thật
      try {
        final accounts = await BankAccountRemoteDataSource().getAccounts();
        if (accounts.isNotEmpty && mounted) {
          final mapped = <Map<String, String>>[];
          for (final acc in accounts) {
            final bankCode = acc['bankCode']?.toString() ?? 'NGANHANG';
            final accNum = acc['accountNumber']?.toString() ?? '';
            final masked = accNum.length > 4
                ? '*${accNum.substring(accNum.length - 4)}'
                : accNum;
            mapped.add({
              'bank': bankCode,
              'num': masked,
              'type': 'Tài khoản liên kết chính chủ (Miễn phí)',
              'logo': bankCode.length > 4
                  ? bankCode.substring(0, 4).toUpperCase()
                  : bankCode.toUpperCase(),
            });
          }
          setState(() {
            _sources = mapped;
          });
        }
      } catch (_) {}

      // 2. Nạp lịch sử nạp gần nhất thực tế
      try {
        final wallet = await WalletRemoteDataSource().getMyWallet();
        final txs = await TransactionRemoteDataSource().getTransactions(
          walletId: wallet.walletId,
          type: 'DEPOSIT',
          size: 5,
        );
        if (mounted) {
          setState(() {
            _recentDeposits = txs.map((tx) {
              final bankName =
                  tx['bankCode']?.toString() ?? 'Ngân hàng liên kết';
              final acc = tx['counterpartyAccount']?.toString() ?? '';
              final maskedAcc =
                  acc.length > 4 ? '(*${acc.substring(acc.length - 4)})' : acc;
              return {
                'bank':
                    maskedAcc.isNotEmpty ? '$bankName $maskedAcc' : bankName,
                'amount': ((tx['amount'] as num?)?.toDouble() ?? 0.0).abs(),
                'time': tx['date']?.toString() ?? 'Gần đây',
                'status': 'Nạp thành công',
              };
            }).toList();
          });
        }
      } catch (_) {}

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingLimit = (_dailyLimit - _usedLimitToday).clamp(0.0, _dailyLimit);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nạp Tiền Vào Ví'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Daily Limit Gauge Card
              _buildDailyLimitCard(remainingLimit),
              const SizedBox(height: 18),

              // 2. Deposit Methods Selector (3 Methods)
              _buildDepositMethodSelector(),
              const SizedBox(height: 20),

              // Method-specific Content
              if (_selectedDepositMethod == 0) ...[
                // Method 1: Nạp từ Ngân hàng liên kết
                _buildAmountInputCard(),
                const SizedBox(height: 20),
                _buildSourcesSection(),
                const SizedBox(height: 22),
                _buildSubmitButton(),
              ] else if (_selectedDepositMethod == 1) ...[
                // Method 2: Nạp qua VietQR Napas 24/7
                _buildVietQrDepositCard(),
              ] else ...[
                // Method 3: Nạp tiền mặt tại cây CDM 24/7
                _buildCdmDepositCard(),
              ],

              const SizedBox(height: 24),

              // 3. Rewards Banner
              _buildDepositRewardBanner(),
              const SizedBox(height: 22),

              // 4. Policy & Zero Fee Table
              _buildFeePolicyTable(),
              const SizedBox(height: 22),

              // 5. Recent Deposits Log
              _buildRecentDepositsLog(),
              const SizedBox(height: 20),

              // 6. Security Notice
              _buildSecurityNotice(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDailyLimitCard(double remainingLimit) {
    final progress = (_usedLimitToday / _dailyLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.checkmark_shield_fill,
                      color: AppColors.emeraldGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'HẠN MỨC NẠP TIỀN TRONG NGÀY',
                    style: TextStyle(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'Còn: ${CurrencyFormatter.formatVND(remainingLimit)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.emeraldGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã nạp: 10.000.000 đ',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                'Tối đa: 50.000.000 đ/ngày',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepositMethodSelector() {
    final methods = [
      {
        'title': 'Thẻ Liên Kết',
        'sub': '1-Chạm tức thì',
        'icon': CupertinoIcons.creditcard_fill,
      },
      {
        'title': 'Mã VietQR 24/7',
        'sub': 'Từ mọi app ngân hàng',
        'icon': CupertinoIcons.qrcode_viewfinder,
      },
      {
        'title': 'Cây CDM 24/7',
        'sub': 'Nộp tiền mặt tự động',
        'icon': CupertinoIcons.building_2_fill,
      },
    ];

    return Row(
      children: List.generate(methods.length, (idx) {
        final isSelected = _selectedDepositMethod == idx;
        final m = methods[idx];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDepositMethod = idx);
            },
            child: Container(
              margin: EdgeInsets.only(
                left: idx == 0 ? 0 : 4,
                right: idx == methods.length - 1 ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.bottomBarCyan.withValues(alpha: 0.2)
                    : const Color(0xFF0C1929).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.bottomBarCyan
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(m['icon'] as IconData,
                      color: isSelected
                          ? AppColors.bottomBarCyan
                          : Colors.white60,
                      size: 22),
                  const SizedBox(height: 6),
                  Text(
                    m['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m['sub'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? AppColors.bottomBarCyan : Colors.white38,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAmountInputCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số tiền cần nạp',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                suffixIcon: _amountCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid,
                            color: Colors.white38, size: 20),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _amountCtrl.clear());
                        },
                      )
                    : null,
                suffixText: ' đ',
                suffixStyle: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.bottomBarCyan, width: 1.5),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _amountCtrl,
              builder: (context, value, _) {
                final amt = double.tryParse(value.text) ?? 0;
                final words = CurrencyFormatter.toVietnameseWords(amt);
                if (words.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Bằng chữ: $words đồng',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amt) {
                return ActionChip(
                  label: Text(
                    CurrencyFormatter.formatVND(amt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: const Color(0xFF132A48).withValues(alpha: 0.6),
                  side: BorderSide(
                      color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _amountCtrl.text = amt.toInt().toString());
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chọn tài khoản nguồn tiền',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/bank-cards'),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.plus_circle,
                      color: AppColors.bottomBarCyan, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Thêm liên kết',
                    style: TextStyle(
                      color: AppColors.bottomBarCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_sources.length, (idx) {
          final s = _sources[idx];
          final isSelected = _selectedSource == idx;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.bottomBarCyan, width: 1.8)
                  : null,
            ),
            child: GlassCard(
              quality: GlassQuality.minimal,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSource = idx);
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        s['logo']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    '${s['bank']} (${s['num']})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    s['type']!,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                  trailing: Icon(
                    isSelected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: isSelected
                        ? AppColors.bottomBarCyan
                        : Colors.white24,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        onPressed: _isSubmitting
            ? null
            : () async {
                final amt = double.tryParse(_amountCtrl.text) ?? 0;
                if (amt < 10000) {
                  HapticFeedback.vibrate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số tiền nạp tối thiểu là 10.000đ'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (amt > 50000000) {
                  HapticFeedback.vibrate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số tiền nạp vượt quá hạn mức tối đa trong ngày (50.000.000đ)'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                setState(() => _isSubmitting = true);
                HapticFeedback.mediumImpact();

                final source = _sources.isNotEmpty
                    ? _sources[_selectedSource]['bank']!
                    : 'Ngân hàng liên kết';
                final uri = Uri(
                  path: '/deposit/confirm',
                  queryParameters: {
                    'amount': amt.toString(),
                    'source': source,
                  },
                );
                await context.push(uri.toString());
                if (mounted) setState(() => _isSubmitting = false);
              },
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text(
                'Tiếp tục xác nhận nạp tiền',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildVietQrDepositCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Text(
            'Nạp Tiền Bằng Chuyển Khoản VietQR 24/7',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mở bất kỳ ứng dụng ngân hàng nào (Techcombank, Vietinbank, MB, ACB...) quét mã QR dưới đây để tiền về ví ngay tức thì.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(CupertinoIcons.qrcode,
                size: 160, color: Color(0xFF030B17)),
          ),
          const SizedBox(height: 16),
          _buildCopyRow('Ngân hàng thụ hưởng', 'SenBank (NH Số Sen Hồng)'),
          const Divider(color: Colors.white10),
          _buildCopyRow('Số tài khoản ảo', '9988 2026 8888'),
          const Divider(color: Colors.white10),
          _buildCopyRow('Tên người thụ hưởng', 'SENBANK - VÍ ĐIỆN TỬ'),
          const Divider(color: Colors.white10),
          _buildCopyRow('Nội dung chuyển khoản', 'NAP SEN 0912345678'),
        ],
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.emeraldGreen,
                    content: Text('Đã sao chép "$value"!'),
                  ),
                );
              },
              child: const Icon(CupertinoIcons.doc_on_clipboard,
                  color: AppColors.bottomBarCyan, size: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCdmDepositCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.building_2_fill,
                  color: AppColors.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Mạng Lưới Nộp Tiền Mặt Tự Động (CDM 24/7)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Quý khách có thể nộp tiền mặt trực tiếp vào ví SenBank tại các máy CDM 24/7 không cần chờ giờ làm việc:',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          _buildCdmItem(
            'CDM Hoàn Kiếm 24/7',
            'Số 22 Phố Hàng Bài, Q. Hoàn Kiếm, Hà Nội (Cách 1.2 km)',
          ),
          const SizedBox(height: 8),
          _buildCdmItem(
            'CDM Sen Hồng Tower',
            'Tầng 1 Tòa nhà Sen Hồng, 54 Liễu Giai, Ba Đình, Hà Nội',
          ),
          const SizedBox(height: 8),
          _buildCdmItem(
            'CDM Bến Thành Sài Gòn',
            '128 Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
          ),
        ],
      ),
    );
  }

  Widget _buildCdmItem(String name, String address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.location_solid,
              color: AppColors.accentGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  address,
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositRewardBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF132A48), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.sparkles, color: AppColors.accentGold, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TÍCH ĐIỂM SENPOINTS KHI NẠP TỪ 500.000Đ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nhận ngay 500 SenPoints đổi voucher Highland Coffee, vé xem phim CGV.',
                  style: TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeePolicyTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chính Sách Biểu Phí & Thời Gian Xử Lý',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildPolicyRow('Phí nạp tiền từ ngân hàng', '0 đ (Miễn phí 100%)',
              AppColors.emeraldGreen),
          const Divider(color: Colors.white10),
          _buildPolicyRow(
              'Thời gian ghi có số dư', 'Tức thì (< 3 giây)', AppColors.bottomBarCyan),
          const Divider(color: Colors.white10),
          _buildPolicyRow('Số tiền nạp tối thiểu', '10.000 đ / giao dịch', Colors.white),
          const Divider(color: Colors.white10),
          _buildPolicyRow('Số tiền nạp tối đa', '50.000.000 đ / ngày', Colors.white),
        ],
      ),
    );
  }

  Widget _buildPolicyRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDepositsLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch Sử Nạp Tiền Gần Đây',
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
        else if (_recentDeposits.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: const Center(
              child: Text(
                'Chưa có lịch sử nạp tiền gần đây.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          )
        else
          ..._recentDeposits.map((item) {
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
                        child: const Icon(CupertinoIcons.arrow_down_circle_fill,
                            color: AppColors.emeraldGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['bank'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              item['time'] as String,
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
                            '+${CurrencyFormatter.formatVND(item['amount'] as double)}',
                            style: const TextStyle(
                              color: AppColors.emeraldGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const Text(
                            'Thành công',
                            style: TextStyle(
                              color: AppColors.emeraldGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.info_circle_fill,
              color: AppColors.bottomBarCyan, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nạp tiền từ tài khoản ngân hàng liên kết hoàn toàn miễn phí. Chỉ áp dụng nạp từ tài khoản ngân hàng chính chủ trùng khớp họ tên với CCCD đã xác thực eKYC.',
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
