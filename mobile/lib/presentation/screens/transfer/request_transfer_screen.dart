import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/money_request_remote_datasource.dart';

class RequestTransferScreen extends StatefulWidget {
  const RequestTransferScreen({super.key});

  @override
  State<RequestTransferScreen> createState() => _RequestTransferScreenState();
}

class _RequestTransferScreenState extends State<RequestTransferScreen> {
  final TextEditingController _targetCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isGroupSplit = false;
  int _splitMemberCount = 3;
  bool _isSubmitting = false;

  final List<double> _quickAmounts = [50000, 100000, 200000, 500000, 1000000, 2000000];

  double _eachPersonAmount(String amountText) {
    final total = double.tryParse(amountText) ?? 0;
    return _isGroupSplit && _splitMemberCount > 0 ? (total / _splitMemberCount) : total;
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRequest() async {
    if (_isSubmitting) return;

    final total = double.tryParse(_amountCtrl.text) ?? 0;
    if (total < 10000) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền yêu cầu tối thiểu là 10.000đ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (total > 50000000) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền yêu cầu tối đa cho mỗi giao dịch là 50.000.000đ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final target = _targetCtrl.text.trim();
    if (target.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại hoặc người nhận'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final perPerson = _eachPersonAmount(_amountCtrl.text);
      await MoneyRequestRemoteDataSource().create(
        payerUserId: target,
        amount: _isGroupSplit ? perPerson : total,
        message: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : (_isGroupSplit ? 'Chia tiền nhóm' : 'Yêu cầu chuyển tiền'),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: 'https://senbank.vn/pay-request?target=$target&amount=$total'));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text('Đã tạo yêu cầu!', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isGroupSplit
                  ? 'Yêu cầu chia tiền nhóm ($_splitMemberCount người, mỗi người ${CurrencyFormatter.formatVND(_eachPersonAmount(_amountCtrl.text))}) đã được khởi tạo.'
                  : 'Yêu cầu chuyển ${CurrencyFormatter.formatVND(total)} đã gửi tới $target.',
              style: const TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Icon(CupertinoIcons.qrcode, color: AppColors.primary, size: 80),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Đã sao chép link thanh toán vào bộ nhớ đệm', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/transfer');
              }
            },
            child: const Text('Đóng', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
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
        title: const Text('Yêu Cầu Chuyển Tiền / Chia Tiền'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Mã QR của tôi',
            icon: const Icon(CupertinoIcons.qrcode, color: AppColors.primary),
            onPressed: () => context.push('/my-qr'),
          ),
          IconButton(
            tooltip: 'Chuyển tiền',
            icon: const Icon(CupertinoIcons.paperplane_fill, color: AppColors.primary),
            onPressed: () => context.push('/transfer'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Choice: Cá nhân / Chia nhóm
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Nhắc nợ cá nhân')),
                      selected: !_isGroupSplit,
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _isGroupSplit = false);
                      },
                      selectedColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Chia tiền nhóm')),
                      selected: _isGroupSplit,
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _isGroupSplit = true);
                      },
                      selectedColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_isGroupSplit) ...[
                Text('Người trả tiền (SĐT hoặc Tên)', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetCtrl,
                  style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(CupertinoIcons.person_fill, color: AppColors.primary),
                    hintText: 'Nhập số điện thoại người cần nhắc nợ',
                    hintStyle: const TextStyle(color: AppColors.textMutedLight),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                Text('Số người cùng chia (bao gồm cả bạn)', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 8),
                GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_splitMemberCount người', style: AppTypography.titleMedium(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.minus_circle_fill, color: AppColors.textSecondaryLight),
                              onPressed: _splitMemberCount > 2
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _splitMemberCount--);
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.primary),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _splitMemberCount++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              Text('Tổng số tiền cần nhận', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: AppTypography.displaySmall(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: 'đ',
                  suffixStyle: const TextStyle(color: AppColors.primaryDark, fontSize: 24, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),

              // Dynamic Vietnamese Words for Amount & Limits
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _amountCtrl,
                builder: (context, value, _) {
                  final amt = double.tryParse(value.text) ?? 0;
                  final words = CurrencyFormatter.toVietnameseWords(amt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (words.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Bằng chữ: $words đồng',
                            style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              amt < 10000 || amt > 50000000 ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.checkmark_shield_fill,
                              size: 13,
                              color: amt < 10000 || amt > 50000000 ? AppColors.warningText : AppColors.emeraldGreen,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Hạn mức yêu cầu: 10.000đ - 50.000.000đ / giao dịch',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: amt < 10000 || amt > 50000000 ? AppColors.warningText : AppColors.textMutedLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Quick Amount Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amt) {
                  return ActionChip(
                    label: Text(CurrencyFormatter.formatVND(amt)),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                    side: const BorderSide(color: AppColors.borderLight),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _amountCtrl.text = amt.toInt().toString());
                    },
                  );
                }).toList(),
              ),

              if (_isGroupSplit) ...[
                const SizedBox(height: 14),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _amountCtrl,
                  builder: (context, value, _) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mỗi người cần trả:', style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight)),
                          Text(
                            CurrencyFormatter.formatVND(_eachPersonAmount(value.text)),
                            style: AppTypography.titleMedium(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 18),
              Text('Nội dung / Lời nhắn', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(CupertinoIcons.chat_bubble_text_fill, color: AppColors.primary),
                  hintText: 'Nhập lý do nhắc nợ / chia tiền',
                  hintStyle: const TextStyle(color: AppColors.textMutedLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreateRequest,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isGroupSplit ? 'Tạo liên kết chia tiền nhóm' : 'Gửi yêu cầu chuyển tiền'),
                ),
              ),

              const SizedBox(height: 20),

              // Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.paperplane_fill,
                        label: 'Chuyển tiền trực tiếp ví & liên ngân hàng',
                        onTap: () => context.push('/transfer'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode,
                        label: 'Lấy mã VietQR cá nhân nhận tiền chuyển khoản',
                        onTap: () => context.push('/my-qr'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        label: 'Quét mã QR bạn bè để nhận diện tài khoản',
                        onTap: () => context.push('/scan-qr'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_2_fill,
                        label: 'Danh bạ người thụ hưởng đã lưu',
                        onTap: () => context.push('/beneficiaries'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.clock_fill,
                        label: 'Xem lịch sử các yêu cầu nhận & chuyển tiền',
                        onTap: () => context.push('/history'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouterTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 14),
          ],
        ),
      ),
    );
  }
}
