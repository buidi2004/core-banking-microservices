import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/funding_source_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _methods = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final items = await FundingSourceRemoteDataSource().getAll();
      if (!mounted) return;
      setState(() {
        _methods
          ..clear()
          ..addAll(items.map((item) => {
            'id': item['id'],
            'title': '${item['provider'] ?? item['type'] ?? 'Nguồn tiền'}',
            'subtitle': item['maskedNumber'] ?? item['number'] ?? '',
            'icon': CupertinoIcons.creditcard_fill,
            'isDefault': item['isDefault'] == true,
            'type': item['type'] ?? 'CARD',
          }));
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = extractErrorMessage(error); _loading = false; });
    }
  }

  /*
  final List<Map<String, dynamic>> _methods = [
    {
      'id': '1',
      'title': 'Ví Sen Hồng (Tài khoản chính)',
      'subtitle': 'Số dư: 12.580.000 đ',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'isDefault': true,
      'type': 'WALLET',
    },
    {
      'id': '2',
      'title': 'Visa Platinum Quốc Tế',
      'subtitle': '•••• •••• •••• 4589 • Hết hạn: 08/28',
      'icon': CupertinoIcons.creditcard_fill,
      'isDefault': false,
      'type': 'CARD',
    },
    {
      'id': '3',
      'title': 'Mastercard World Elite',
      'subtitle': '•••• •••• •••• 9921 • Hết hạn: 11/27',
      'icon': CupertinoIcons.creditcard_fill,
      'isDefault': false,
      'type': 'CARD',
    },
  ];*/

  void _showAddCardModal() {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Thêm Thẻ Quốc Tế Mới',
                          style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        icon: const Icon(CupertinoIcons.xmark, color: AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Số thẻ', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(CupertinoIcons.creditcard, color: AppColors.primary),
                      hintText: '4xxx xxxx xxxx xxxx',
                      hintStyle: const TextStyle(color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Tên in trên thẻ', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(CupertinoIcons.person_fill, color: AppColors.primary),
                      hintText: 'HỌ VÀ TÊN (KHÔNG DẤU)',
                      hintStyle: const TextStyle(color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ngày hết hạn', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: expiryCtrl,
                              enabled: !isSubmitting,
                              style: const TextStyle(color: AppColors.textPrimaryLight),
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                hintStyle: const TextStyle(color: AppColors.textMutedLight),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.borderLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mã CVV/CVC', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: cvvCtrl,
                              obscureText: true,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimaryLight),
                              decoration: InputDecoration(
                                hintText: '•••',
                                hintStyle: const TextStyle(color: AppColors.textMutedLight),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.borderLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.borderLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final numStr = numberCtrl.text.replaceAll(' ', '').trim();
                              final holder = nameCtrl.text.trim();
                              final exp = expiryCtrl.text.trim();
                              final cvv = cvvCtrl.text.trim();

                              if (numStr.length < 15) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Số thẻ quốc tế phải có ít nhất 15-16 chữ số')),
                                );
                                return;
                              }
                              if (holder.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập tên in trên thẻ')),
                                );
                                return;
                              }
                              if (!exp.contains('/') || exp.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập ngày hết hạn theo định dạng MM/YY')),
                                );
                                return;
                              }
                              if (cvv.length < 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mã bảo mật CVV/CVC phải có từ 3-4 chữ số')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              HapticFeedback.mediumImpact();
                              try {
                                await FundingSourceRemoteDataSource().link({
                                  'type': 'CREDIT_CARD',
                                  'provider': 'CARD',
                                  'number': numStr,
                                  'cardHolderName': holder,
                                  'expiryDate': exp,
                                  'cvv': cvv,
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _loadMethods();
                                if (mounted) {
                                  AppAlerts.showSuccess(
                                    context,
                                    'Liên kết thẻ quốc tế thành công!',
                                    title: 'Thành công',
                                  );
                                }
                              } catch (error) {
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  AppAlerts.showError(
                                    context,
                                    extractErrorMessage(error),
                                    title: 'Liên kết thẻ thất bại',
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Lưu & Xác thực thẻ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nguồn Tiền & Phương Thức'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMethods,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Phương thức thanh toán đã liên kết', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text('Sử dụng để thanh toán hóa đơn, nạp tiền và chi tiêu trực tuyến', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 16),

              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.error)),
              if (!_loading && _error == null && _methods.isEmpty) const Text('Chưa có nguồn tiền liên kết.'),
              ..._methods.map((m) {
                final isDefault = m['isDefault'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    quality: GlassQuality.minimal,
                    child: Material(type: MaterialType.transparency, child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(m['icon'] as IconData, color: AppColors.primary),
                      ),
                      title: Text(m['title'] as String, style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      subtitle: Text(m['subtitle'] as String, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                      trailing: isDefault
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Mặc định', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          : IconButton(
                              icon: const Icon(CupertinoIcons.ellipsis, color: AppColors.textMutedLight),
                              onPressed: () {
                                _showOptionSheet(m);
                              },
                            ),
                    )),
                  ),
                );
              }),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showAddCardModal,
                icon: const Icon(CupertinoIcons.plus_circle_fill),
                label: const Text('Thêm thẻ quốc tế mới (Visa/Mastercard)'),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.push('/bank-cards'),
                icon: const Icon(CupertinoIcons.building_2_fill, color: AppColors.primary),
                label: const Text('Quản lý tài khoản ngân hàng liên kết'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/cards'),
                icon: const Icon(CupertinoIcons.creditcard, color: AppColors.primary),
                label: const Text('Xem danh sách thẻ ảo Sen Hồng'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(type: MaterialType.transparency, child: ListTile(
              leading: const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen),
              title: const Text('Đặt làm phương thức mặc định', style: TextStyle(color: AppColors.textPrimaryLight)),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(ctx);
                setState(() {
                  for (var m in _methods) {
                    m['isDefault'] = m['id'] == item['id'];
                  }
                });
              },
            )),
            Material(type: MaterialType.transparency, child: ListTile(
              leading: const Icon(CupertinoIcons.trash_fill, color: AppColors.error),
              title: const Text('Hủy liên kết thẻ này', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Hủy liên kết thẻ?'),
                    content: Text('Bạn có chắc chắn muốn hủy liên kết thẻ ${item['title']} (${item['subtitle']})?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Xóa liên kết'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  HapticFeedback.mediumImpact();
                  try {
                    await FundingSourceRemoteDataSource().remove(item['id'].toString());
                    await _loadMethods();
                    if (mounted) {
                      AppAlerts.showSuccess(
                        context,
                        'Đã hủy liên kết thẻ thành công',
                        title: 'Hủy liên kết',
                      );
                    }
                  } catch (error) {
                    if (mounted) {
                      AppAlerts.showError(
                        context,
                        extractErrorMessage(error),
                        title: 'Không thể hủy liên kết thẻ',
                      );
                    }
                  }
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}
