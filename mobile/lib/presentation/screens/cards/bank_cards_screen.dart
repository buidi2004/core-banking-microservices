import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';

class BankCardsScreen extends StatefulWidget {
  const BankCardsScreen({super.key});

  @override
  State<BankCardsScreen> createState() => _BankCardsScreenState();
}

class _BankCardsScreenState extends State<BankCardsScreen> {
  final BankAccountRemoteDataSource _bankDataSource = BankAccountRemoteDataSource();
  final ProfileRemoteDataSource _profileDataSource = ProfileRemoteDataSource();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> _banks = [];
  bool _isLoading = true;
  String _userFullName = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadUserName(),
      _loadBankAccounts(),
    ]);
  }

  Future<void> _loadUserName() async {
    try {
      final savedName = await _storage.read(key: AppConstants.keyFullName);
      if (savedName != null && savedName.isNotEmpty) {
        if (mounted) setState(() => _userFullName = savedName);
      }
      final me = await _profileDataSource.getMe();
      final name = me['fullName'] as String? ?? me['name'] as String? ?? '';
      if (name.isNotEmpty && mounted) {
        setState(() => _userFullName = name);
      }
    } catch (_) {}
  }

  Future<void> _loadBankAccounts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final rawAccounts = await _bankDataSource.getAccounts();
      if (!mounted) return;
      setState(() {
        _banks = rawAccounts.map((account) {
          final bankCode = account['bankCode'] as String? ?? 'BANK';
          final accNum = account['accountNumber'] as String? ?? '';
          final holder = account['accountHolderName'] as String? ?? _userFullName;
          final isDef = account['isDefault'] as bool? ?? false;
          final id = account['id'] as String? ?? '';
          return {
            'id': id,
            'bankName': _getBankFullName(bankCode),
            'shortName': bankCode,
            'accountNumber': accNum,
            'holderName': holder,
            'isDefault': isDef,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách tài khoản: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getBankFullName(String code) {
    switch (code.toUpperCase()) {
      case 'VCB':
      case 'VIETCOMBANK':
        return 'Ngân hàng Ngoại thương Việt Nam';
      case 'CTG':
      case 'VIETINBANK':
        return 'Ngân hàng Công thương Việt Nam';
      case 'BIDV':
        return 'Ngân hàng Đầu tư và Phát triển Việt Nam';
      case 'TCB':
      case 'TECHCOMBANK':
        return 'Ngân hàng Kỹ thương Việt Nam';
      case 'MB':
      case 'MBBANK':
        return 'Ngân hàng Quân đội';
      case 'VPB':
      case 'VPBANK':
        return 'Ngân hàng Việt Nam Thịnh vượng';
      case 'ACB':
        return 'Ngân hàng Á Châu';
      case 'STB':
      case 'SACOMBANK':
        return 'Ngân hàng Sài Gòn Thương Tín';
      default:
        return 'Ngân hàng $code';
    }
  }

  final List<Map<String, String>> _availableBanks = const [
    {'code': 'VCB', 'name': 'Vietcombank - Ngân hàng Ngoại Thương'},
    {'code': 'CTG', 'name': 'VietinBank - Ngân hàng Công Thương'},
    {'code': 'BIDV', 'name': 'BIDV - Ngân hàng Đầu tư & Phát triển'},
    {'code': 'TCB', 'name': 'Techcombank - Ngân hàng Kỹ Thương'},
    {'code': 'MB', 'name': 'MB Bank - Ngân hàng Quân Đội'},
    {'code': 'VPB', 'name': 'VPBank - Ngân hàng VN Thịnh Vượng'},
    {'code': 'ACB', 'name': 'ACB - Ngân hàng Á Châu'},
    {'code': 'STB', 'name': 'Sacombank - Ngân hàng Sài Gòn Thương Tín'},
  ];

  void _showAddBankModal() {
    HapticFeedback.selectionClick();
    String selectedBankCode = _availableBanks.first['code']!;
    final accCtrl = TextEditingController();
    final holderCtrl = TextEditingController(text: _userFullName.toUpperCase());
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
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
                        'Liên Kết Ngân Hàng Mới',
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
                Text('Chọn ngân hàng liên kết', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
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
                      value: selectedBankCode,
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14),
                      items: _availableBanks
                          .map((b) => DropdownMenuItem(
                                value: b['code'],
                                child: Text(
                                  b['name']!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) setModalState(() => selectedBankCode = val);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Số tài khoản ngân hàng', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 6),
                TextField(
                  controller: accCtrl,
                  keyboardType: TextInputType.number,
                  enabled: !isSubmitting,
                  style: const TextStyle(color: AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(CupertinoIcons.creditcard, color: AppColors.primary),
                    hintText: 'Nhập số tài khoản ngân hàng chính chủ',
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
                Text('Tên chủ tài khoản (Chính chủ)', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 6),
                TextField(
                  controller: holderCtrl,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !isSubmitting,
                  style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final acc = accCtrl.text.trim();
                            final holder = holderCtrl.text.trim();
                            if (acc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập số tài khoản ngân hàng')),
                              );
                              return;
                            }
                            if (holder.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập họ tên chủ tài khoản')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _bankDataSource.link(
                                bankCode: selectedBankCode,
                                accountNumber: acc,
                                accountHolderName: holder,
                              );
                              HapticFeedback.mediumImpact();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.emeraldGreen,
                                    content: Text('Liên kết tài khoản ngân hàng thành công!'),
                                  ),
                                );
                                _loadBankAccounts();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.error,
                                    content: Text('Lỗi liên kết: $e'),
                                  ),
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
                        : const Text('Xác nhận liên kết ngân hàng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBankOptions(Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen),
                title: const Text('Đặt làm tài khoản mặc định', style: TextStyle(color: AppColors.textPrimaryLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    for (var item in _banks) {
                      item['isDefault'] = item['id'] == b['id'];
                    }
                  });
                },
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(CupertinoIcons.trash_fill, color: AppColors.error),
                title: const Text('Hủy liên kết tài khoản này', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Xác nhận hủy liên kết'),
                      content: Text('Bạn có chắc chắn muốn hủy liên kết tài khoản ${b['bankName']} (${b['accountNumber']})?'),
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
                    final id = b['id'] as String;
                    try {
                      if (id.isNotEmpty) {
                        await _bankDataSource.unlink(id);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.emeraldGreen,
                            content: Text('Đã hủy liên kết tài khoản thành công'),
                          ),
                        );
                        _loadBankAccounts();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text('Không thể hủy liên kết: $e'),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tài Khoản Ngân Hàng'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _initData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Text('Tài khoản ngân hàng liên kết', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                    const SizedBox(height: 6),
                    Text(
                      'Liên kết tài khoản ngân hàng nội địa để nạp và rút tiền tức thì 24/7',
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 16),

                    if (_banks.isEmpty)
                      GlassCard(
                        quality: GlassQuality.minimal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          child: Column(
                            children: [
                              const Icon(CupertinoIcons.creditcard, size: 56, color: AppColors.textMutedLight),
                              const SizedBox(height: 14),
                              Text(
                                'Chưa có ngân hàng nào được liên kết',
                                style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Liên kết tài khoản ngân hàng để nạp tiền vào ví hoặc rút tiền về tài khoản ngân hàng bất cứ lúc nào',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _showAddBankModal,
                                icon: const Icon(CupertinoIcons.plus_circle_fill, size: 18),
                                label: const Text('Liên kết ngân hàng ngay'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._banks.map((b) {
                        final isDefault = b['isDefault'] as bool;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            quality: GlassQuality.minimal,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary.withOpacity(0.18),
                                        child: Text(
                                          b['shortName'] as String,
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${b['shortName']} - ${b['accountNumber']}',
                                              style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${b['holderName']} • ${b['bankName']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isDefault)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.emeraldGreen.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('Mặc định', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(CupertinoIcons.ellipsis, color: AppColors.textMutedLight),
                                          onPressed: () => _showBankOptions(b),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 20, color: AppColors.cardBorderLight),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            side: const BorderSide(color: AppColors.borderLight),
                                          ),
                                          onPressed: () => context.push('/deposit'),
                                          icon: const Icon(CupertinoIcons.arrow_down_circle_fill, size: 16, color: AppColors.emeraldGreen),
                                          label: const Text('Nạp tiền', style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            side: const BorderSide(color: AppColors.borderLight),
                                          ),
                                          onPressed: () => context.push('/withdraw'),
                                          icon: const Icon(CupertinoIcons.arrow_up_circle_fill, size: 16, color: AppColors.primary),
                                          label: const Text('Rút tiền', style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    if (_banks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddBankModal,
                        icon: const Icon(CupertinoIcons.plus_circle_fill),
                        label: const Text('Thêm tài khoản ngân hàng mới'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
