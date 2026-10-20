import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';

class ChooseRecipientScreen extends StatefulWidget {
  const ChooseRecipientScreen({super.key});

  @override
  State<ChooseRecipientScreen> createState() => _ChooseRecipientScreenState();
}

class _ChooseRecipientScreenState extends State<ChooseRecipientScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;

  Timer? _debounceTimer;
  bool _isLookingUp = false;
  Map<String, dynamic>? _lookedUpRecipient;
  String? _lookupError;

  List<Map<String, String>> _beneficiaries = [];
  bool _isLoadingBeneficiaries = true;

  final List<Map<String, String>> _popularBanks = const [
    {'name': 'Vietcombank', 'short': 'VCB', 'code': '970436'},
    {'name': 'Techcombank', 'short': 'TCB', 'code': '970407'},
    {'name': 'MB Bank', 'short': 'MB', 'code': '970422'},
    {'name': 'ACB', 'short': 'ACB', 'code': '970416'},
    {'name': 'BIDV', 'short': 'BIDV', 'code': '970418'},
    {'name': 'VietinBank', 'short': 'CTG', 'code': '970415'},
    {'name': 'VPBank', 'short': 'VPB', 'code': '970432'},
    {'name': 'TPBank', 'short': 'TPB', 'code': '970423'},
  ];

  String _myPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadMyPhone();
    _loadBeneficiaries();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadMyPhone() async {
    try {
      const storage = FlutterSecureStorage();
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (phone != null && mounted) {
        setState(() => _myPhoneNumber = phone.replaceAll(RegExp(r'[\s\.\-]'), ''));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final items = await BeneficiaryRemoteDataSource().getAll();
      if (!mounted) return;
      setState(() {
        _beneficiaries = items.map((item) => {
          'name': (item['name'] ?? item['fullName'] ?? item['nickname'] ?? '').toString(),
          'account': (item['accountNumber'] ?? item['phoneNumber'] ?? '').toString(),
          'bank': (item['bankCode'] ?? 'Ví Sen Hồng').toString(),
          'phone': (item['phoneNumber'] ?? '').toString(),
          'walletId': (item['walletId'] ?? '').toString(),
        }).toList();
        _isLoadingBeneficiaries = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingBeneficiaries = false);
    }
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (_selectedTab != 0) return;

    _debounceTimer?.cancel();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
          _lookedUpRecipient = null;
          _lookupError = null;
        });
      }
      return;
    }

    final clean = text.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (clean.length >= 8) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        _lookupRecipient(clean);
      });
    } else {
      if (_lookedUpRecipient != null || _lookupError != null) {
        setState(() {
          _lookedUpRecipient = null;
          _lookupError = null;
        });
      }
    }
  }

  Future<void> _lookupRecipient(String query) async {
    final clean = query.trim().replaceAll(RegExp(r'[\s\.\-]'), '');
    if (clean.isEmpty) return;

    final phoneClean = clean.startsWith('+84')
        ? '0${clean.substring(3)}'
        : (clean.startsWith('84') && clean.length == 11)
            ? '0${clean.substring(2)}'
            : clean;

    if (_myPhoneNumber.isNotEmpty && phoneClean == _myPhoneNumber) {
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = null;
        _lookupError = 'Không thể chuyển tiền vào chính tài khoản của bạn';
      });
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
    });

    try {
      final info = await TransferRemoteDataSource().getRecipient(clean);
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = info;
        _lookupError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = null;
        _lookupError = 'Không tìm thấy tài khoản SenBank với SĐT/STK này';
      });
    }
  }

  void _continueToAmount() async {
    final text = _searchController.text.trim();
    final clean = text.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập SĐT, mã ví hoặc số tài khoản người nhận')),
      );
      return;
    }

    if (_selectedTab == 0) {
      if (_lookedUpRecipient != null) {
        _navigateToAmount(
          recipient: _lookedUpRecipient!['fullName']?.toString() ?? text,
          phone: _lookedUpRecipient!['phoneNumber']?.toString() ?? text,
          walletId: _lookedUpRecipient!['walletId']?.toString() ?? '',
        );
        return;
      }

      setState(() => _isLookingUp = true);
      try {
        final info = await TransferRemoteDataSource().getRecipient(text);
        if (!mounted) return;
        setState(() {
          _isLookingUp = false;
          _lookedUpRecipient = info;
        });
        _navigateToAmount(
          recipient: info['fullName']?.toString() ?? text,
          phone: info['phoneNumber']?.toString() ?? text,
          walletId: info['walletId']?.toString() ?? '',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLookingUp = false;
          _lookupError = 'Không tìm thấy tài khoản SenBank với SĐT/STK này';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy tài khoản người nhận trên hệ thống Sen Hồng')),
        );
      }
    } else {
      _navigateToAmount(recipient: text);
    }
  }

  void _navigateToAmount({required String recipient, String? phone, String? walletId}) {
    final uri = Uri(
      path: '/transfer/amount',
      queryParameters: {
        'recipient': recipient,
        if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
        if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chuyển Tiền'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Quét mã QR',
            icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.primary),
            onPressed: () => context.push('/scan-qr'),
          ),
          IconButton(
            tooltip: 'Danh bạ',
            icon: const Icon(CupertinoIcons.person_2_fill, color: AppColors.primary),
            onPressed: () => context.push('/beneficiaries'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadBeneficiaries();
            await _loadMyPhone();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Tabs selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTab = 0;
                            _lookedUpRecipient = null;
                            _lookupError = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 0 ? AppColors.primaryGradient : null,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.bottomBarGlow.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Ví tới Ví (Nội bộ)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedTab = 1;
                            _lookedUpRecipient = null;
                            _lookupError = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 1 ? AppColors.primaryGradient : null,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: AppColors.bottomBarGlow.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Liên ngân hàng (Napas)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Input field
              TextField(
                controller: _searchController,
                keyboardType: _selectedTab == 0 ? TextInputType.phone : TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _selectedTab == 0 ? 'Nhập SĐT hoặc STK Sen Hồng...' : 'Nhập số tài khoản ngân hàng...',
                  hintStyle: const TextStyle(color: AppColors.textMutedLight),
                  prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primary),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textMutedLight, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      else
                        IconButton(
                          tooltip: 'Dán từ bộ nhớ tạm',
                          icon: const Icon(CupertinoIcons.doc_on_clipboard, color: AppColors.primary, size: 18),
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            final text = data?.text?.trim() ?? '';
                            if (text.isNotEmpty) {
                              HapticFeedback.selectionClick();
                              _searchController.text = text;
                              _lookupRecipient(text);
                            }
                          },
                        ),
                      IconButton(
                        tooltip: 'Quét QR',
                        icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.primary),
                        onPressed: () => context.push('/scan-qr'),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
                onSubmitted: (_) => _continueToAmount(),
              ),

              // Realtime Recipient Auto-Identification Result Card / Indicator
              if (_selectedTab == 0) ...[
                if (_isLookingUp) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        SizedBox(width: 10),
                        Text(
                          'Đang tự động nhận diện tên chủ tài khoản...',
                          style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_lookedUpRecipient != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldGreen.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emeraldGreen.withOpacity(0.15),
                          ),
                          child: const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_lookedUpRecipient!['fullName'] ?? _lookedUpRecipient!['maskedName'] ?? '').toString().toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SĐT/STK: ${_lookedUpRecipient!['phoneNumber'] ?? ''} • Ví Sen Hồng',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _continueToAmount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Chọn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_lookupError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.info_circle_fill, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lookupError!,
                            style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 10),

              // Continue Button
              ElevatedButton.icon(
                onPressed: _continueToAmount,
                icon: const Icon(CupertinoIcons.chevron_forward, size: 18),
                label: const Text('Tiếp tục nhập số tiền'),
              ),

              const SizedBox(height: 16),

              // Quick Actions: Quét QR, Danh bạ, Yêu cầu chia tiền, QR của tôi
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/scan-qr'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.qrcode_viewfinder, size: 16, color: AppColors.primaryDark),
                            SizedBox(width: 6),
                            Text('Quét QR', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/beneficiaries'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_2_fill, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Danh bạ', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/transfer/request'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.person_2_fill, size: 16, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text('Chia tiền', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/my-qr'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.qrcode, size: 16, color: AppColors.emeraldGreen),
                            SizedBox(width: 4),
                            Text('Mã QR', style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_selectedTab == 1) ...[
                const SizedBox(height: 20),
                Text('Ngân hàng thụ hưởng phổ biến', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularBanks.map((bank) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.text = '${bank['short']} - ';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          bank['short']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              Text('Người thụ hưởng gần đây', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              // Real Beneficiaries List
              if (_isLoadingBeneficiaries) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              ] else if (_beneficiaries.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.person_crop_circle_badge_exclam, size: 40, color: AppColors.textMutedLight.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'Chưa có người thụ hưởng đã lưu',
                        style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nhập SĐT hoặc STK ở trên để tự động nhận diện và chuyển tiền',
                        style: AppTypography.bodySmall(color: AppColors.textMutedLight.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._beneficiaries.take(5).map((b) {
                  final name = b['name'] ?? '';
                  final phone = b['phone'] ?? b['account'] ?? '';
                  final bank = b['bank'] ?? 'Ví Sen Hồng';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      quality: GlassQuality.minimal,
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          onTap: () {
                            _searchController.text = phone;
                            _lookupRecipient(phone);
                          },
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name.toUpperCase(), style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                          subtitle: Text('$bank • $phone', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                          trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Transfer & Utilities Navigation Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        label: 'Quét mã VietQR chuyển tiền tức thì 24/7',
                        onTap: () => context.push('/scan-qr'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode,
                        label: 'Mã QR nhận tiền cá nhân của tôi',
                        onTap: () => context.push('/my-qr'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                        label: 'Tạo yêu cầu chuyển tiền / Chia hóa đơn nhóm',
                        onTap: () => context.push('/transfer/request'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_2_fill,
                        label: 'Quản lý toàn bộ danh bạ người thụ hưởng',
                        onTap: () => context.push('/beneficiaries'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.clock_fill,
                        label: 'Xem lịch sử giao dịch chuyển khoản',
                        onTap: () => context.push('/history'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.creditcard_fill,
                        label: 'Nạp thêm tiền vào ví Sen Hồng',
                        onTap: () => context.push('/deposit'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
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
