import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class EnterAmountScreen extends StatefulWidget {
  final String recipient;
  final String? phoneNumber;
  final String? walletId;
  final double? initialAmount;
  final String? initialNote;

  const EnterAmountScreen({
    super.key,
    required this.recipient,
    this.phoneNumber,
    this.walletId,
    this.initialAmount,
    this.initialNote,
  });

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final TextEditingController _aliasController = TextEditingController();

  double _balance = 0.0;
  bool _isLoadingBalance = true;
  int _selectedCardIdx = 0;
  int _selectedTransferType = 0; // 0: Napas 24/7, 1: Chuyển thường Citad, 2: Đặt lịch
  bool _saveBeneficiary = false;

  final double _dailyLimit = 50000000;
  final double _usedLimitToday = 15000000;

  final List<Map<String, dynamic>> _greetingCards = [
    {
      'title': 'Mặc định',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'color': AppColors.bottomBarCyan,
      'defaultNote': 'Chuyen tien',
    },
    {
      'title': 'Sinh Nhật',
      'icon': CupertinoIcons.gift_fill,
      'color': AppColors.primary,
      'defaultNote': 'Chuc mung sinh nhat! Tuoi moi van su nhu y',
    },
    {
      'title': 'Cảm Ơn',
      'icon': CupertinoIcons.heart_fill,
      'color': const Color(0xFFFF5252),
      'defaultNote': 'Cam on ban rat nhieu vi da giup do',
    },
    {
      'title': 'Cafe / Ăn Trưa',
      'icon': CupertinoIcons.bag_fill,
      'color': AppColors.accentGold,
      'defaultNote': 'Gui tien cafe an trua hom nay nhe',
    },
    {
      'title': 'Khai Trương',
      'icon': CupertinoIcons.star_fill,
      'color': const Color(0xFFFF9800),
      'defaultNote': 'Chuc mung khai truong hong phat tai loc',
    },
    {
      'title': 'Tiền Nhà / Trọ',
      'icon': CupertinoIcons.house_fill,
      'color': AppColors.emeraldGreen,
      'defaultNote': 'Gui tien thue nha thang nay',
    },
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.initialAmount != null && widget.initialAmount! > 0)
          ? widget.initialAmount!.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController(
      text: widget.initialNote ?? 'Chuyen tien',
    );
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          _balance = wallet.balance;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  void _addAmount(double add) {
    HapticFeedback.selectionClick();
    final current =
        double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
    final total = current + add;
    setState(() {
      _amountController.text = total.toStringAsFixed(0);
    });
  }

  void _selectCard(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCardIdx = idx;
      _noteController.text = _greetingCards[idx]['defaultNote'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    final amountVal = double.tryParse(_amountController.text) ?? 0;
    final remainingLimit = (_dailyLimit - _usedLimitToday).clamp(0.0, _dailyLimit);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nhập Số Tiền Chuyển'),
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
              // 1. Recipient Badge Card
              _buildRecipientCard(),
              const SizedBox(height: 18),

              // 2. Amount Input Card
              _buildAmountInputCard(amountVal),
              if (_balance > 0 && amountVal > _balance) ...[
                const SizedBox(height: 12),
                InlineWarningBanner(
                  title: 'Số dư khả dụng không đủ',
                  message: 'Số tiền chuyển (${CurrencyFormatter.formatVND(amountVal)}) vượt quá số dư ví hiện có (${CurrencyFormatter.formatVND(_balance)}).',
                  type: AlertType.error,
                  actionLabel: 'Nạp tiền',
                  onAction: () => context.push('/deposit'),
                ),
              ] else if (amountVal > remainingLimit) ...[
                const SizedBox(height: 12),
                InlineWarningBanner(
                  title: 'Vượt hạn mức trong ngày',
                  message: 'Hạn mức giao dịch còn lại hôm nay là ${CurrencyFormatter.formatVND(remainingLimit)}. Vui lòng điều chỉnh số tiền.',
                  type: AlertType.warning,
                ),
              ],
              const SizedBox(height: 16),

              // 3. Quick Amount Chips
              _buildQuickAmountChips(),
              const SizedBox(height: 22),

              // 4. Greeting Card Theme Selector
              _buildGreetingCardsSection(),
              const SizedBox(height: 22),

              // 5. Transfer Method Selection
              _buildTransferMethodSection(),
              const SizedBox(height: 22),

              // 6. Daily Limit Progress Card
              _buildDailyLimitCard(remainingLimit),
              const SizedBox(height: 22),

              // 7. Note & Save Beneficiary Section
              _buildNoteAndBeneficiarySection(),
              const SizedBox(height: 24),

              // 8. Submit Button
              _buildSubmitButton(amountVal, remainingLimit),
              const SizedBox(height: 20),

              // 9. Guarantee & Security Notice
              _buildSecurityGuaranteeNotice(),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRecipientCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.bottomBarCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.person_crop_circle_fill,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipient.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty
                        ? 'SĐT: ${widget.phoneNumber} • Ví Sen Hồng'
                        : 'Ví Sen Hồng • Đã xác thực CCCD eKYC',
                    style: const TextStyle(
                      color: AppColors.bottomBarCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.emeraldGreen, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'ĐÃ XÁC THỰC',
                    style: TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildAmountInputCard(double amountVal) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Center(
          child: Column(
            children: [
              const Text(
                'Số tiền giao dịch',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.white30),
                        suffixText: ' đ',
                        suffixStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.bottomBarCyan,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (amountVal > 0)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _amountController.clear());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.clear_thick,
                            size: 13, color: Colors.white70),
                      ),
                    ),
                ],
              ),
              if (amountVal > 0) ...[
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatVND(amountVal),
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(amountVal)} đồng',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              if (amountVal >= 10000000) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.shield_lefthalf_fill,
                          color: AppColors.accentGold, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Theo QĐ 2345/QĐ-NHNN: Giao dịch từ 10.000.000 đ yêu cầu xác thực khuôn mặt sinh trắc học FaceID.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoadingBalance
                        ? 'Đang tải số dư...'
                        : 'Số dư khả dụng: ${CurrencyFormatter.formatVND(_balance)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  if (amountVal > _balance && _balance > 0) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => context.push('/deposit'),
                      child: const Text(
                        'Nạp thêm',
                        style: TextStyle(
                          color: AppColors.bottomBarCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (amountVal > _balance && _balance > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppColors.errorText, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Số tiền vượt quá số dư (${CurrencyFormatter.formatVND(_balance)})',
                          style: const TextStyle(
                            color: AppColors.errorText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickChip('+50.000', () => _addAmount(50000)),
        _buildQuickChip('+100.000', () => _addAmount(100000)),
        _buildQuickChip('+500.000', () => _addAmount(500000)),
        _buildQuickChip('+1.000.000', () => _addAmount(1000000)),
        _buildQuickChip('+2.000.000', () => _addAmount(2000000)),
        if (_balance > 0)
          _buildQuickChip('Tất cả số dư', () {
            HapticFeedback.selectionClick();
            setState(() => _amountController.text = _balance.toStringAsFixed(0));
          }),
      ],
    );
  }

  Widget _buildGreetingCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(CupertinoIcons.sparkles, color: AppColors.accentGold, size: 16),
            SizedBox(width: 6),
            Text(
              'Thiệp Chúc Mừng Điện Tử (E-Cards)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Chọn mẫu thiệp để người nhận bất ngờ khi mở biên lai chuyển khoản',
          style: TextStyle(color: Colors.white54, fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _greetingCards.length,
            itemBuilder: (context, idx) {
              final c = _greetingCards[idx];
              final isSelected = _selectedCardIdx == idx;
              return GestureDetector(
                onTap: () => _selectCard(idx),
                child: Container(
                  width: 105,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (c['color'] as Color).withValues(alpha: 0.25)
                        : const Color(0xFF0D1B2A).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (c['color'] as Color)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(c['icon'] as IconData,
                          color: c['color'] as Color, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        c['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransferMethodSection() {
    final methods = [
      {
        'title': 'NAPAS 24/7 Siêu Tốc',
        'sub': 'Nhận tức thì sau 3 giây • Miễn phí 100%',
        'icon': CupertinoIcons.bolt_fill,
        'badge': 'KHUYÊN DÙNG',
      },
      {
        'title': 'Chuyển Liên Ngân Hàng Citad',
        'sub': 'Xử lý trong giờ hành chính các ngày làm việc',
        'icon': CupertinoIcons.building_2_fill,
        'badge': null,
      },
      {
        'title': 'Đặt Lịch Chuyển Tiền Tương Lai',
        'sub': 'Tự động gửi vào ngày giờ đã thiết lập',
        'icon': CupertinoIcons.calendar_today,
        'badge': 'MỚI',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức xử lý lệnh chuyển',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          quality: GlassQuality.minimal,
          child: Column(
            children: List.generate(methods.length, (idx) {
              final m = methods[idx];
              final isSelected = _selectedTransferType == idx;
              return Column(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTransferType = idx);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.bottomBarCyan.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          color: isSelected
                              ? AppColors.bottomBarCyan
                              : Colors.white60,
                          size: 18,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              m['title'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (m['badge'] != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m['badge'] as String,
                                style: const TextStyle(
                                  color: AppColors.emeraldGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        m['sub'] as String,
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
                        size: 20,
                      ),
                    ),
                  ),
                  if (idx < methods.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyLimitCard(double remainingLimit) {
    final progress = (_usedLimitToday / _dailyLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.chart_pie_fill,
                      color: AppColors.bottomBarCyan, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Hạn mức chuyển khoản hôm nay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.bottomBarCyan,
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
                  AppColors.bottomBarCyan),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã dùng: ${CurrencyFormatter.formatVND(_usedLimitToday)}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                'Còn lại: ${CurrencyFormatter.formatVND(remainingLimit)}',
                style: const TextStyle(
                  color: AppColors.emeraldGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteAndBeneficiarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Note Input
        TextField(
          controller: _noteController,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            labelText: 'Lời nhắn / Nội dung chuyển tiền',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(CupertinoIcons.chat_bubble_text_fill,
                color: AppColors.bottomBarCyan, size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.bottomBarCyan, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Save Beneficiary Switch
        GlassCard(
          quality: GlassQuality.minimal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(CupertinoIcons.bookmark_fill,
                            color: AppColors.accentGold, size: 18),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lưu vào Danh bạ Thụ hưởng',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Giúp chuyển nhanh 1-chạm cho các lần sau',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: _saveBeneficiary,
                      activeTrackColor: AppColors.bottomBarCyan,
                      onChanged: (v) => setState(() => _saveBeneficiary = v),
                    ),
                  ],
                ),
                if (_saveBeneficiary) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _aliasController,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Nhập biệt danh gợi nhớ (ví dụ: Bạn Thân, Chủ Trọ...)',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(double amountVal, double remainingLimit) {
    final isExceededBalance = _balance > 0 && amountVal > _balance;
    final isExceededLimit = amountVal > remainingLimit;
    final isEnabled = amountVal > 0 && !isExceededBalance && !isExceededLimit;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.primary : AppColors.cardBorderLight,
          foregroundColor: isEnabled ? Colors.white : Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isEnabled ? 4 : 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        onPressed: isEnabled
            ? () {
                HapticFeedback.mediumImpact();
                final params = <String, String>{
                  'recipient': widget.recipient,
                  'amount': amountVal.toString(),
                  'note': _noteController.text,
                  if (widget.phoneNumber != null)
                    'phoneNumber': widget.phoneNumber!,
                  if (widget.walletId != null) 'walletId': widget.walletId!,
                };
                final uri =
                    Uri(path: '/transfer/confirm', queryParameters: params);
                context.push(uri.toString());
              }
            : () {
                HapticFeedback.vibrate();
                if (isExceededBalance) {
                  AppAlerts.showError(
                    context,
                    'Số tiền chuyển vượt quá số dư khả dụng (${CurrencyFormatter.formatVND(_balance)}). Vui lòng nạp thêm tiền.',
                    title: 'Số dư không đủ',
                    actionLabel: 'Nạp tiền',
                    onAction: () => context.push('/deposit'),
                  );
                } else if (isExceededLimit) {
                  AppAlerts.showWarning(
                    context,
                    'Số tiền vượt hạn mức chuyển khoản tối đa trong ngày (${CurrencyFormatter.formatVND(remainingLimit)}).',
                    title: 'Vượt hạn mức ngày',
                  );
                }
              },
        child: Text(
          isExceededBalance
              ? 'Số tiền vượt số dư khả dụng ví'
              : isExceededLimit
                  ? 'Vượt hạn mức chuyển tiền ngày'
                  : 'Tiếp tục xác nhận giao dịch',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSecurityGuaranteeNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.checkmark_shield_fill,
              color: AppColors.emeraldGreen, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cam kết chuyển mạch NAPAS 24/7 & Bảo mật đa tầng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Giao dịch được mã hóa chuẩn PCI-DSS Level 1. Tiền về tài khoản người nhận trong 3 giây. Hoàn tiền tức thì 100% nếu có gián đoạn kết nối ngân hàng.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF132A48).withValues(alpha: 0.6),
      side: BorderSide(color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}
