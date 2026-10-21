import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/constants/backend_capabilities.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class ConfirmTransferScreen extends StatefulWidget {
  final String recipient;
  final String? phoneNumber;
  final String? walletId;
  final double amount;
  final String note;

  const ConfirmTransferScreen({
    super.key,
    required this.recipient,
    this.phoneNumber,
    this.walletId,
    required this.amount,
    required this.note,
  });

  @override
  State<ConfirmTransferScreen> createState() => _ConfirmTransferScreenState();
}

class _ConfirmTransferScreenState extends State<ConfirmTransferScreen> {
  bool _saveBeneficiary = true;
  bool _showPinModal = false;
  String _pin = '';
  bool _isSubmitting = false;
  double _fee = 0;

  double _walletBalance = 0.0;
  String _sourceWalletId = '';
  String _sourceUserId = '';
  String _recipientName = '';
  String _recipientPhone = '';
  String _targetWalletId = '';
  String _targetUserId = '';

  /// MOB-017: idempotency key sinh MỘT lần khi người dùng bắt đầu xác nhận.
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _recipientName = widget.recipient;
    _recipientPhone = widget.phoneNumber ?? '';
    _targetWalletId = widget.walletId ?? '';
    _loadFee();
    _loadWalletAndRecipient();
  }

  bool _isLoadingWallet = true;

  Future<void> _loadWalletAndRecipient() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      // MOB-014/OPT-01: lấy userId từ session/secure storage, fallback về ví.
      final storedUserId = await AppSecureStorage.safeRead(
        AppSecureStorage.instance,
        key: AppConstants.keyUserId,
      );
      if (mounted) {
        setState(() {
          _walletBalance = wallet.balance;
          _sourceWalletId = wallet.walletId;
          _sourceUserId = (storedUserId != null && storedUserId.isNotEmpty)
              ? storedUserId
              : wallet.userId;
          _isLoadingWallet = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingWallet = false);
    }

    if (_targetWalletId.isEmpty) {
      try {
        final query = _recipientPhone.isNotEmpty ? _recipientPhone : widget.recipient;
        final info = await TransferRemoteDataSource().getRecipient(query);
        if (mounted) {
          setState(() {
            _recipientName = (info['fullName'] ?? info['maskedName'] ?? widget.recipient).toString();
            _recipientPhone = (info['phoneNumber'] ?? _recipientPhone).toString();
            _targetWalletId = (info['walletId'] ?? '').toString();
            // recipient-info trả ownerId => không cần GET /wallets/{id} nữa.
            _targetUserId = (info['ownerId'] ?? '').toString();
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadFee() async {
    try {
      final fee = await TransferRemoteDataSource().estimateFee(widget.amount);
      if (mounted) setState(() => _fee = fee);
    } catch (_) {
      // Keep the summary usable while the fee endpoint is unavailable.
    }
  }

  Future<void> _onPinEntered(String val) async {
    if (_isSubmitting) return;
    setState(() => _pin = val);
    if (val.length == 6) {
      HapticFeedback.mediumImpact();
      _ensureIdempotencyKey();
      await _submitTransfer(val);
    }
  }

  /// MOB-017: sinh idempotency key MỘT lần khi người dùng bắt đầu xác nhận;
  /// mọi retry mạng phải dùng lại đúng key này.
  void _ensureIdempotencyKey() {
    _idempotencyKey ??=
        'MOBILE-$_sourceUserId-$_targetUserId-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _submitTransfer(String pin) async {
    if (_isSubmitting) return;

    final totalRequired = widget.amount + _fee;
    if (!_isLoadingWallet && _walletBalance < totalRequired) {
      HapticFeedback.vibrate();
      AppAlerts.showError(
        context,
        'Số dư ví (${CurrencyFormatter.formatVND(_walletBalance)}) không đủ để chuyển ${CurrencyFormatter.formatVND(totalRequired)} (bao gồm phí). Vui lòng nạp thêm tiền.',
        title: 'Số dư không đủ',
        actionLabel: 'Nạp tiền',
        onAction: () => context.push('/deposit'),
      );
      return;
    }

    _ensureIdempotencyKey();
    setState(() => _isSubmitting = true);
    try {
      final transferApi = TransferRemoteDataSource();

      // Xác thực mã PIN trước với Identity Service để nhận pinToken
      final pinToken = await WalletTransactionRemoteDataSource().verifyPin(pin);

      // MOB-014 / OPT-01: dùng userId (session + recipient-info) thay vì tra ví.
      String sourceUserId = _sourceUserId;
      if (sourceUserId.isEmpty) {
        final wallet = await WalletRemoteDataSource().getMyWallet();
        sourceUserId = wallet.userId;
      }
      String targetUserId = _targetUserId;
      if (targetUserId.isEmpty) {
        final query = _recipientPhone.isNotEmpty ? _recipientPhone : widget.recipient;
        final recipient = await transferApi.getRecipient(query);
        targetUserId = (recipient['ownerId'] ?? '').toString();
      }

      final initialized = await transferApi.initTransfer(
        sourceUserId: sourceUserId,
        targetUserId: targetUserId,
        amount: widget.amount,
        note: widget.note,
        idempotencyKey: _idempotencyKey,
        sourceWalletId: _sourceWalletId,
        targetWalletId: _targetWalletId,
        pinToken: pinToken,
      );
      final transactionId = (initialized['transactionId'] ?? initialized['id'] ?? '').toString();
      final result = await transferApi.confirmTransfer(
        transactionId: transactionId,
        pin: pin,
        pinToken: pinToken,
      );

      final status = (result['status'] ?? '').toString().toUpperCase();
      if (status == 'FAILED') {
        final reason = (result['failureReason'] ?? result['message'] ?? 'Số dư khả dụng không đủ').toString();
        throw Exception(reason.contains('INSUFFICIENT') || reason.contains('<')
            ? 'Số dư khả dụng trong ví không đủ để thực hiện giao dịch này.'
            : reason);
      }

      if (_saveBeneficiary && _recipientPhone.isNotEmpty && BackendCapabilities.beneficiaries) {
        try {
          await BeneficiaryRemoteDataSource().add({
            'beneficiaryWalletId': _targetWalletId,
            'nickname': _recipientName,
            'bankCode': 'SENHONG',
            'accountNumber': _recipientPhone,
          });
        } catch (_) {}
      }

      if (!mounted) return;
      final uri = Uri(
        path: '/transfer/result',
        queryParameters: {
          'recipient': _recipientName,
          'phoneNumber': _recipientPhone,
          'amount': widget.amount.toString(),
          'note': widget.note,
          'transactionId': transactionId,
          'status': result['status']?.toString() ?? 'SUCCESS',
        },
      );
      context.go(uri.toString());
    } catch (error) {
      HapticFeedback.vibrate();
      if (mounted) {
        setState(() => _pin = '');
        final msg = extractErrorMessage(error);
        final isPinNotSet = msg.contains('chưa thiết lập mã PIN');
        final isLocked = msg.contains('khóa 15 phút') || msg.contains('temporarily locked');

        if (isLocked) {
          setState(() => _showPinModal = false);
          _showAccountLockedDialog();
        } else {
          AppAlerts.showError(
            context,
            msg,
            title: 'Chuyển tiền thất bại',
            actionLabel: isPinNotSet ? 'Cài mã PIN' : null,
            onAction: isPinNotSet ? () => context.push('/auth/forgot-pin') : null,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAccountLockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.lock_fill, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Tài Khoản Tạm Khóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: const Text(
          'Tài khoản đã bị tạm khóa 15 phút do nhập sai mã xác thực/PIN quá 3 lần liên tiếp.\n\nBạn có thể cấp lại mã PIN mới ngay lập tức qua OTP hoặc liên hệ tổng đài CSKH.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/support/help-center');
            },
            child: const Text('CSKH 24/7'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/auth/forgot-pin');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Cấp lại mã PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRequired = widget.amount + _fee;
    final isInsufficientBalance = !_isLoadingWallet && _walletBalance < totalRequired;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Nhận Giao Dịch'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_showPinModal) {
                    setState(() => _showPinModal = false);
                  } else {
                    context.pop();
                  }
                },
        ),
      ),
      body: PopScope(
        canPop: !_isSubmitting,
        child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Summary
              Center(
                child: Column(
                  children: [
                    Text('Tổng tiền thanh toán', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatVND(widget.amount),
                      style: AppTypography.displayLarge(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (isInsufficientBalance) ...[
                InlineWarningBanner(
                  title: 'Số dư khả dụng không đủ',
                  message: 'Tổng số tiền cần thanh toán (${CurrencyFormatter.formatVND(totalRequired)}) vượt quá số dư ví hiện có (${CurrencyFormatter.formatVND(_walletBalance)}). Vui lòng nạp thêm tiền để tiếp tục.',
                  type: AlertType.error,
                  actionLabel: 'Nạp tiền ngay',
                  onAction: () => context.push('/deposit'),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const InlineWarningBanner(
                  title: 'Cảnh báo an toàn chuyển tiền',
                  message: 'Quý khách vui lòng kiểm tra kỹ số tài khoản và họ tên người nhận. Tuyệt đối không chia sẻ mã PIN hay OTP cho bất kỳ ai (kể cả nhân viên SenBank).',
                  type: AlertType.warning,
                ),
                const SizedBox(height: 16),
              ],

              // Details Card (GlassCard)
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow('Người nhận', _recipientName.toUpperCase()),
                      if (_recipientPhone.isNotEmpty) ...[
                        const Divider(height: 20, color: AppColors.cardBorderLight),
                        _buildInfoRow('Số tài khoản / SĐT', _recipientPhone),
                      ],
                      const Divider(height: 20, color: AppColors.cardBorderLight),
                      _buildInfoRow('Phương thức', 'Ví Sen Hồng (Nội bộ 24/7)'),
                      const Divider(height: 20, color: AppColors.cardBorderLight),
                      _buildInfoRow('Phí giao dịch', CurrencyFormatter.formatVND(_fee), valueColor: AppColors.emeraldGreen),
                      const Divider(height: 20, color: AppColors.cardBorderLight),
                      _buildInfoRow('Nội dung', widget.note.isEmpty ? 'Chuyen tien' : widget.note),
                      const Divider(height: 20, color: AppColors.cardBorderLight),
                      _buildInfoRow(
                        'Nguồn tiền',
                        _isLoadingWallet
                            ? 'Ví chính (Đang tải...)'
                            : 'Ví chính (Khả dụng: ${CurrencyFormatter.formatVND(_walletBalance)})',
                        valueColor: isInsufficientBalance ? AppColors.error : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Checkbox(
                    value: _saveBeneficiary,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _saveBeneficiary = v ?? true),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _saveBeneficiary = !_saveBeneficiary),
                      child: Text(
                        'Lưu vào danh bạ người thụ hưởng',
                        style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (!_showPinModal) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isInsufficientBalance
                        ? () {
                            HapticFeedback.vibrate();
                            AppAlerts.showError(
                              context,
                              'Số dư ví không đủ để thực hiện giao dịch (${CurrencyFormatter.formatVND(_walletBalance)} < ${CurrencyFormatter.formatVND(totalRequired)}). Vui lòng nạp thêm tiền.',
                              title: 'Số dư không đủ',
                              actionLabel: 'Nạp tiền',
                              onAction: () => context.push('/deposit'),
                            );
                          }
                        : (_isSubmitting ? null : () => setState(() => _showPinModal = true)),
                    icon: Icon(
                      isInsufficientBalance
                          ? CupertinoIcons.exclamationmark_triangle_fill
                          : CupertinoIcons.lock_shield_fill,
                      size: 18,
                    ),
                    label: Text(
                      isInsufficientBalance
                          ? 'Số dư không đủ để chuyển tiền'
                          : 'Xác nhận & Ký mã PIN',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInsufficientBalance
                          ? AppColors.cardBorderLight
                          : AppColors.primary,
                      foregroundColor: isInsufficientBalance
                          ? Colors.white38
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : () => context.pop(),
                        icon: const Icon(CupertinoIcons.pencil, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Sửa số tiền'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : () => context.go('/transfer'),
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Hủy giao dịch'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondaryLight,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Center(
                  child: Text(
                    _isSubmitting ? 'Đang xử lý giao dịch an toàn...' : 'Nhập mã PIN 6 số để duyệt chuyển tiền',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
                  ),
                ),
                const SizedBox(height: 14),
                if (_isSubmitting) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(radius: 14),
                        const SizedBox(height: 16),
                        Text(
                          'Đang kết nối hệ thống & ký số giao dịch...',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleSmall(color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vui lòng không tắt ứng dụng trong lúc xử lý',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  CustomPinNumpad(
                    pin: _pin,
                    maxDigits: 6,
                    showBiometric: true,
                    onPinChanged: _onPinEntered,
                    onBiometricPressed: () => _submitTransfer(_pin),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _showPinModal = false;
                        _pin = '';
                      }),
                      icon: const Icon(CupertinoIcons.doc_text_fill, size: 16, color: AppColors.primary),
                      label: const Text('Quay lại xem chi tiết giao dịch', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push('/auth/forgot-pin'),
                      icon: const Icon(CupertinoIcons.lock_fill, size: 16, color: AppColors.primaryDark),
                      label: const Text('Quên mã PIN giao dịch? Cấp lại mã PIN', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_fill,
                        label: 'Quên hoặc muốn đổi mã PIN thanh toán',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Cài đặt an toàn bảo mật & Smart OTP',
                        onTap: () => context.push('/settings/security'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_fill,
                        label: 'Trung tâm trợ giúp khẩn cấp CSKH 24/7',
                        onTap: () => context.push('/support/help-center'),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.titleMedium(color: valueColor ?? AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
