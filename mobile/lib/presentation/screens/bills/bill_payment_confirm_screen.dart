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
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class BillPaymentConfirmScreen extends StatefulWidget {
  final String billId;
  final double amount;
  final String provider;
  final String customerCode;

  const BillPaymentConfirmScreen({
    super.key,
    required this.billId,
    required this.amount,
    required this.provider,
    required this.customerCode,
  });

  @override
  State<BillPaymentConfirmScreen> createState() => _BillPaymentConfirmScreenState();
}

class _BillPaymentConfirmScreenState extends State<BillPaymentConfirmScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _pin = '';
  bool _isSubmitting = false;
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;
  bool _autoDebit = false;

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

  IconData _getServiceIcon() {
    final p = widget.provider.toLowerCase();
    if (p.contains('evn') || p.contains('điện')) return CupertinoIcons.bolt_fill;
    if (p.contains('nước') || p.contains('sawaco') || p.contains('viwaco')) return CupertinoIcons.drop_fill;
    if (p.contains('vnpt') || p.contains('fpt') || p.contains('viettel') || p.contains('internet')) return CupertinoIcons.wifi;
    if (p.contains('truyền hình') || p.contains('k+')) return CupertinoIcons.tv_fill;
    if (p.contains('học phí') || p.contains('trường')) return CupertinoIcons.book_fill;
    return CupertinoIcons.square_list_fill;
  }

  Color _getServiceColor() {
    final p = widget.provider.toLowerCase();
    if (p.contains('evn') || p.contains('điện')) return AppColors.accentGold;
    if (p.contains('nước') || p.contains('sawaco') || p.contains('viwaco')) return AppColors.primary;
    if (p.contains('vnpt') || p.contains('fpt') || p.contains('internet')) return AppColors.emeraldGreen;
    return AppColors.primaryDark;
  }

  Future<void> _onBiometricPressed() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị chưa cài đặt bảo mật sinh trắc học')),
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực khuôn mặt / vân tay để thanh toán hóa đơn ${widget.provider}',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (authenticated) {
        HapticFeedback.heavyImpact();
        await _processPaymentWithoutPin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xác thực sinh trắc học: $e')),
        );
      }
    }
  }

  Future<void> _processPaymentWithoutPin() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final result = await BillRemoteDataSource().pay(
        walletId: wallet.walletId,
        billId: widget.billId,
        amount: widget.amount,
      );
      if (!mounted) return;
      context.go(
        '/transfer/result?recipient=${Uri.encodeComponent(widget.provider)}&amount=${widget.amount}&note=Thanh%20toan%20hoa%20don&transactionId=${result['transactionId'] ?? ''}&status=${result['status'] ?? 'SUCCESS'}',
      );
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Thanh toán không thành công',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pay(String pin) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      await WalletTransactionRemoteDataSource().verifyPin(pin);
      final result = await BillRemoteDataSource().pay(
        walletId: wallet.walletId,
        billId: widget.billId,
        amount: widget.amount,
      );
      if (!mounted) return;
      context.go(
        '/transfer/result?recipient=${Uri.encodeComponent(widget.provider)}&amount=${widget.amount}&note=Thanh%20toan%20hoa%20don&transactionId=${result['transactionId'] ?? ''}&status=${result['status'] ?? 'SUCCESS'}',
      );
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Thanh toán không thành công',
        );
        setState(() => _pin = '');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughBalance = _walletBalance >= widget.amount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Nhận Thanh Toán Hóa Đơn'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          _getServiceIcon(),
                          color: _getServiceColor(),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.provider,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã KH: ${widget.customerCode}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Bill Detail GlassCard
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildDetailRow('Đơn vị cung cấp', widget.provider),
                      const SizedBox(height: 10),
                      _buildDetailRow('Mã khách hàng / Danh bạ', widget.customerCode),
                      const SizedBox(height: 10),
                      _buildDetailRow('Kỳ cước thanh toán', 'Kỳ gần nhất'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Phí giao dịch', '0 đ (Miễn phí)', valueColor: AppColors.emeraldGreen),
                      const Divider(height: 24, color: AppColors.cardBorderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng tiền thanh toán', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.formatVND(widget.amount),
                            style: AppTypography.displayMedium(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      if (CurrencyFormatter.toVietnameseWords(widget.amount).isNotEmpty) ...[
                        const SizedBox(height: 6),
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
                  child: Column(
                    children: [
                      Row(
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
                      const Divider(height: 20, color: AppColors.cardBorderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(CupertinoIcons.arrow_2_circlepath_circle, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Tự động trừ tiền kỳ tiếp theo', style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Switch.adaptive(
                            value: _autoDebit,
                            activeTrackColor: AppColors.primary,
                            onChanged: (v) => setState(() => _autoDebit = v),
                          ),
                        ],
                      ),
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
                      _isSubmitting ? 'Đang xác thực giao dịch an toàn...' : 'Nhập mã PIN 6 số để xác nhận',
                      style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bảo mật 2 lớp PCI-DSS • Hóa đơn điện tử e-Invoice',
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isSubmitting)
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
                    if (value.length == 6) _pay(value);
                  },
                  onBiometricPressed: _onBiometricPressed,
                ),

              const SizedBox(height: 16),

              // Legal Notice Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chứng từ thanh toán hóa đơn điện tử có giá trị pháp lý theo Thông tư 78/2021/TT-BTC của Bộ Tài chính.',
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall(color: valueColor ?? AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}