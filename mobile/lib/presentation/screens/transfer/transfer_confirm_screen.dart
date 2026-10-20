import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class TransferConfirmScreen extends StatefulWidget {
  final String recipient;
  final double amount;
  final String note;

  const TransferConfirmScreen({
    super.key,
    required this.recipient,
    required this.amount,
    required this.note,
  });

  @override
  State<TransferConfirmScreen> createState() => _TransferConfirmScreenState();
}

class _TransferConfirmScreenState extends State<TransferConfirmScreen> {
  final TextEditingController _otpController = TextEditingController();
  // ValueNotifier để chỉ rebuild _OtpCountdownRow, không rebuild toàn screen
  final ValueNotifier<int> _secondsNotifier = ValueNotifier<int>(60);
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsNotifier.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsNotifier.value > 0) {
        _secondsNotifier.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secondsNotifier.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final pin = _otpController.text.trim();
    if (pin.length < 6) {
      HapticFeedback.vibrate();
      AppAlerts.showError(
        context,
        'Vui lòng nhập đủ 6 số mã xác thực',
        title: 'Lỗi',
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final transferApi = TransferRemoteDataSource();
      final recipientInfo = await transferApi.getRecipient(widget.recipient);
      final targetId = (recipientInfo['walletId'] ?? '').toString();

      final initRes = await transferApi.initTransfer(
        sourceWalletId: wallet.walletId,
        targetWalletId: targetId,
        amount: widget.amount,
        note: widget.note,
      );
      final txId = (initRes['transactionId'] ?? initRes['id'] ?? '').toString();
      await transferApi.confirmTransfer(transactionId: txId, pin: pin);

      if (!mounted) return;
      context.go('/transfer/result?recipient=${Uri.encodeComponent(widget.recipient)}&amount=${widget.amount}&note=${Uri.encodeComponent(widget.note)}&transactionId=$txId');
    } catch (e) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(e),
          title: 'Giao dịch thất bại',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Thực Giao Dịch (2FA)'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InlineWarningBanner(
                title: 'Cảnh báo an toàn xác thực OTP',
                message: 'Mã OTP là mật khẩu dùng một lần để chuyển tiền. SenBank KHÔNG BAO GIỜ yêu cầu bạn cung cấp mã này. Cảnh giác kẻ gian mạo danh!',
                type: AlertType.warning,
              ),
              const SizedBox(height: 16),

              // Transaction Review Brief Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Người nhận:', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.recipient,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Số tiền chuyển:', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                          Text(
                            CurrencyFormatter.formatVND(widget.amount),
                            style: AppTypography.titleMedium(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (CurrencyFormatter.toVietnameseWords(widget.amount).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(widget.amount)} đồng',
                            style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      if (widget.note.isNotEmpty) ...[
                        const Divider(height: 16, color: AppColors.cardBorderLight),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lời nhắn:', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.note,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall(color: AppColors.textPrimaryLight),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primaryDark, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bảo mật 2 lớp giá trị cao', style: AppTypography.titleMedium(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            'Giao dịch ${CurrencyFormatter.formatVND(widget.amount)} yêu cầu xác thực OTP gửi qua SMS tới số đăng ký.',
                            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Nhập mã OTP 6 số', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Kiểm tra tin nhắn SMS từ SEN HỒNG trên điện thoại của bạn', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 18),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: AppColors.primaryDark, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(CupertinoIcons.lock_fill, color: AppColors.primary),
                  hintText: '• • • • • •',
                  hintStyle: const TextStyle(color: AppColors.textMutedLight, letterSpacing: 6),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Widget đếm ngược tách riêng — chỉ phần này rebuild mỗi giây
              _OtpCountdownRow(
                secondsNotifier: _secondsNotifier,
                onResend: _startCountdown,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleConfirm,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận & Chuyển tiền'),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/transfer');
                  }
                },
                icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                label: const Text('Hủy bỏ giao dịch'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.textSecondaryLight,
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 24),

              // Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_fill,
                        label: 'Không nhận được mã OTP? Tổng đài CSKH 24/7',
                        onTap: () => context.push('/support/help-center'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Kích hoạt Chữ ký số Smart OTP không cần SMS',
                        onTap: () => context.push('/profile/digital-signature'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_left_circle_fill,
                        label: 'Quay lại màn hình Chọn người nhận',
                        onTap: () => context.go('/transfer'),
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

/// Widget đếm ngược OTP tách biệt — dùng ValueListenableBuilder
/// chỉ rebuild Row này mỗi giây, không ảnh hưởng toàn screen.
class _OtpCountdownRow extends StatelessWidget {
  final ValueNotifier<int> secondsNotifier;
  final VoidCallback onResend;

  const _OtpCountdownRow({
    required this.secondsNotifier,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: secondsNotifier,
      builder: (context, seconds, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              seconds > 0 ? 'Mã hết hạn sau: ${seconds}s' : 'Mã OTP đã hết hạn',
              style: TextStyle(
                color: seconds > 0 ? AppColors.textSecondaryLight : AppColors.error,
              ),
            ),
            TextButton(
              onPressed: seconds == 0 ? onResend : null,
              child: const Text('Gửi lại mã'),
            ),
          ],
        );
      },
    );
  }
}
