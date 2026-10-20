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
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  int _tabIndex = 0;
  final TextEditingController _amountCtrl = TextEditingController(text: '20000000');
  int _selectedProductIdx = 0; // 0: Phat Loc, 1: Tra Lai Thang, 2: Tich Luy Gui Gop
  int _selectedTermIdx = 3; // 12 thang
  int _rolloverOption = 0; // 0: Goc + Lai, 1: Chi Goc, 2: Tat toan ve TK
  bool _isSubmitting = false;

  String _userName = '';
  String _userCccd = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    const storage = FlutterSecureStorage();
    try {
      final name = await storage.read(key: AppConstants.keyFullName);
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (mounted) {
        setState(() {
          if (name != null) _userName = name;
          if (phone != null) _userPhone = phone;
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

  final List<Map<String, dynamic>> _savingsProducts = [
    {
      'title': 'Tiết Kiệm Phát Lộc',
      'subtitle': 'Nhận toàn bộ lãi cuối kỳ với lãi suất sinh lời cao nhất',
      'baseRate': 7.2,
      'minDeposit': 1000000.0,
      'badge': 'Lãi suất cao nhất',
      'icon': CupertinoIcons.sparkles,
    },
    {
      'title': 'Tiết Kiệm Trả Lãi Tháng',
      'subtitle': 'Nhận tiền lãi đều đặn vào ngày 01 hàng tháng để chi tiêu',
      'baseRate': 6.5,
      'minDeposit': 5000000.0,
      'badge': 'Linh hoạt dòng tiền',
      'icon': CupertinoIcons.calendar,
    },
    {
      'title': 'Tích Lũy Gửi Góp V-Plus',
      'subtitle': 'Gửi thêm bất kỳ lúc nào từ 100.000đ, tích lũy tự động',
      'baseRate': 6.0,
      'minDeposit': 500000.0,
      'badge': 'Tích lũy linh hoạt',
      'icon': CupertinoIcons.arrow_up_right_circle_fill,
    },
  ];

  final List<Map<String, dynamic>> _terms = [
    {'months': 1, 'rate': 3.6, 'tag': ''},
    {'months': 3, 'rate': 4.3, 'tag': ''},
    {'months': 6, 'rate': 5.8, 'tag': '+0.3% online'},
    {'months': 12, 'rate': 7.2, 'tag': 'Ưu đãi hot'},
    {'months': 18, 'rate': 7.3, 'tag': ''},
    {'months': 24, 'rate': 7.4, 'tag': 'Dài hạn'},
  ];

  List<Map<String, dynamic>> get _myPassbooks => [
    {
      'code': 'STK2026-088192',
      'product': 'Tiết Kiệm Phát Lộc Online',
      'principal': 50000000.0,
      'term': '12 tháng (7.2%/năm)',
      'rate': 7.2,
      'months': 12,
      'openDate': '15/01/2026',
      'maturityDate': '15/01/2027',
      'expectedInterest': 3600000.0,
      'accruedInterest': 591780.0, // Lai luy ke den nay
      'rollover': 'Tự động tái tục Gốc + Lãi',
      'status': 'ĐANG SINH LỜI',
      'canWithdrawPart': true,
    },
    {
      'code': 'STK2026-012944',
      'product': 'Tiết Kiệm Trả Lãi Tháng',
      'principal': 20000000.0,
      'term': '6 tháng (5.8%/năm)',
      'rate': 5.8,
      'months': 6,
      'openDate': '01/06/2026',
      'maturityDate': '01/12/2026',
      'expectedInterest': 580000.0,
      'accruedInterest': 286027.0,
      'rollover': 'Nhận lãi hàng tháng về TK ${_userPhone.isNotEmpty ? _userPhone : "chính"}',
      'status': 'ĐANG SINH LỜI',
      'canWithdrawPart': true,
    },
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _currentRate {
    final termRate = (_terms[_selectedTermIdx]['rate'] as num).toDouble();
    if (_selectedProductIdx == 1) return (termRate * 0.92); // Tra lai thang lai thap hon ti
    if (_selectedProductIdx == 2) return (termRate * 0.88);
    return termRate;
  }

  int get _currentMonths => _terms[_selectedTermIdx]['months'] as int;

  void _addQuickAmount(double amount) {
    final cur = double.tryParse(_amountCtrl.text) ?? 0;
    setState(() {
      _amountCtrl.text = (cur + amount).toInt().toString();
    });
  }

  Future<void> _handleOpenSavings() async {
    if (_isSubmitting) return;

    final depositAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final minDeposit = _savingsProducts[_selectedProductIdx]['minDeposit'] as double;
    if (depositAmount < minDeposit) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số tiền gửi tối thiểu cho gói này là ${CurrencyFormatter.formatVND(minDeposit)}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final prodTitle = _savingsProducts[_selectedProductIdx]['title'];
    final rateStr = _currentRate.toStringAsFixed(2);
    await context.push(
      '/transfer/confirm?recipient=$prodTitle ($_currentMonths tháng - $rateStr%/năm)&amount=$depositAmount&note=Mo so tiet kiem $prodTitle $_currentMonths thang',
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showWithdrawPartialModal(Map<String, dynamic> pb) {
    final principal = pb['principal'] as double;
    final partialCtrl = TextEditingController(text: '10000000');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bottomBarCyan.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.arrow_down_circle_fill, color: AppColors.bottomBarCyan, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rút Gốc Từng Phần', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        Text('Sổ: ${pb['code']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Theo TT 04/2022/TT-NHNN: Phần gốc còn lại vẫn được giữ nguyên mức lãi suất có kỳ hạn!',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Gốc hiện tại: ${CurrencyFormatter.formatVND(principal)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: partialCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền muốn rút trước hạn',
                  suffixText: 'đ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final withdrawAmt = double.tryParse(partialCtrl.text) ?? 0;
                    if (withdrawAmt <= 0 || withdrawAmt >= principal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Số tiền rút không hợp lệ (phải nhỏ hơn tổng gốc)')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã rút ${CurrencyFormatter.formatVND(withdrawAmt)} về tài khoản. Phần còn lại tiếp tục sinh lời.')),
                    );
                  },
                  child: const Text('Xác nhận rút gốc'),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showPassbookCertModal(Map<String, dynamic> pb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            const SizedBox(height: 16),
            const Icon(CupertinoIcons.doc_text_fill, color: AppColors.bottomBarCyan, size: 48),
            const SizedBox(height: 12),
            const Text('CHỨNG NHẬN TIỀN GỬI ĐIỆN TỬ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const Text('E-PASSBOOK CERTIFICATE • SEN HỒNG BANK', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildCertRow('Chủ sở hữu:', _userName.isNotEmpty ? _userName.toUpperCase() : 'KHÁCH HÀNG SEN HỒNG'),
                  _buildCertRow('Số CCCD:', _userCccd.isNotEmpty ? '$_userCccd (Đã xác thực eKYC)' : 'Đã xác thực eKYC'),
                  _buildCertRow('Mã sổ tiết kiệm:', pb['code']),
                  _buildCertRow('Sản phẩm:', pb['product']),
                  _buildCertRow('Tiền gửi gốc:', CurrencyFormatter.formatVND(pb['principal'] as double), isBold: true),
                  _buildCertRow('Lãi suất áp dụng:', pb['term']),
                  _buildCertRow('Ngày phát hành:', pb['openDate']),
                  _buildCertRow('Ngày đáo hạn:', pb['maturityDate']),
                  _buildCertRow('Trạng thái xác thực:', 'ĐÃ KÝ SỐ SHA-256 (HỢP LỆ)', isSuccess: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang xuất chứng nhận PDF gửi vào Email đăng ký...')),
                      );
                    },
                    icon: const Icon(CupertinoIcons.arrow_down_doc),
                    label: const Text('Tải file PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép liên kết chứng thực sổ trực tuyến.')),
                      );
                    },
                    icon: const Icon(CupertinoIcons.share),
                    label: const Text('Chia sẻ'),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCertRow(String label, String value, {bool isBold = false, bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold || isSuccess ? FontWeight.bold : FontWeight.w500,
                color: isSuccess ? AppColors.emeraldGreen : (isBold ? AppColors.primaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tiết Kiệm Sinh Lời'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Biểu phí & Lãi suất',
            icon: const Icon(CupertinoIcons.question_circle),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lãi suất áp dụng niêm yết theo quy định NHNN Việt Nam cập nhật hàng ngày.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Mở sổ tiết kiệm')),
                      selected: _tabIndex == 0,
                      onSelected: (val) => setState(() => _tabIndex = 0),
                      selectedColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('Sổ của tôi (${_myPassbooks.length})')),
                      selected: _tabIndex == 1,
                      onSelected: (val) => setState(() => _tabIndex = 1),
                      selectedColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tabIndex == 0 ? _buildOpenTab() : _buildMyPassbooksTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Savings Banner with Image
          _buildHeroSavingsBanner(),
          const SizedBox(height: 24),

          // Product Selector
          Text('Chọn gói tiết kiệm phù hợp', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          Column(
            children: List.generate(_savingsProducts.length, (idx) {
              final prod = _savingsProducts[idx];
              final isSelected = _selectedProductIdx == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedProductIdx = idx);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.bottomBarCyan.withOpacity(0.08) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.bottomBarCyan : AppColors.borderLight,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Icon(
                            prod['icon'] as IconData,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    prod['title'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.emeraldGreen.withOpacity(0.2) : AppColors.cardBorderLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      prod['badge'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppColors.emeraldGreen : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                prod['subtitle'] as String,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                          color: isSelected ? AppColors.bottomBarCyan : AppColors.textMutedLight,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Amount Input
          Text('Số tiền gửi tiết kiệm', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.primaryDark, fontSize: 26, fontWeight: FontWeight.bold),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixIcon: _amountCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textMutedLight, size: 20),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _amountCtrl.clear());
                      },
                    )
                  : null,
              suffixText: ' đ',
              suffixStyle: const TextStyle(color: AppColors.primaryDark, fontSize: 20, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          if ((double.tryParse(_amountCtrl.text) ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(double.tryParse(_amountCtrl.text) ?? 0)} đồng',
                style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('+5 Triệu', 5000000),
                _buildQuickChip('+10 Triệu', 10000000),
                _buildQuickChip('+50 Triệu', 50000000),
                _buildQuickChip('+100 Triệu', 100000000),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms
          Text('Chọn kỳ hạn gửi online', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_terms.length, (idx) {
                final t = _terms[idx];
                final isSelected = _selectedTermIdx == idx;
                final rate = _selectedProductIdx == 1 ? (t['rate'] * 0.92) : (_selectedProductIdx == 2 ? (t['rate'] * 0.88) : t['rate']);
                final rateStr = (rate as double).toStringAsFixed(2);
                final tag = t['tag'] as String;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTermIdx = idx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 108,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.bottomBarCyan : AppColors.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.bottomBarGlow.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          if (tag.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.accentGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.accentGold,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 17),
                          Text('${t['months']} Tháng', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('$rateStr%', style: TextStyle(color: isSelected ? Colors.white : AppColors.emeraldGreen, fontSize: 17, fontWeight: FontWeight.w800)),
                          Text('/năm', style: TextStyle(color: isSelected ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Interactive Calculator Preview Card
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountCtrl,
            builder: (context, value, _) {
              final depositAmt = double.tryParse(value.text) ?? 0;
              final totalInterest = depositAmt * (_currentRate / 100.0) * (_currentMonths / 12.0);
              final dailyInterest = depositAmt * (_currentRate / 100.0) / 365.0;
              final monthlyInterest = depositAmt * (_currentRate / 100.0) / 12.0;

              return GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bảng Tính Tăng Trưởng Lãi', style: AppTypography.titleMedium(color: AppColors.primaryDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${_currentRate.toStringAsFixed(2)}%/năm',
                              style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCalcRow('Tiền lãi dự kiến mỗi ngày:', CurrencyFormatter.formatVND(dailyInterest)),
                      const SizedBox(height: 8),
                      _buildCalcRow('Tiền lãi ước tính mỗi tháng:', CurrencyFormatter.formatVND(monthlyInterest)),
                      const Divider(height: 20, color: AppColors.cardBorderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng tiền lãi khi đáo hạn:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                          Text(CurrencyFormatter.formatVND(totalInterest), style: AppTypography.titleLarge(color: AppColors.emeraldGreen)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng gốc + lãi thực nhận:', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                          Text(CurrencyFormatter.formatVND(depositAmt + totalInterest), style: AppTypography.titleMedium(color: AppColors.primaryDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Rollover options
          Text('Phương thức đáo hạn', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                RadioListTile<int>(
                  value: 0,
                  groupValue: _rolloverOption,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tái tục toàn bộ Gốc và Lãi (Lãi kép sinh lời)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onChanged: (v) => setState(() => _rolloverOption = v!),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                RadioListTile<int>(
                  value: 1,
                  groupValue: _rolloverOption,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tái tục Gốc, chuyển Lãi về tài khoản thanh toán', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onChanged: (v) => setState(() => _rolloverOption = v!),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                RadioListTile<int>(
                  value: 2,
                  groupValue: _rolloverOption,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tất toán toàn bộ Gốc và Lãi về tài khoản khi đáo hạn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onChanged: (v) => setState(() => _rolloverOption = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Legal / Regulatory Box (DIV & TT 04/2022/TT-NHNN)
          _buildLegalPolicyBox(),
          const SizedBox(height: 28),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleOpenSavings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Mở sổ tiết kiệm ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSavingsBanner() {
    return Container(
      width: double.infinity,
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Savings Illustration
          Positioned(
            right: -10,
            bottom: -10,
            top: -10,
            width: 180,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/images/banking_savings.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    CupertinoIcons.archivebox_fill,
                    size: 90,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.accentGold, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'TIẾT KIỆM BẢO CHỨNG NHNN',
                        style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tiết Kiệm Sen Lộc Phát',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lãi suất vượt trội đến 7.4%/năm\nRút gốc từng phần bảo toàn lãi suất',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        backgroundColor: AppColors.dividerLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderLight)),
        onPressed: () => _addQuickAmount(amount),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalPolicyBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Bảo Hiểm Tiền Gửi & Chính Sách NHNN',
                style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 100% tiền gửi được bảo vệ bởi Bảo hiểm Tiền gửi Việt Nam (DIV) theo Luật các TCTD.\n'
            '• Tuân thủ Thông tư 04/2022/TT-NHNN: Khách hàng được rút gốc từng phần mà không bị mất lãi suất kỳ hạn của phần gốc duy trì còn lại.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPassbooksTab() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      itemCount: _myPassbooks.length,
      itemBuilder: (context, idx) {
        final pb = _myPassbooks[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            quality: GlassQuality.minimal,
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                            Text(
                              pb['code'] as String,
                              style: AppTypography.titleMedium(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              pb['product'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showPassbookCertModal(pb),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(pb['status'] as String, style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Tiền gốc gửi tiết kiệm', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  Text(CurrencyFormatter.formatVND(pb['principal'] as double), style: const TextStyle(color: AppColors.primaryDark, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.graph_circle, color: AppColors.emeraldGreen, size: 16),
                      const SizedBox(width: 6),
                      const Text('Lãi lũy kế đến hôm nay: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      Text(CurrencyFormatter.formatVND(pb['accruedInterest'] as double), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.cardBorderLight),
                  _buildRow('Kỳ hạn & Lãi suất', pb['term'] as String),
                  const SizedBox(height: 6),
                  _buildRow('Ngày gửi', pb['openDate'] as String),
                  const SizedBox(height: 6),
                  _buildRow('Ngày đáo hạn', pb['maturityDate'] as String),
                  const SizedBox(height: 6),
                  _buildRow('Phương thức tái tục', pb['rollover'] as String),
                  const SizedBox(height: 6),
                  _buildRow('Lãi dự kiến khi đáo hạn', CurrencyFormatter.formatVND(pb['expectedInterest'] as double), isGreen: true),
                  const SizedBox(height: 18),
                  
                  // Secondary actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: AppColors.bottomBarCyan),
                            foregroundColor: AppColors.bottomBarCyan,
                          ),
                          onPressed: () => context.push('/savings/detail', extra: pb),
                          icon: const Icon(CupertinoIcons.doc_text_fill, size: 16),
                          label: const Text('Chi tiết sổ điện tử', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: AppColors.bottomBarCyan),
                            foregroundColor: AppColors.bottomBarCyan,
                          ),
                          onPressed: () => _showWithdrawPartialModal(pb),
                          icon: const Icon(CupertinoIcons.arrow_down_circle, size: 16),
                          label: const Text('Rút gốc 1 phần', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('Tất Toán Sổ Tiết Kiệm?'),
                                content: Text('Sổ ${pb['code']} chưa đến ngày đáo hạn (${pb['maturityDate']}). Nếu tất toán trước hạn toàn bộ, lãi suất sẽ chuyển về không kỳ hạn (0.1%/năm). Bạn có thể chọn Rút gốc từng phần để giữ nguyên lãi suất.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Giữ lại sổ')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã gửi yêu cầu tất toán sổ ${pb['code']}')),
                                      );
                                    },
                                    child: const Text('Xác nhận tất toán'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Tất toán toàn bộ', style: TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            context.push(
                              '/bills/confirm?service=${Uri.encodeComponent('Nạp tích lũy sổ tiết kiệm')}&provider=SenHongBank&code=${Uri.encodeComponent(pb['code'] as String)}&amount=5000000',
                            );
                          },
                          icon: const Icon(CupertinoIcons.plus_circle, size: 16),
                          label: const Text('Nạp tích lũy', style: TextStyle(fontSize: 12)),
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
    );
  }

  Widget _buildRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
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
}

