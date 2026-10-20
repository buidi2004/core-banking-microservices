import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _beneficiaries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final items = await BeneficiaryRemoteDataSource().getAll();
      if (!mounted) return;
      setState(() {
        _beneficiaries
          ..clear()
          ..addAll(items.map((item) => {
            'id': '${item['id'] ?? ''}',
            'name': '${item['name'] ?? item['fullName'] ?? ''}',
            'nickname': '${item['nickname'] ?? item['name'] ?? ''}',
            'bank': '${item['bankCode'] ?? ''}',
            'acc': '${item['accountNumber'] ?? item['phoneNumber'] ?? ''}',
            'phone': '${item['phoneNumber'] ?? ''}',
            'walletId': '${item['beneficiaryWalletId'] ?? item['walletId'] ?? ''}',
          }));
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = extractErrorMessage(error); _loading = false; });
    }
  }

  List<Map<String, String>> get _filtered {
    if (_keyword.isEmpty) return _beneficiaries;
    return _beneficiaries.where((b) {
      return b['name']!.toLowerCase().contains(_keyword.toLowerCase()) ||
          b['nickname']!.toLowerCase().contains(_keyword.toLowerCase()) ||
          b['acc']!.contains(_keyword) ||
          b['phone']!.contains(_keyword);
    }).toList();
  }

  void _showAddBeneficiaryModal() {
    final nameCtrl = TextEditingController();
    final nickCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    String selectedBank = 'Vietcombank';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
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
                          'Thêm Người Thụ Hưởng Mới',
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
                  Text('Chọn ngân hàng / Ví', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBank,
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'Ví Sen Hồng', child: Text('Ví Sen Hồng (Nội bộ 24/7)')),
                          DropdownMenuItem(value: 'Vietcombank', child: Text('Vietcombank (VCB)')),
                          DropdownMenuItem(value: 'MBBank', child: Text('MBBank (Quân Đội)')),
                          DropdownMenuItem(value: 'Techcombank', child: Text('Techcombank (TCB)')),
                          DropdownMenuItem(value: 'VietinBank', child: Text('VietinBank (CTG)')),
                          DropdownMenuItem(value: 'BIDV', child: Text('BIDV')),
                          DropdownMenuItem(value: 'VPBank', child: Text('VPBank')),
                          DropdownMenuItem(value: 'ACB', child: Text('Á Châu (ACB)')),
                          DropdownMenuItem(value: 'TPBank', child: Text('Tiên Phong (TPB)')),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (val) {
                                if (val != null) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => selectedBank = val);
                                }
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Số tài khoản / Số điện thoại', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: accCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(CupertinoIcons.creditcard, color: AppColors.primary),
                      hintText: 'Nhập số tài khoản hoặc SĐT ví',
                      hintStyle: const TextStyle(color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Họ và tên người nhận', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: TRẦN VĂN A',
                      hintStyle: const TextStyle(color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Biệt danh gợi nhớ (tùy chọn)', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nickCtrl,
                    enabled: !isSubmitting,
                    style: const TextStyle(color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Bạn thân, Tiền nhà...',
                      hintStyle: const TextStyle(color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final acc = accCtrl.text.trim();
                              if (name.isEmpty || acc.isEmpty) {
                                HapticFeedback.vibrate();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.error,
                                    content: Text('Vui lòng nhập tên và số tài khoản'),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              try {
                                await BeneficiaryRemoteDataSource().add({
                                  'beneficiaryWalletId': acc,
                                  'nickname': nickCtrl.text.trim().isEmpty ? name : nickCtrl.text.trim(),
                                  'bankCode': selectedBank,
                                  'accountNumber': acc,
                                });
                                HapticFeedback.mediumImpact();
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _loadBeneficiaries();
                                if (mounted) {
                                  AppAlerts.showSuccess(
                                    context,
                                    'Đã lưu người thụ hưởng vào danh bạ!',
                                    title: 'Thành công',
                                  );
                                }
                              } catch (error) {
                                setModalState(() => isSubmitting = false);
                                if (mounted) {
                                  AppAlerts.showError(
                                    context,
                                    extractErrorMessage(error),
                                    title: 'Không thể lưu thụ hưởng',
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Lưu người thụ hưởng'),
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

  void _editNickname(Map<String, String> b) {
    final nickCtrl = TextEditingController(text: b['nickname']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Đổi Biệt Danh', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nickCtrl,
          style: const TextStyle(color: AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: 'Nhập biệt danh dễ nhớ',
            hintStyle: const TextStyle(color: AppColors.textMutedLight),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AppColors.textMutedLight))),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => b['nickname'] = nickCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteBeneficiary(Map<String, String> b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.error),
            SizedBox(width: 8),
            Expanded(
              child: Text('Xác nhận xóa thụ hưởng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${b['name']}" (${b['acc']}) khỏi danh bạ người thụ hưởng?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textMutedLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              try {
                await BeneficiaryRemoteDataSource().remove(b['id']!);
                await _loadBeneficiaries();
                if (mounted) {
                  AppAlerts.showSuccess(
                    context,
                    'Đã xóa người thụ hưởng khỏi danh bạ',
                    title: 'Xóa thành công',
                  );
                }
              } catch (error) {
                if (mounted) {
                  AppAlerts.showError(
                    context,
                    extractErrorMessage(error),
                    title: 'Không thể xóa thụ hưởng',
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Danh Bạ Thụ Hưởng'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_badge_plus_fill, color: AppColors.primary),
            tooltip: 'Thêm người thụ hưởng',
            onPressed: _showAddBeneficiaryModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _keyword = val),
                    style: const TextStyle(color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primary),
                      suffixIcon: _keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textMutedLight, size: 18),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _keyword = '';
                              }),
                            )
                          : null,
                      hintText: 'Tìm theo tên, SĐT, số tài khoản...',
                      hintStyle: const TextStyle(color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showAddBeneficiaryModal,
                      icon: const Icon(CupertinoIcons.plus_circle_fill),
                      label: const Text('Thêm người thụ hưởng mới'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                      : _filtered.isEmpty
                  ? Center(
                      child: Text('Không tìm thấy người thụ hưởng phù hợp', style: AppTypography.bodyMedium(color: AppColors.textMutedLight)),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: _filtered.length,
                      itemBuilder: (context, idx) {
                        final b = _filtered[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            quality: GlassQuality.minimal,
                            child: Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                onTap: () {
                                  final name = b['name'] ?? '';
                                  final phone = (b['phone']?.isNotEmpty == true) ? b['phone']! : (b['acc'] ?? '');
                                  final walletId = b['walletId'];
                                  final uri = Uri(
                                    path: '/transfer/amount',
                                    queryParameters: {
                                      'recipient': name,
                                      if (phone.isNotEmpty) 'phoneNumber': phone,
                                      if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
                                      'note': 'Chuyen tien',
                                    },
                                  );
                                  context.push(uri.toString());
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.bottomBarGlow.withOpacity(0.35),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      (b['name'] != null && b['name']!.trim().isNotEmpty)
                                          ? b['name']!.trim().split(' ').last[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(b['name']!, style: AppTypography.titleMedium(color: AppColors.textPrimaryLight))),
                                    const Icon(CupertinoIcons.paperplane_fill, size: 16, color: AppColors.primary),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(b['nickname']!, style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('${b['bank']} • ${b['acc']}', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(CupertinoIcons.ellipsis, color: AppColors.textMutedLight),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onSelected: (action) {
                                    if (action == 'edit') _editNickname(b);
                                    if (action == 'delete') _deleteBeneficiary(b);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.pencil, size: 16, color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('Sửa biệt danh', style: TextStyle(color: AppColors.textPrimaryLight)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(CupertinoIcons.trash, size: 16, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Xóa người này', style: TextStyle(color: AppColors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
