import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class WithdrawConfirmScreen extends StatefulWidget {
  final double amount;
  final String bank;
  final String acc;
  final String bankAccountId;

  const WithdrawConfirmScreen({
    super.key,
    required this.amount,
    required this.bank,
    required this.acc,
    required this.bankAccountId,
  });

  @override
  State<WithdrawConfirmScreen> createState() => _WithdrawConfirmScreenState();
}

class _WithdrawConfirmScreenState extends State<WithdrawConfirmScreen> {
  String _pin = '';
  bool _isLoading = false;
  String _holderName = 'CHỦ TÀI KHOẢN';

  @override
  void initState() {
    super.initState();
    _loadHolderName();
  }

  Future<void> _loadHolderName() async {
    try {
      final cachedName = await AppSecureStorage.safeRead(AppSecureStorage.instance, key: AppConstants.keyFullName);
      if (cachedName != null && cachedName.isNotEmpty && mounted) {
        setState(() => _holderName = cachedName.toUpperCase());
      }
      final profile = await ProfileRemoteDataSource().getMe();
      final name = profile['fullName'] as String?;
      if (name != null && name.isNotEmpty && mounted) {
        setState(() => _holderName = name.toUpperCase());
      }
    } catch (_) {}
  }

  void _handleDigit(String d) {
    if (_pin.length < 6) {
      HapticFeedback.selectionClick();
      setState(() => _pin += d);
      if (_pin.length == 6) {
        _submitWithdraw();
      }
    }
  }

  void _handleBackspace() {
    if (_pin.isNotEmpty) {
      HapticFeedback.selectionClick();
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

  Future<void> _submitWithdraw() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final api = WalletTransactionRemoteDataSource();
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final pinToken = await api.verifyPin(_pin);
      final result = await api.withdraw(
        walletId: wallet.walletId,
        bankAccountId: widget.bankAccountId,
        amount: widget.amount,
        pinToken: pinToken,
      );
      if (!mounted) return;
      context.go(
        '/transfer/result?recipient=${Uri.encodeComponent('${widget.bank} - ${widget.acc}')}&amount=${widget.amount}&note=Rut%20tien&transactionId=${result['transactionId'] ?? ''}&status=${result['status'] ?? 'SUCCESS'}',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _pin = '');
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Rút tiền không thành công',
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
        title: const Text('Xác Nhận Rút Tiền'),
        backgroundColor: Colors.transparent,
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
                      title: 'Lưu ý an toàn rút tiền',
                      message: 'Tiền chỉ được rút về tài khoản ngân hàng chính chủ. Quý khách vui lòng kiểm tra chính xác số tài khoản trước khi nhập mã PIN.',
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
                            Text('Số tiền rút về tài khoản', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.formatVND(widget.amount),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Divider(height: 28, color: AppColors.cardBorderLight),
                            _buildRow('Ngân hàng nhận', widget.bank),
                            const SizedBox(height: 10),
                            _buildRow('Số tài khoản', widget.acc),
                            const SizedBox(height: 10),
                            _buildRow('Người thụ hưởng', _holderName),
                            const SizedBox(height: 10),
                            _buildRow('Kênh chuyển mạch', 'NAPAS 24/7 Realtime'),
                            const SizedBox(height: 10),
                            _buildRow('Phí dịch vụ', 'Miễn phí (0đ)', isHighlight: true),
                            const SizedBox(height: 10),
                            _buildRow('Thời gian nhận', 'Tức thời (trong 30 giây)'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Daily Limit Card
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
                                    Icon(CupertinoIcons.chart_pie_fill, color: AppColors.bottomBarCyan, size: 18),
                                    SizedBox(width: 8),
                                    Text('Hạn mức rút tiền trong ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
                                  ],
                                ),
                                Text('50.000.000 đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ((widget.amount + 5000000) / 50000000).clamp(0.05, 1.0),
                                backgroundColor: AppColors.dividerLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Giao dịch này: ${CurrencyFormatter.formatVND(widget.amount)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                const Text('Còn lại: 45.000.000 đ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emeraldGreen)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Security & Regulatory Compliance Card
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
                              Icon(CupertinoIcons.lock_shield_fill, color: AppColors.emeraldGreen, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Giao dịch được mã hóa an toàn qua Smart OTP PKI và xác thực đa yếu tố theo QĐ 2345/QĐ-NHNN.',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lưu ý: Chỉ rút tiền về tài khoản ngân hàng chính chủ trùng tên với tài khoản SenBank.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Nhập mã PIN hoặc xác thực FaceID để ký lệnh rút tiền', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

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
                            color: isFilled ? AppColors.primary : Colors.transparent,
                            border: Border.all(color: isFilled ? AppColors.primary : AppColors.textMutedLight, width: 2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

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

  Widget _buildNumpadBtn(String label) {
    return InkWell(
      onTap: () => _handleDigit(label),
      borderRadius: BorderRadius.circular(34),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
          ),
        ),
      ),
    );
  }
}
