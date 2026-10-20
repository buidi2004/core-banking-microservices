import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

class TransferResultScreen extends StatefulWidget {
  final String recipient;
  final String? phoneNumber;
  final double amount;
  final String note;
  final String? transactionId;
  final String status;

  const TransferResultScreen({
    super.key,
    required this.recipient,
    this.phoneNumber,
    required this.amount,
    required this.note,
    this.transactionId,
    this.status = 'SUCCESS',
  });

  @override
  State<TransferResultScreen> createState() => _TransferResultScreenState();
}

class _TransferResultScreenState extends State<TransferResultScreen> {
  bool _isBalanceVisible = true;
  bool _isBeneficiarySaved = false;
  bool _isRecurringScheduled = false;

  late final String _txId;
  late final String _napasTraceNo;
  late final String _timestamp;
  String _sourceAccount = '';
  double? _postTransferBalance;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _txId = widget.transactionId ?? 'SHB${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}882';
    _napasTraceNo = '882${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
    _timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _loadSourceAccount();
    _loadPostTransferBalance();
  }

  Future<void> _loadPostTransferBalance() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() => _postTransferBalance = wallet.balance);
      }
    } catch (_) {}
  }

  Future<void> _loadSourceAccount() async {
    try {
      const storage = FlutterSecureStorage();
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (phone != null && phone.isNotEmpty && mounted) {
        setState(() => _sourceAccount = phone);
      } else {
        final profile = await ProfileRemoteDataSource().getMe();
        final p = profile['phoneNumber']?.toString();
        if (p != null && mounted) {
          setState(() => _sourceAccount = p);
        }
      }
    } catch (_) {}
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _recurringCycle = 'Ngày 05 hàng tháng';

  void _showCyclePicker(StateSetter setModalState) {
    final cycles = [
      'Hàng ngày (09:00)',
      'Hàng tuần (Thứ 2 hàng tuần)',
      'Ngày 01 hàng tháng (Đầu tháng)',
      'Ngày 05 hàng tháng (Ngày nhận lương)',
      'Ngày 15 hàng tháng (Giữa tháng)',
      'Ngày 25 hàng tháng',
      'Ngày cuối cùng của tháng',
    ];
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chọn chu kỳ chuyển tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cycles.map((c) {
              final isSel = _recurringCycle == c;
              return ListTile(
                title: Text(c, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? AppColors.primary : AppColors.textPrimaryLight)),
                trailing: isSel ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.primary, size: 18) : null,
                onTap: () {
                  setModalState(() => _recurringCycle = c);
                  setState(() => _recurringCycle = c);
                  Navigator.pop(dialogCtx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showScheduleModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                  const Icon(CupertinoIcons.calendar_today, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đặt lịch chuyển tiền định kỳ',
                      style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tự động chuyển ${CurrencyFormatter.formatVND(widget.amount)} đến "${widget.recipient}" theo chu kỳ bạn chọn.',
                style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.repeat, color: AppColors.primary),
                title: const Text('Chu kỳ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(_recurringCycle, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
                onTap: () => _showCyclePicker(setModalState),
              ),
              const Divider(height: 1),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen),
                title: Text('Xác thực Smart OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Tự động ký theo QĐ 2345/QĐ-NHNN', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _isRecurringScheduled = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thiết lập lịch chuyển tiền định kỳ: $_recurringCycle!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Xác nhận đặt lịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            children: [
              // Top Bank Header Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.building_2_fill, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NGÂN HÀNG SỐ SEN HỒNG',
                    style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Success Animated Circle Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emeraldGreen.withOpacity(0.2),
                      AppColors.bottomBarCyan.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emeraldGreen, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emeraldGreen.withOpacity(0.3),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen, size: 44),
              ),
              const SizedBox(height: 12),

              Text(
                'Giao Dịch Thành Công',
                style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_timestamp, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 14),

              Text(
                CurrencyFormatter.formatVND(widget.amount),
                style: AppTypography.displayLarge(color: AppColors.emeraldGreen).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),

              // Official Electronic Banking Receipt Ticket Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      // Digital Stamp Watermark Seal
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'CHỨNG TỪ ĐIỆN TỬ - SMART OTP XÁC THỰC',
                              style: AppTypography.bodySmall(color: AppColors.primary).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Core Banking Ref
                      _buildCopyableRow('Mã giao dịch (FT)', _txId, 'Mã giao dịch'),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Napas Trace
                      _buildCopyableRow('Mã tham chiếu Napas', _napasTraceNo, 'Mã Napas Trace'),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Method
                      _buildReceiptRow('Phương thức', 'Chuyển tiền nội bộ SenBank 24/7'),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Source Account
                      _buildReceiptRow('Tài khoản nguồn', '${_sourceAccount.isNotEmpty ? _sourceAccount : 'Tài khoản chính'} (Ví Sen Hồng)'),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Recipient
                      _buildReceiptRow('Người thụ hưởng', widget.recipient.toUpperCase(), isHighlight: true),
                      if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) ...[
                        const Divider(height: 16, color: AppColors.dividerLight),
                        _buildReceiptRow('Tài khoản / SĐT nhận', widget.phoneNumber!),
                      ],
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Bank
                      _buildReceiptRow('Ngân hàng thụ hưởng', 'Ví Sen Hồng (Nội bộ)'),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Fee
                      _buildReceiptRow('Phí dịch vụ', '0 đ (Miễn phí)', valueColor: AppColors.emeraldGreen),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Note
                      _buildReceiptRow('Lời nhắn', widget.note.isEmpty ? 'Chuyen tiền' : widget.note),
                      const Divider(height: 16, color: AppColors.dividerLight),

                      // Balance with eye toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Số dư ví sau GD', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                child: Icon(
                                  _isBalanceVisible ? CupertinoIcons.eye_fill : CupertinoIcons.eye_slash_fill,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _isBalanceVisible
                                  ? (_postTransferBalance != null
                                      ? CurrencyFormatter.formatVND(_postTransferBalance!)
                                      : 'Đang cập nhật...')
                                  : '******** đ',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Online Receipt Verification QR Code Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            QrImageView(
                              data: 'https://verify.senbank.vn/receipt/$_txId?amount=${widget.amount.toInt()}',
                              version: QrVersions.auto,
                              size: 64,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimaryLight),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimaryLight),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tra cứu biên lai điện tử',
                                    style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Quét mã QR để tra cứu chứng từ gốc có chữ ký số. Hợp lệ theo Nghị định 52/2024/NĐ-CP.',
                                    style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Quick Contact & Schedule Toggles
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isBeneficiarySaved = !_isBeneficiarySaved);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isBeneficiarySaved ? 'Đã lưu "${widget.recipient}" vào danh bạ tin cậy!' : 'Đã xóa khỏi danh bạ'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _isBeneficiarySaved ? AppColors.emeraldGreen.withOpacity(0.12) : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isBeneficiarySaved ? AppColors.emeraldGreen : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isBeneficiarySaved ? CupertinoIcons.person_crop_circle_badge_checkmark : CupertinoIcons.person_badge_plus_fill,
                              size: 16,
                              color: _isBeneficiarySaved ? AppColors.emeraldGreen : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isBeneficiarySaved ? 'Đã lưu danh bạ' : 'Lưu thụ hưởng',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isBeneficiarySaved ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showScheduleModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _isRecurringScheduled ? AppColors.primary.withOpacity(0.12) : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isRecurringScheduled ? AppColors.primary : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.calendar_badge_plus,
                              size: 16,
                              color: _isRecurringScheduled ? AppColors.primary : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isRecurringScheduled ? 'Đã đặt định kỳ' : 'Chuyển định kỳ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isRecurringScheduled ? AppColors.primary : AppColors.textPrimaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // PDF Receipt & Share
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang tải biên lai điện tử định dạng PDF (kèm chữ ký số SHA-256)...')),
                        );
                      },
                      icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18, color: AppColors.primaryDark),
                      label: const Text('Tải biên lai PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimaryLight,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang tạo ảnh biên lai bảo mật để chia sẻ...')),
                        );
                      },
                      icon: const Icon(CupertinoIcons.share_up, size: 18, color: AppColors.primaryDark),
                      label: const Text('Chia sẻ ảnh GD'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimaryLight,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(CupertinoIcons.house_fill, size: 18),
                label: const Text('Về màn hình chính'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.pushReplacement('/transfer'),
                icon: const Icon(CupertinoIcons.repeat, size: 18),
                label: const Text('Thực hiện chuyển tiền mới'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 20),

              // Post-transfer Navigation Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.person_2_fill,
                        label: 'Quản lý danh bạ người thụ hưởng',
                        onTap: () => context.push('/beneficiaries'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.clock_fill,
                        label: 'Xem chi tiết giao dịch trong Lịch sử',
                        onTap: () => context.push('/history'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                        label: 'Tạo yêu cầu chia tiền nhóm cho khoản này',
                        onTap: () => context.push('/transfer/request'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode,
                        label: 'Mở mã QR cá nhân nhận tiền chuyển lại',
                        onTap: () => context.push('/my-qr'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        label: 'Quét mã VietQR thanh toán khác',
                        onTap: () => context.push('/scan-qr'),
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

  Widget _buildCopyableRow(String label, String value, String toastLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
        const SizedBox(width: 12),
        Flexible(
          child: GestureDetector(
            onTap: () => _copyToClipboard(value, toastLabel),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.doc_on_doc_fill, size: 15, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium(color: valueColor ?? AppColors.textPrimaryLight).copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
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

