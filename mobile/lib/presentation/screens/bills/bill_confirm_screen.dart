import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/promotion_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

class BillConfirmScreen extends StatefulWidget {
  final String? service;
  final String? provider;
  final String? code;
  final String? billId;
  final double? amount;

  const BillConfirmScreen({
    super.key,
    this.service,
    this.provider,
    this.code,
    this.billId,
    this.amount,
  });

  @override
  State<BillConfirmScreen> createState() => _BillConfirmScreenState();
}

class _BillConfirmScreenState extends State<BillConfirmScreen> {
  late final double _billAmount = widget.amount ?? 485000;
  double _discountAmount = 0;
  String _selectedVoucherCode = '';
  bool _autoPayNextMonth = true;
  bool _requestVatInvoice = false;
  int _selectedSourceIdx = 0;
  double _walletBalance = 0;
  bool _isSubmitting = false;

  final TextEditingController _taxCodeCtrl = TextEditingController();
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _vatEmailCtrl = TextEditingController();

  List<Map<String, String>> _sources = [
    {'name': 'Ví Sen Hồng (Đang tải số dư...)', 'type': 'Miễn phí giao dịch', 'logo': 'SHB'},
  ];

  List<Map<String, dynamic>> _vouchers = [];

  double get _finalAmount => (_billAmount - _discountAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Nạp số dư ví thực từ backend
      final wallet = await WalletRemoteDataSource().getMyWallet();
      _walletBalance = wallet.balance;

      final updatedSources = <Map<String, String>>[
        {
          'name': 'Ví Sen Hồng (Số dư: ${CurrencyFormatter.formatVND(wallet.balance)})',
          'type': 'Thanh toán tức thời • Miễn phí 100%',
          'logo': 'SHB',
        }
      ];

      // 2. Nạp tài khoản liên kết thực
      try {
        final accounts = await BankAccountRemoteDataSource().getAccounts();
        for (final acc in accounts) {
          final bankCode = acc['bankCode']?.toString() ?? 'NGANHANG';
          final accNum = acc['accountNumber']?.toString() ?? '';
          final masked = accNum.length > 4 ? '(*${accNum.substring(accNum.length - 4)})' : accNum;
          updatedSources.add({
            'name': '$bankCode $masked',
            'type': 'Tài khoản ngân hàng liên kết',
            'logo': bankCode.length > 4 ? bankCode.substring(0, 4).toUpperCase() : bankCode.toUpperCase(),
          });
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _sources = updatedSources;
        });
      }

