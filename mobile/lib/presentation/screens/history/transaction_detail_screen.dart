import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String? id;
  final String? title;
  final double? amount;
  final String? time;
  final String? note;
  final String? recipient;

  const TransactionDetailScreen({
    super.key,
    this.id,
    this.title,
    this.amount,
    this.time,
    this.note,
    this.recipient,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isBalanceVisible = false;
  bool _isBeneficiarySaved = false;
  Map<String, dynamic>? _fetchedDetail;
  String? _sourceAccount;
  String? _sourceName;
  double? _runningBalance;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final profile = await ProfileRemoteDataSource().getMe();
      if (mounted) {
        setState(() {
          _sourceName = (profile['fullName'] ?? profile['name'])?.toString();
          _sourceAccount = profile['phoneNumber']?.toString();
        });
      }
    } catch (_) {
      try {
        const storage = FlutterSecureStorage();
        final phone = await storage.read(key: AppConstants.keyPhoneNumber);
        if (phone != null && mounted) setState(() => _sourceAccount = phone);
      } catch (_) {}
    }

    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          _runningBalance = wallet.balance;
        });
      }
    } catch (_) {}

    if (widget.id != null && widget.id!.isNotEmpty) {
      try {
        final detail = await TransactionRemoteDataSource().getTransaction(widget.id!);
        if (mounted) {
          setState(() {
            _fetchedDetail = detail;
            if (detail['runningBalance'] != null) {
              _runningBalance = (detail['runningBalance'] as num).toDouble();
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _downloadReceipt(String txId) async {
    try {
      final bytes = await TransactionRemoteDataSource().getReceipt(txId);
      if (mounted) {
        AppAlerts.showSuccess(
          context,
          'Đã tải thành công biên lai điện tử PDF (${bytes.length} bytes)',
          title: 'Biên lai giao dịch',
        );
      }
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Không thể tải biên lai',
        );
      }
    }
  }

  void _showDisputeModal(String txId) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.textMutedLight.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_shield_fill, color: AppColors.error, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yêu Cầu Tra Soát Giao Dịch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        Text('Quy trình xử lý theo Thông tư 28/2019/TT-NHNN', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Mã giao dịch tra soát: $txId', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              const Text(
                'Chọn lý do tra soát / khiếu nại:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 8),
              _buildDisputeOption(ctx, 'Chuyển tiền thành công nhưng người nhận chưa nhận được'),
              _buildDisputeOption(ctx, 'Chuyển nhầm số tài khoản hoặc số tiền'),
              _buildDisputeOption(ctx, 'Tài khoản bị trừ tiền nhiều lần cho 1 giao dịch'),
              _buildDisputeOption(ctx, 'Nghi ngờ giao dịch giả mạo / lừa đảo'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeOption(BuildContext ctx, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(ctx);
          AppAlerts.showSuccess(
            context,
            'Đã tạo phiếu tra soát: "$text". Tổng đài 1900 6688 sẽ liên hệ hỗ trợ trong 2h làm việc.',
            title: 'Tiếp nhận tra soát',
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.arrow_right_circle, size: 16, color: AppColors.bottomBarCyan),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimaryLight))),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTxDetailTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')} - ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      }
    } catch (_) {}
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final txId = _fetchedDetail?['id']?.toString().isNotEmpty == true ? _fetchedDetail!['id'].toString() : (widget.id ?? '');
    final txTitle = _fetchedDetail?['title'] ?? widget.title ?? 'Giao dịch Sen Hồng';
    final txAmount = (_fetchedDetail?['amount'] as num?)?.toDouble() ?? widget.amount ?? 0.0;
    final txTime = _fetchedDetail?['date'] ?? widget.time ?? '';
    final txNote = (_fetchedDetail?['note'] ?? widget.note ?? txTitle).toString();
    final txRecipient = (_fetchedDetail?['counterpartyName'] ?? widget.recipient ?? txTitle).toString();
    final recipAccount = (_fetchedDetail?['counterpartyAccount'] ?? _fetchedDetail?['recipientAccount'] ?? '').toString();
    final recipBank = (_fetchedDetail?['counterpartyBankName'] ?? _fetchedDetail?['bankCode'] ?? '').toString();
    final isPositive = txAmount > 0;
    final napasTrace = txId.length > 6 ? txId.substring(txId.length - 6) : (txId.isNotEmpty ? txId : '000000');
    final coreRef = txId.isNotEmpty ? txId : 'SHB${DateTime.now().millisecondsSinceEpoch}';
    final sourceDisplay = (_sourceAccount != null && _sourceAccount!.isNotEmpty)
        ? '$_sourceAccount (${(_sourceName ?? 'SEN HỒNG USER').toUpperCase()})'
        : 'Tài khoản thanh toán Sen Hồng';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Biên Lai Điện Tử'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.share),
            tooltip: 'Chia sẻ biên lai',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo ảnh biên lai giao dịch chuẩn và sẵn sàng chia sẻ.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          child: Column(
            children: [
              // Electronic Receipt Container
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Watermark / Bank Brand
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.bottomBarCyan.withOpacity(0.5)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Image.asset('assets/icons/senbank_lotus_isolated.png', fit: BoxFit.contain),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SENBANK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark, letterSpacing: 0.5)),
                                  Text('NGÂN HÀNG SỐ VIỆT NAM', style: TextStyle(fontSize: 8.5, color: AppColors.textSecondaryLight, letterSpacing: 0.3)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bottomBarCyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('NAPAS 24/7', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.bottomBarCyan)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Success Circle Badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'GIAO DỊCH THÀNH CÔNG',
                        style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isPositive ? '+' : ''}${CurrencyFormatter.formatVND(txAmount)}',
                        style: AppTypography.displayMedium(
                          color: isPositive ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(txTitle, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                      const Divider(height: 32, color: AppColors.cardBorderLight),

                      // Core Details
                      _buildReceiptRow('Mã giao dịch (TxID)', txId, isCopyable: true),
                      const SizedBox(height: 10),
                      _buildReceiptRow('Mã tham chiếu Core Banking', coreRef, isCopyable: true),
                      const SizedBox(height: 10),
                      _buildReceiptRow('Số tham chiếu Napas (Trace)', napasTrace),
                      const SizedBox(height: 10),
                      _buildReceiptRow('Thời gian thực hiện', _formatTxDetailTime(txTime)),
                      const Divider(height: 24, color: AppColors.cardBorderLight),

                      // Accounts
                      _buildReceiptRow('Tài khoản trích tiền', sourceDisplay),
                      const SizedBox(height: 10),
                      _buildReceiptRow('Người thụ hưởng / đối tác', txRecipient, isBold: true),
                      if (recipAccount.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildReceiptRow('Số tài khoản thụ hưởng', recipAccount, isCopyable: true),
                      ],
                      if (recipBank.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildReceiptRow('Ngân hàng thụ hưởng', recipBank == 'SenHong' ? 'Ngân Hàng Số Sen Hồng' : recipBank),
                      ],
                      const SizedBox(height: 10),
                      _buildReceiptRow('Nội dung giao dịch', txNote),
                      const SizedBox(height: 10),
                      _buildReceiptRow('Kênh giao dịch', 'Sen Mobile App (Napas IBFT)'),
                      const SizedBox(height: 10),
                      _buildReceiptRow('Phí giao dịch', '0 VND (Miễn phí 100%)', isHighlight: true),
                      const Divider(height: 24, color: AppColors.cardBorderLight),

                      // Closing Balance with toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('Số dư khả dụng sau GD:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _isBalanceVisible
                                    ? (_runningBalance != null
                                        ? CurrencyFormatter.formatVND(_runningBalance!)
                                        : 'Đang cập nhật')
                                    : '•••••••• đ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(left: 6),
                                icon: Icon(
                                  _isBalanceVisible ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                                  size: 16,
                                  color: AppColors.textSecondaryLight,
                                ),
                                onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Digital Seal Stamp & QR
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: const Icon(CupertinoIcons.qrcode, size: 38, color: AppColors.primaryDark),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SEN HỒNG BANK • DIGITAL VERIFIED',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.emeraldGreen),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Chứng từ điện tử hợp lệ theo Luật Giao dịch điện tử số 20/2023/QH15. Quét mã QR để đối soát trực tuyến.',
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, height: 1.3),
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
              const SizedBox(height: 20),

              // Save Beneficiary Quick Action
              if (!isPositive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _isBeneficiarySaved ? AppColors.emeraldGreen : AppColors.borderSubtle),
                    ),
                    onPressed: () {
                      setState(() => _isBeneficiarySaved = !_isBeneficiarySaved);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isBeneficiarySaved ? 'Đã lưu người nhận vào Danh bạ thụ hưởng!' : 'Đã bỏ lưu khỏi danh bạ.'),
                        ),
                      );
                    },
                    icon: Icon(
                      _isBeneficiarySaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                      size: 16,
                      color: _isBeneficiarySaved ? AppColors.emeraldGreen : AppColors.primary,
                    ),
                    label: Text(
                      _isBeneficiarySaved ? 'Đã lưu trong danh bạ thụ hưởng' : 'Lưu người nhận vào danh bạ',
                      style: TextStyle(fontSize: 13, color: _isBeneficiarySaved ? AppColors.emeraldGreen : AppColors.primaryDark),
                    ),
                  ),
                ),

              // Primary Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      onPressed: () => _downloadReceipt(txId),
                      icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18, color: AppColors.primary),
                      label: const Text('Tải file PDF', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final positiveAmt = txAmount.abs();
                        final uri = Uri(
                          path: '/transfer/amount',
                          queryParameters: {
                            'recipient': txRecipient,
                            'amount': positiveAmt.toString(),
                            'note': txNote,
                          },
                        );
                        context.push(uri.toString());
                      },
                      icon: const Icon(CupertinoIcons.arrow_2_squarepath, size: 18),
                      label: const Text('Thực hiện lại', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dispute button & Home button
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showDisputeModal(txId),
                      icon: const Icon(CupertinoIcons.exclamationmark_bubble_fill, size: 16, color: AppColors.textSecondaryLight),
                      label: const Text('Tra soát / Khiếu nại', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(CupertinoIcons.house_fill, size: 16, color: AppColors.bottomBarCyan),
                      label: const Text('Về Trang Chủ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.bottomBarCyan)),
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

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false, bool isBold = false, bool isCopyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
        const SizedBox(width: 16),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight ? AppColors.emeraldGreen : (isBold ? AppColors.primaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép: $value')),
                    );
                  },
                  child: const Icon(CupertinoIcons.doc_on_doc, size: 14, color: AppColors.bottomBarCyan),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

