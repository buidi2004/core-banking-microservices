import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class DepositConfirmScreen extends StatefulWidget {
  final double amount;
  final String source;

  const DepositConfirmScreen({
    super.key,
    required this.amount,
    required this.source,
  });

  @override
  State<DepositConfirmScreen> createState() => _DepositConfirmScreenState();
}

class _DepositConfirmScreenState extends State<DepositConfirmScreen> {
  String _pin = '';
  bool _isLoading = false;
  String _targetAccount = 'Ví Sen Hồng chính';

  @override
  void initState() {
    super.initState();
    _loadTargetAccount();
  }

  Future<void> _loadTargetAccount() async {
    try {
      const storage = FlutterSecureStorage();
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (phone != null && phone.isNotEmpty && mounted) {
        final masked = phone.length > 4 ? '(*${phone.substring(phone.length - 4)})' : phone;
        setState(() {
          _targetAccount = 'Ví Sen Hồng chính $masked';
        });
      }
    } catch (_) {}
  }

  void _handlePinInput(String digit) {
    HapticFeedback.selectionClick();
    if (_pin.length < 6) {
      setState(() => _pin += digit);
      if (_pin.length == 6) {
        _submitDeposit();
      }
    }
  }

  void _handleBackspace() {
    HapticFeedback.selectionClick();
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _handleBiometric() {
    AppAlerts.showInfo(
      context,
      'Tính năng xác thực sinh trắc học đang đồng bộ. Quý khách vui lòng nhập mã PIN bảo mật.',
      title: 'Sinh trắc học',
    );
  }

  Future<void> _submitDeposit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final result = await WalletTransactionRemoteDataSource().deposit(
        walletId: wallet.walletId,
        amount: widget.amount,
      );
      if (!mounted) return;
      context.go(
        '/transfer/result?recipient=Nạp%20Ví%20Sen%20Hồng&amount=${widget.amount}&note=Nạp%20tiền&transactionId=${result['transactionId'] ?? ''}&status=${result['status'] ?? 'SUCCESS'}',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _pin = '');
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Nạp tiền không thành công',
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
        title: const Text('Xác Nhận Nạp Tiền'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    const InlineWarningBanner(
                      title: 'Lưu ý nạp tiền an toàn',
                      message: 'Vui lòng kiểm tra nguồn thanh toán chính chủ. Tiền nạp sẽ được cộng trực tiếp vào số dư khả dụng ngay khi giao dịch thành công.',
                      type: AlertType.info,
                    ),
                    const SizedBox(height: 14),

                    // Summary Glass Card
                    GlassCard(
                      quality: GlassQuality.minimal,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text('Số tiền nạp vào ví', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.formatVND(widget.amount),
                              style: AppTypography.displayMedium(color: AppColors.emeraldGreen),
                            ),
                            if (CurrencyFormatter.toVietnameseWords(widget.amount).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(widget.amount)} đồng',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const Divider(height: 28, color: AppColors.cardBorderLight),
                            _buildRow('Nguồn nạp', widget.source),
                            const SizedBox(height: 10),
                            _buildRow('Tài khoản nhận', _targetAccount),
                            const SizedBox(height: 10),
                            _buildRow('Phí giao dịch', 'Miễn phí (0đ)', isHighlight: true),
                            const SizedBox(height: 10),
                            _buildRow('Thời gian xử lý', 'Tức thì 24/7 (Realtime)'),
                            const SizedBox(height: 10),
                            _buildRow('Tổng tiền trừ', CurrencyFormatter.formatVND(widget.amount)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Daily Deposit Limit Card
                    GlassCard(
                      quality: GlassQuality.minimal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.arrow_down_circle_fill, color: AppColors.emeraldGreen, size: 18),
                                    SizedBox(width: 8),
                                    Text('Hạn mức nạp tiền trong ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
                                  ],
                                ),
                                Text('50.000.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (widget.amount / 50000000).clamp(0.05, 1.0),
                                backgroundColor: AppColors.dividerLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.bottomBarCyan),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Nạp giao dịch này: ${CurrencyFormatter.formatVND(widget.amount)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                Text('Hạn mức còn lại: ${CurrencyFormatter.formatVND(50000000 - widget.amount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emeraldGreen)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Security & Limit notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.emeraldGreen, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Giao dịch được bảo vệ bởi chuẩn an toàn thanh toán PCI-DSS Quốc Tế & QĐ 2345/QĐ-NHNN.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.bottomBarCyan, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Miễn phí 100% nạp tiền từ tài khoản ngân hàng liên kết chính chủ.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Nhập mã PIN để hoàn tất nạp tiền', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    // 6 Dots PIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (idx) {
                        final isFilled = idx < _pin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? AppColors.emeraldGreen : Colors.transparent,
                            border: Border.all(color: isFilled ? AppColors.emeraldGreen : AppColors.textMutedLight, width: 2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _handleBiometric,
                          icon: const Icon(CupertinoIcons.viewfinder_circle_fill, color: Colors.white, size: 18),
                          label: const Text('Sinh trắc học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emeraldGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => context.push('/auth/forgot-pin'),
                          child: const Text(
                            'Quên mã PIN?',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              // Numpad Light Glass
              Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
                child: Column(
                  children: [
                    _buildNumpadRow(['1', '2', '3']),
                    const SizedBox(height: 10),
                    _buildNumpadRow(['4', '5', '6']),
                    const SizedBox(height: 10),
                    _buildNumpadRow(['7', '8', '9']),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Biometrics Button
                        InkWell(
                          onTap: _handleBiometric,
                          borderRadius: BorderRadius.circular(34),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.4), width: 1.2),
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.viewfinder_circle_fill, color: AppColors.emeraldGreen, size: 26),
                            ),
                          ),
                        ),
                        _buildNumpadBtn('0'),
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: IconButton(
                            icon: const Icon(CupertinoIcons.delete_left_fill, color: AppColors.primaryDark, size: 26),
                            onPressed: _handleBackspace,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium(
              color: isHighlight ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildNumpadBtn(d)).toList(),
    );
  }

  Widget _buildNumpadBtn(String digit) {
    return InkWell(
      onTap: () => _handlePinInput(digit),
      borderRadius: BorderRadius.circular(34),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}