      // 3. Nạp danh sách khuyến mãi / voucher thực
      try {
        final promos = await PromotionRemoteDataSource().getPromotions();
        final mappedVouchers = <Map<String, dynamic>>[];
        for (final p in promos) {
          final code = p['code']?.toString() ?? '';
          final discount = (p['discountAmount'] ?? p['discount'] as num?)?.toDouble() ?? 10000.0;
          final title = p['title']?.toString() ?? 'Khuyến mãi Sen Hồng';
          final minAmount = (p['minAmount'] ?? p['minOrder'] as num?)?.toDouble() ?? 0.0;
          mappedVouchers.add({
            'code': code,
            'discount': discount,
            'title': title,
            'min': minAmount,
          });
        }

        if (mappedVouchers.isNotEmpty && mounted) {
          setState(() {
            _vouchers = mappedVouchers;
            // Áp dụng voucher đầu tiên nếu đơn thỏa mãn min
            final firstVoucher = mappedVouchers.first;
            if (_billAmount >= (firstVoucher['min'] as double)) {
              _selectedVoucherCode = firstVoucher['code'] as String;
              _discountAmount = firstVoucher['discount'] as double;
            }
          });
        }
      } catch (_) {
        // Fallback danh mục ưu đãi chuẩn nếu server chưa có danh sách
        if (mounted && _vouchers.isEmpty) {
          setState(() {
            _vouchers = [
              {'code': 'SENHONG5', 'discount': 15000.0, 'title': 'Giảm 15.000đ hóa đơn điện nước', 'min': 300000.0},
              {'code': 'EVN2026', 'discount': 25000.0, 'title': 'Giảm 25.000đ hóa đơn EVN trên 400k', 'min': 400000.0},
              {'code': 'HOAN5K', 'discount': 5000.0, 'title': 'Hoàn 5.000đ cho mọi hóa đơn', 'min': 100000.0},
            ];
            _selectedVoucherCode = 'SENHONG5';
            _discountAmount = 15000;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _taxCodeCtrl.dispose();
    _companyNameCtrl.dispose();
    _vatEmailCtrl.dispose();
    super.dispose();
  }

  void _showVoucherPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mã Giảm Giá / Voucher Sen Hồng', style: AppTypography.titleLarge(color: AppColors.primaryDark)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textMutedLight)),
              ],
            ),
            const SizedBox(height: 12),
            if (_vouchers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Hiện chưa có voucher khả dụng cho hóa đơn này.')),
              )
            else
              ..._vouchers.map((v) {
                final isApplied = _selectedVoucherCode == v['code'];
                final discount = (v['discount'] as num?)?.toDouble() ?? 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isApplied ? AppColors.emeraldGreen : AppColors.borderLight, width: isApplied ? 2 : 1),
                    color: isApplied ? AppColors.emeraldGreen.withOpacity(0.06) : Colors.white,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.emeraldGreen.withOpacity(0.15),
                      child: const Icon(CupertinoIcons.tickets_fill, color: AppColors.emeraldGreen, size: 20),
                    ),
                    title: Text(v['code'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryLight)),
                    subtitle: Text(v['title'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApplied ? AppColors.emeraldGreen : AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedVoucherCode = v['code'] as String;
                          _discountAmount = discount;
                        });
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.emeraldGreen,
                            content: Text('Đã áp dụng mã ${v['code']}! Tiết kiệm ${CurrencyFormatter.formatVND(discount)}'),
                          ),
                        );
                      },
                      child: Text(isApplied ? 'Đang dùng' : 'Dùng mã', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _proceedPayment() async {
    if (_isSubmitting) return;

    // Nếu chọn nguồn là Ví Sen Hồng mà số dư nhỏ hơn số tiền cần trả
    if (_selectedSourceIdx == 0 && _walletBalance < _finalAmount) {
      HapticFeedback.vibrate();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.warningText),
              SizedBox(width: 8),
              Expanded(
                child: Text('Số Dư Ví Không Đủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimaryLight)),
              ),
            ],
          ),
          content: Text(
            'Số dư Ví Sen Hồng của bạn hiện có ${CurrencyFormatter.formatVND(_walletBalance)}, không đủ để thanh toán hóa đơn ${CurrencyFormatter.formatVND(_finalAmount)}.\n\nBạn có muốn nạp thêm tiền vào ví ngay bây giờ?',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textMutedLight)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/deposit');
              },
              child: const Text('Nạp tiền ngay'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final provider = widget.provider ?? 'EVN';
    await context.push(
      '/bills/payment-confirm?billId=${Uri.encodeComponent(widget.billId ?? '')}&provider=${Uri.encodeComponent(provider)}&code=${Uri.encodeComponent(widget.code ?? '')}&amount=$_finalAmount',
    );
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Nhận Hóa Đơn'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill Summary Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Số tiền cước cần thanh toán', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.formatVND(_finalAmount),
                        style: const TextStyle(color: AppColors.primaryDark, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      if (CurrencyFormatter.toVietnameseWords(_finalAmount).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(_finalAmount)} đồng',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Chờ thanh toán', style: TextStyle(color: AppColors.warningText, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Divider(height: 28, color: AppColors.cardBorderLight),

                      _buildRow('Dịch vụ', widget.service ?? 'Hóa đơn dịch vụ'),
                      const SizedBox(height: 10),
                      _buildRow('Đơn vị cung cấp', widget.provider ?? 'Nhà cung cấp'),
                      const SizedBox(height: 10),
                      _buildRow('Mã khách hàng', widget.code ?? ''),
                      const SizedBox(height: 10),
                      _buildRow('Kỳ cước hóa đơn', 'Kỳ gần nhất'),
                      const SizedBox(height: 10),
                      _buildRow('Tiền cước gốc', CurrencyFormatter.formatVND(_billAmount)),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 10),
                        _buildRow('Ưu đãi Sen Hồng ($_selectedVoucherCode)', '-${CurrencyFormatter.formatVND(_discountAmount)}', isHighlight: true),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Voucher Selection Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: ListTile(
                  onTap: _showVoucherPicker,
                  leading: const Icon(CupertinoIcons.tickets_fill, color: AppColors.emeraldGreen, size: 24),
                  title: const Text('Mã giảm giá / Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
                  subtitle: Text(
                    _discountAmount > 0
                        ? 'Đang dùng: $_selectedVoucherCode (-${CurrencyFormatter.formatVND(_discountAmount)})'
                        : 'Chọn mã giảm giá để tiết kiệm thêm',
                    style: TextStyle(
                      fontSize: 11,
                      color: _discountAmount > 0 ? AppColors.emeraldGreen : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Chọn mã', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(CupertinoIcons.chevron_forward, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Payment Source Selection
              Text('Nguồn tiền thanh toán', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Column(
                  children: List.generate(_sources.length, (idx) {
                    final s = _sources[idx];
                    final isSelected = _selectedSourceIdx == idx;
                    final isLast = idx == _sources.length - 1;
                    return Column(
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () => setState(() => _selectedSourceIdx = idx),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: Text(s['logo']!, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            title: Text(s['name']!, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(s['type']!, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                            trailing: isSelected
                                ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen)
                                : const Icon(CupertinoIcons.circle, color: AppColors.textMutedLight),
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // Auto-Debit Switch
              GlassCard(
                quality: GlassQuality.minimal,
                child: SwitchListTile.adaptive(
                  value: _autoPayNextMonth,
                  activeTrackColor: AppColors.primary,
                  title: Text('Tự động thanh toán các kỳ sau', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('Hệ thống tự động trừ cước khi có hóa đơn mới, thông báo biến động tức thời', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                  onChanged: (val) => setState(() => _autoPayNextMonth = val),
                ),
              ),
              const SizedBox(height: 14),

              // VAT E-Invoice Toggle Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _requestVatInvoice,
                      activeTrackColor: AppColors.primary,
                      title: Text('Yêu cầu xuất hóa đơn điện tử GTGT', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Hóa đơn VAT hợp pháp theo quy định Tổng Cục Thuế', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                      onChanged: (val) => setState(() => _requestVatInvoice = val),
                    ),
                    if (_requestVatInvoice) ...[
                      const Divider(height: 1, color: AppColors.cardBorderLight),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _taxCodeCtrl,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                              decoration: InputDecoration(
                                labelText: 'Mã số thuế doanh nghiệp (MST)',
                                prefixIcon: const Icon(CupertinoIcons.number, size: 16, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _companyNameCtrl,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                              decoration: InputDecoration(
                                labelText: 'Tên cơ quan / Doanh nghiệp',
                                prefixIcon: const Icon(CupertinoIcons.building_2_fill, size: 16, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _vatEmailCtrl,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                              decoration: InputDecoration(
                                labelText: 'Email nhận hóa đơn điện tử',
                                prefixIcon: const Icon(CupertinoIcons.mail_solid, size: 16, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Confirm Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _proceedPayment,
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(CupertinoIcons.checkmark_shield_fill, color: Colors.white),
                  label: Text('Xác nhận & Tiếp tục (${CurrencyFormatter.formatVND(_finalAmount)})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.lock_shield_fill, size: 14, color: AppColors.emeraldGreen),
                    SizedBox(width: 6),
                    Text('Giao dịch mã hóa chuẩn PCI-DSS & Smart OTP bảo mật', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall(color: isHighlight ? AppColors.emeraldGreen : AppColors.textPrimaryLight).copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
