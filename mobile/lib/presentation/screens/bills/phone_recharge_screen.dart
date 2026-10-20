import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import '../../widgets/app_alerts.dart';

class PhoneRechargeScreen extends StatefulWidget {
  const PhoneRechargeScreen({super.key});

  @override
  State<PhoneRechargeScreen> createState() => _PhoneRechargeScreenState();
}

class _PhoneRechargeScreenState extends State<PhoneRechargeScreen> {
  int _mode = 0; // 0: Nạp trực tiếp, 1: Mua mã thẻ, 2: Gói cước Data 4G/5G
  final TextEditingController _phoneCtrl = TextEditingController();
  int _selectedTelcoIdx = 0;
  int _selectedAmountIdx = 3; // 100,000đ
  int _selectedDataPkgIdx = 0;
  bool _isSubmitting = false;

  final List<String> _telcos = ['Viettel', 'Vinaphone', 'Mobifone', 'Vietnamobile', 'Wintel'];
  final List<double> _amounts = [10000, 20000, 50000, 100000, 200000, 500000];

  List<Map<String, dynamic>> _recentContacts = [];
  List<Map<String, dynamic>> _recentRecharges = [];

  @override
  void initState() {
    super.initState();
    _initData();
    _phoneCtrl.addListener(_onPhoneChanged);
  }

