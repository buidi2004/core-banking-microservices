import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/bill_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';

class PhoneTopupConfirmScreen extends StatefulWidget {
  final String phoneNumber;
  final double amount;
  final String telco;

  const PhoneTopupConfirmScreen({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.telco,
  });

  @override
  State<PhoneTopupConfirmScreen> createState() => _PhoneTopupConfirmScreenState();
}

class _PhoneTopupConfirmScreenState extends State<PhoneTopupConfirmScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _pin = '';
  bool _loading = false;
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;
  bool _maskPhone = true;

  double get _discount => widget.amount * 0.03; // Chiết khấu 3%
  double get _finalAmount => widget.amount - _discount;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          _walletBalance = wallet.balance;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _onBiometricPressed() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        if (!mounted) return;
        AppAlerts.showWarning(context, 'Thiết bị chưa cài đặt hoặc không hỗ trợ sinh trắc học', title: 'Sinh trắc học');
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực khuôn mặt / vân tay để nạp ${CurrencyFormatter.formatVND(widget.amount)}',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (authenticated) {
        if (!mounted) return;
        if (_walletBalance < _finalAmount) {
          AppAlerts.showWarning(
            context,
            'Số dư ví không đủ để thanh toán. Vui lòng nạp thêm tiền.',
            title: 'Số dư không đủ',
            actionLabel: 'Nạp tiền',
            onAction: () => context.push('/deposit'),
          );
          return;
        }
        HapticFeedback.heavyImpact();
        await _processTopupWithoutPin();
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showError(context, 'Lỗi xác thực sinh trắc học: $e', title: 'Xác thực thất bại');
      }
    }
  }

  Future<void> _processTopupWithoutPin() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final result = await BillRemoteDataSource().topup(
        walletId: wallet.walletId,
        phoneNumber: widget.phoneNumber,
        amount: widget.amount,
      );
      if (!mounted) return;
      context.go(
        '/transfer/result?recipient=${Uri.encodeComponent('${widget.telco} ${widget.phoneNumber}')}&amount=${widget.amount}&note=Nap%20tien%20dien%20thoai&transactionId=${result['transactionId'] ?? ''}&status=${result['status'] ?? 'SUCCESS'}',
      );
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Giao dịch không thành công',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(String pin) async {
    if (_loading) return;

    if (_walletBalance < _finalAmount) {
      AppAlerts.showWarning(
        context,
        'Số dư ví không đủ để thanh toán. Vui lòng nạp thêm tiền.',
        title: 'Số dư không đủ',
        actionLabel: 'Nạp tiền',
        onAction: () => context.push('/deposit'),
      );
      setState(() => _pin = '');
      return;
    }

    setState(() => _loading = true);
    try {
      await WalletTransactionRemoteDataSource().verifyPin(pin);
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final result = await BillRemoteDataSource().topup(
        walletId: wallet.walletId,
        phoneNumber: widget.phoneNumber,
        amount: widget.amount,
      );
      if (!mounted) return;
      context.go(
        '/transfer/result?recipient=${Uri.encodeComponent('${widget.telco} ${widget.phoneNumber}')}&amount=${widget.amount}&note=Nap%20tien%20dien%20thoai&transactionId=${result['transactionId'] ?? ''}&status=${result['status'] ?? 'SUCCESS'}',
      );
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Giao dịch không thành công',
        );
        setState(() => _pin = '');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getTelcoColor() {
    switch (widget.telco.toLowerCase()) {
      case 'viettel':
        return const Color(0xFFE50019);
      case 'vinaphone':
        return const Color(0xFF0072BC);
      case 'mobifone':
        return const Color(0xFF005BAA);
      case 'vietnamobile':
        return const Color(0xFFFF6600);
      case 'wintel':
        return const Color(0xFFED1C24);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughBalance = _walletBalance >= _finalAmount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Nhận Nạp Tiền'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Summary Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.bottomBarCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bottomBarGlow.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.device_phone_portrait,
                          color: _getTelcoColor(),
                          size: 28,
                        ),
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
                                widget.telco.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.accentGold.withOpacity(0.6), width: 0.8),
                                ),
                                child: const Text(
                                  '-3% HOÀN TIỀN',
                                  style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _maskPhone
                                      ? (widget.phoneNumber.length >= 7
                                          ? '${widget.phoneNumber.substring(0, 3)} •••• ${widget.phoneNumber.substring(widget.phoneNumber.length - 3)}'
                                          : widget.phoneNumber)
                                      : widget.phoneNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _maskPhone = !_maskPhone);
                                },
                                child: Icon(
                                  _maskPhone ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                                  color: Colors.white70,
                                  size: 18,
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

              const SizedBox(height: 18),

              // Transaction Detail GlassCard
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildDetailRow('Mệnh giá nạp thẻ', CurrencyFormatter.formatVND(widget.amount)),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        'Chiết khấu ưu đãi Sen Hồng (3%)',
                        '-${CurrencyFormatter.formatVND(_discount)}',
                        valueColor: AppColors.emeraldGreen,
                        isBold: true,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow('Phí dịch vụ', '0 đ (Miễn phí)', valueColor: AppColors.emeraldGreen),
                      const Divider(height: 24, color: AppColors.cardBorderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thực thu thanh toán', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.formatVND(_finalAmount),
                            style: AppTypography.displayMedium(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      if (CurrencyFormatter.toVietnameseWords(_finalAmount).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(_finalAmount)} đồng',
                            style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Source Wallet Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(CupertinoIcons.creditcard_fill, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nguồn tiền thanh toán', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 2),
                            Text('Ví Sen Hồng Chính Chủ', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingBalance
                                  ? 'Đang tải số dư...'
                                  : 'Khả dụng: ${CurrencyFormatter.formatVND(_walletBalance)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: hasEnoughBalance ? AppColors.emeraldGreen : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!hasEnoughBalance && !_isLoadingBalance)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => context.push('/deposit'),
                          child: const Text('Nạp thêm', style: TextStyle(fontSize: 11, color: Colors.white)),
                        )
                      else
                        const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // PIN Verification Header
              Center(
                child: Column(
                  children: [
                    Text(
                      _loading ? 'Đang xác thực giao dịch an toàn...' : 'Nhập mã PIN 6 số để xác nhận',
                      style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bảo mật 2 lớp PCI-DSS • Chữ ký số Smart OTP',
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else
                CustomPinNumpad(
                  pin: _pin,
                  maxDigits: 6,
                  showBiometric: true,
                  onPinChanged: (value) {
                    setState(() => _pin = value);
                    if (value.length == 6) _submit(value);
                  },
                  onBiometricPressed: _onBiometricPressed,
                ),

              const SizedBox(height: 16),

              // Security notice badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Giao dịch nạp tiền điện thoại được mã hóa đầu cuối và bảo vệ bởi Liên minh Napas 247 & SenBank.',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
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
            style: AppTypography.titleSmall(color: valueColor ?? AppColors.textPrimaryLight).copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}