  Future<void> _initData() async {
    await _loadUserPhone();
    _loadTopupHistory();
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_onPhoneChanged);
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    _detectTelco(_phoneCtrl.text);
  }

  void _detectTelco(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length >= 3) {
      final prefix = clean.substring(0, 3);
      int detectedIdx = _selectedTelcoIdx;
      if (['086', '096', '097', '098', '032', '033', '034', '035', '036', '037', '038', '039'].contains(prefix)) {
        detectedIdx = 0; // Viettel
      } else if (['088', '091', '094', '081', '082', '083', '084', '085'].contains(prefix)) {
        detectedIdx = 1; // Vinaphone
      } else if (['089', '090', '093', '070', '079', '077', '076', '078'].contains(prefix)) {
        detectedIdx = 2; // Mobifone
      } else if (['092', '056', '058'].contains(prefix)) {
        detectedIdx = 3; // Vietnamobile
      } else if (['055'].contains(prefix)) {
        detectedIdx = 4; // Wintel
      }
      if (detectedIdx != _selectedTelcoIdx && mounted) {
        setState(() => _selectedTelcoIdx = detectedIdx);
      }
    }
  }

  Future<void> _loadUserPhone() async {
    const storage = FlutterSecureStorage();
    String myPhone = '';
    try {
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (phone != null && phone.isNotEmpty && mounted) {
        myPhone = phone;
        setState(() {
          _phoneCtrl.text = phone;
          _detectTelco(phone);
        });
      }
    } catch (_) {}

    try {
      final beneficiaries = await BeneficiaryRemoteDataSource().getAll();
      final contacts = beneficiaries.where((b) {
        final acc = (b['accountNumber'] ?? '').toString();
        return acc.length == 10 && (acc.startsWith('09') || acc.startsWith('08') || acc.startsWith('03') || acc.startsWith('07') || acc.startsWith('05'));
      }).map((b) => {
        'name': (b['name'] ?? b['nickname'] ?? 'Bạn bè').toString(),
        'phone': b['accountNumber'].toString(),
        'telco': 'Di động',
      }).toList();

      if (myPhone.isNotEmpty) {
        contacts.insert(0, {'name': 'Số của tôi', 'phone': myPhone, 'telco': 'Chính chủ'});
      }
      if (mounted) setState(() => _recentContacts = contacts);
    } catch (_) {
      if (myPhone.isNotEmpty && mounted) {
        setState(() => _recentContacts = [{'name': 'Số của tôi', 'phone': myPhone, 'telco': 'Chính chủ'}]);
      }
    }
  }

  Future<void> _loadTopupHistory() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final txs = await TransactionRemoteDataSource().getTransactions(
        walletId: wallet.walletId,
        type: 'TOPUP',
        size: 5,
      );
      if (!mounted) return;
      setState(() {
        _recentRecharges = txs.map((tx) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final timeStr = tx['createdAt'] as String? ?? '';
          final desc = tx['description'] as String? ?? 'Nạp tiền điện thoại';
          return {
            'telco': 'Di động',
            'phone': desc,
            'amount': amt,
            'discount': amt * 0.03,
            'date': timeStr.length >= 16 ? timeStr.substring(0, 16).replaceAll('T', ' ') : timeStr,
            'status': 'Nạp thành công',
          };
        }).toList();
      });
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _dataPackages = const [
    {
      'code': 'ST10K',
      'name': 'Gói 1 Ngày (2GB)',
      'desc': '2GB tốc độ cao/ngày, hết tốc độ cao dừng truy cập',
      'price': 10000.0,
      'duration': '1 ngày',
    },
    {
      'code': 'ST30K',
      'name': 'Gói Tuần (7GB)',
      'desc': '7GB data tốc độ cao dùng trong 7 ngày, gia hạn tự động',
      'price': 30000.0,
      'duration': '7 ngày',
    },
    {
      'code': 'ST90N',
      'name': 'Gói Tháng (120GB)',
      'desc': '4GB/ngày (120GB/tháng) + Miễn phí gọi nội mạng dưới 20p',
      'price': 90000.0,
      'duration': '30 ngày',
    },
    {
      'code': '12HD70',
      'name': 'Gói Năm Siêu Rẻ',
      'desc': '5GB/tháng x 12 tháng liên tục không cần nạp tiền định kỳ',
      'price': 500000.0,
      'duration': '360 ngày',
    },
  ];

  double get _discountRate => 0.03; // 3% chiết khấu
  double get _selectedAmount => _mode == 2 ? _dataPackages[_selectedDataPkgIdx]['price'] as double : _amounts[_selectedAmountIdx];
  double get _finalAmount => _selectedAmount * (1 - _discountRate);

  Future<void> _handlePay() async {
    if (_isSubmitting) return;

    final telco = _telcos[_selectedTelcoIdx];
    final cleanPhone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final target = _mode == 1 ? telco : cleanPhone;

    if (_mode != 0) {
      AppAlerts.showInfo(
        context,
        'Tính năng đang được nâng cấp bảo trì. Quý khách vui lòng chọn Nạp trực tiếp để nhận chiết khấu 3% ngay lập tức.',
        title: 'Thông báo dịch vụ',
      );
      return;
    }

    if (cleanPhone.isEmpty) {
      AppAlerts.showWarning(
        context,
        'Vui lòng nhập số điện thoại cần nạp tiền',
        title: 'Thiếu số điện thoại',
      );
      return;
    }

    if (cleanPhone.length < 10) {
      AppAlerts.showWarning(
        context,
        'Số điện thoại không hợp lệ (cần đủ 10 chữ số). Hiện có: ${cleanPhone.length}/10 số.',
        title: 'Sai định dạng',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    await context.push('/bills/topup-confirm?phone=${Uri.encodeComponent(target)}&telco=${Uri.encodeComponent(telco)}&amount=$_selectedAmount');
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nạp Tiền Điện Thoại & 4G/5G'),
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
              // Segmented Tab: Nạp trực tiếp / Mua mã thẻ / Gói Data
              Row(
                children: [
                  _buildTabButton(idx: 0, label: 'Nạp trực tiếp'),
                  const SizedBox(width: 8),
                  _buildTabButton(idx: 1, label: 'Mua mã thẻ'),
                  const SizedBox(width: 8),
                  _buildTabButton(idx: 2, label: 'Gói cước Data'),
                ],
              ),
              const SizedBox(height: 20),

              if (_mode != 1) ...[
                Text('Số điện thoại nạp', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(CupertinoIcons.phone_fill, color: AppColors.primary),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_phoneCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textMutedLight, size: 18),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _phoneCtrl.clear());
                            },
                          ),
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(CupertinoIcons.person_crop_circle_fill_badge_plus, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                    hintText: 'Nhập số điện thoại cần nạp',
                    hintStyle: const TextStyle(color: AppColors.textMutedLight),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  ),
                ),
                if (_phoneCtrl.text.isNotEmpty && _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length < 10) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.info_circle_fill, color: AppColors.warningText, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Số điện thoại cần 10 số (hiện có ${_phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length}/10)',
                        style: const TextStyle(color: AppColors.warningText, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Quick Contacts Chips
                Text('Danh bạ nạp gần đây', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _recentContacts.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(
                              (c['name'] as String).substring(0, 1),
                              style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          label: Text('${c['name']} (${c['phone']})'),
                          backgroundColor: Colors.white.withOpacity(0.85),
                          labelStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                          side: const BorderSide(color: AppColors.borderLight),
                          onPressed: () {
                            setState(() {
                              _phoneCtrl.text = c['phone'] as String;
                              final tIdx = _telcos.indexOf(c['telco'] as String);
                              if (tIdx != -1) _selectedTelcoIdx = tIdx;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text('Chọn nhà mạng', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_telcos.length, (idx) {
                    final t = _telcos[idx];
                    final isSelected = _selectedTelcoIdx == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTelcoIdx = idx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.bottomBarCyan : AppColors.borderLight,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.bottomBarGlow.withOpacity(0.25),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              if (_mode != 2) ...[
                Text('Chọn mệnh giá', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _amounts.length,
                  itemBuilder: (context, idx) {
                    final amt = _amounts[idx];
                    final isSelected = _selectedAmountIdx == idx;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAmountIdx = idx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryDark : AppColors.borderLight,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              CurrencyFormatter.formatVND(amt),
                              style: TextStyle(
                                color: isSelected ? AppColors.primaryDark : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Chiết khấu 3%',
                              style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                Text('Chọn gói cước Data tốc độ cao', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 12),

                ...List.generate(_dataPackages.length, (idx) {
                  final pkg = _dataPackages[idx];
                  final isSelected = _selectedDataPkgIdx == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDataPkgIdx = idx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.10) : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryDark : AppColors.borderLight,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryDark : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                pkg['code'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pkg['name'] as String, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(pkg['desc'] as String, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.formatVND(pkg['price'] as double),
                                  style: AppTypography.titleMedium(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(pkg['duration'] as String, style: const TextStyle(color: AppColors.textMutedLight, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Summary Box
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Giá thanh toán (Đã trừ 3%):', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  alignment: Alignment.centerLeft,
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    CurrencyFormatter.formatVND(_finalAmount),
                                    style: AppTypography.titleLarge(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Tiết kiệm ${CurrencyFormatter.formatVND(_selectedAmount * _discountRate)}',
                              style: const TextStyle(color: AppColors.warningText, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (CurrencyFormatter.toVietnameseWords(_finalAmount).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(_finalAmount)} đồng',
                          style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePay,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_mode == 0 ? 'Nạp tiền ngay' : (_mode == 1 ? 'Mua mã thẻ cào' : 'Đăng ký gói Data ngay')),
                ),
              ),
              const SizedBox(height: 28),

              // Promotion Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.bottomBarCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.bottomBarGlow.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.gift_fill, color: AppColors.accentGold, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HOÀN TIỀN 3% - KHÔNG GIỚI HẠN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Áp dụng tự động cho mọi lần nạp tiền và gói data trên app Sen Hồng.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Recharges History
              Text('Lịch sử nạp tiền gần nhất', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 12),

              if (_recentRecharges.isEmpty)
                GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Chưa có giao dịch nạp tiền gần đây',
                        style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                )
              else
                ..._recentRecharges.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    quality: GlassQuality.minimal,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(CupertinoIcons.device_phone_portrait, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${r['telco']} - ${r['phone']}', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('${r['date']}', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(CurrencyFormatter.formatVND(r['amount'] as double), style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                              Text(r['status'] as String, style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({required int idx, required String label}) {
    final isSelected = _mode == idx;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _mode = idx);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
