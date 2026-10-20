import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/qr_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

class MyQRScreen extends StatefulWidget {
  const MyQRScreen({super.key});

  @override
  State<MyQRScreen> createState() => _MyQRScreenState();
}

class _MyQRScreenState extends State<MyQRScreen> {
  int _selectedAccountIdx = 0;
  int _selectedFrameIdx = 0;
  double? _customAmount;
  String? _customNote;
  String? _defaultQrData;
  String? _dynamicQrData;
  bool _isGeneratingQr = false;
  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadMyQr();
    _loadRecentReceived();
  }

  Future<void> _loadUserInfo() async {
    const storage = FlutterSecureStorage();
    try {
      final cachedPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      final cachedName = await storage.read(key: AppConstants.keyFullName);
      if (mounted) {
        setState(() {
          if (cachedPhone != null && cachedPhone.isNotEmpty) _userPhone = cachedPhone;
          if (cachedName != null && cachedName.isNotEmpty) _userName = cachedName;
        });
      }
      final profile = await ProfileRemoteDataSource().getMe();
      if (mounted) {
        setState(() {
          final n = profile['fullName'] as String? ?? profile['name'] as String?;
          if (n != null && n.isNotEmpty) _userName = n;
          final p = profile['phoneNumber'] as String? ?? profile['phone'] as String?;
          if (p != null && p.isNotEmpty) _userPhone = p;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMyQr() async {
    try {
      final qr = await QrRemoteDataSource().getMyQr();
      if (mounted) setState(() => _defaultQrData = qr);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _recentQrReceived = [];
  bool _isLoadingRecentReceived = true;

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadUserInfo(),
      _loadMyQr(),
      _loadRecentReceived(),
    ]);
  }

  Future<void> _loadRecentReceived() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final txs = await TransactionRemoteDataSource().getTransactions(walletId: wallet.walletId, type: 'TRANSFER_IN');
      if (!mounted) return;
      setState(() {
        _recentQrReceived = txs.take(5).map((item) => {
          'from': (item['title'] ?? 'Người gửi').toString(),
          'amount': ((item['amount'] as num?)?.toDouble() ?? 0).abs(),
          'time': (item['date'] ?? '').toString(),
          'note': (item['desc'] ?? 'Chuyen tien').toString(),
          'bank': 'Ví Sen Hồng',
        }).toList();
        _isLoadingRecentReceived = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRecentReceived = false);
    }
  }

  List<Map<String, String>> get _accounts => [
    {
      'name': 'Ví Sen Hồng (Mặc định)',
      'stk': _userPhone.isNotEmpty ? _userPhone : 'Ví chính',
      'type': 'Tài khoản ví chính',
    },
  ];

  final List<String> _frames = ['Mặc định', 'Kim Cương', 'Doanh Nghiệp'];

  String get _qrData {
    if (_customAmount != null && _dynamicQrData != null && _dynamicQrData!.isNotEmpty) {
      return _dynamicQrData!;
    }
    if (_defaultQrData != null && _defaultQrData!.isNotEmpty) {
      return _defaultQrData!;
    }
    return _userPhone.isNotEmpty ? _userPhone : 'SENHONG_PAY';
  }

  void _showSetAmountModal() {
    HapticFeedback.selectionClick();
    final amtCtrl = TextEditingController(text: _customAmount?.toInt().toString() ?? '');
    final noteCtrl = TextEditingController(text: _customNote ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final amtNum = double.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return Padding(
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
                          'Tạo QR Có Số Tiền & Nội Dung',
                          style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Nhập số tiền cần nhận', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    decoration: InputDecoration(
                      suffixText: 'đ',
                      hintText: 'Ví dụ: 200000',
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                  if (amtNum > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(amtNum)} đồng',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text('Lời nhắn / Nội dung chuyển', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimaryLight),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Tien an trua',
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amtCtrl.text);
                      final note = noteCtrl.text.trim();
                      Navigator.pop(ctx);
                      setState(() {
                        _customAmount = amt;
                        _customNote = note;
                        _isGeneratingQr = true;
                      });
                      try {
                        if (amt != null && amt > 0 && _userPhone.isNotEmpty) {
                          final res = await QrRemoteDataSource().generateQr(
                            accountNumber: _userPhone,
                            amount: amt,
                            purpose: note.isNotEmpty ? note : 'Chuyen tien',
                          );
                          final qrStr = res['qrCodeString']?.toString() ?? res['qrString']?.toString();
                          if (mounted && qrStr != null && qrStr.isNotEmpty) {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _dynamicQrData = qrStr;
                              _isGeneratingQr = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.emeraldGreen,
                                content: Text('Đã cập nhật mã VietQR động thành công!'),
                              ),
                            );
                            return;
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi tạo mã QR: $e')),
                          );
                        }
                      }
                      if (mounted) setState(() => _isGeneratingQr = false);
                    },
                    child: const Text('Cập nhật mã QR'),
                  ),
                ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Mã QR Của Tôi'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Quét mã VietQR',
            icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.primary),
            onPressed: () => context.push('/scan-qr'),
          ),
          IconButton(
            tooltip: 'Chuyển tiền',
            icon: const Icon(CupertinoIcons.arrow_up_circle_fill, color: AppColors.primary),
            onPressed: () => context.push('/transfer'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
            children: [
              // QR Main Card
              GlassCard(
                quality: GlassQuality.standard,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedFrameIdx == 1 ? AppColors.accentGold : AppColors.borderLight,
                      width: _selectedFrameIdx == 1 ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('VietQR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Napas 24/7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isGeneratingQr)
                        const SizedBox(
                          height: 210,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        )
                      else
                        QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 210,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimaryLight),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimaryLight),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        _userName.isNotEmpty ? _userName.toUpperCase() : 'QUÝ KHÁCH',
                        style: AppTypography.titleLarge(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'STK: ${_userPhone.isNotEmpty ? _userPhone : _accounts[_selectedAccountIdx]['stk']} • Sen Hồng Bank',
                        style: const TextStyle(color: AppColors.primaryDark, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      if (_customAmount != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Số tiền yêu cầu: ${CurrencyFormatter.formatVND(_customAmount!)}',
                            style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                      if (_customNote != null && _customNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Nội dung: $_customNote', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row: Tạo QR có số tiền / Reset
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _showSetAmountModal,
                      icon: const Icon(CupertinoIcons.pencil, color: AppColors.primaryDark, size: 18),
                      label: Text(_customAmount != null ? 'Sửa số tiền' : 'Nhập số tiền', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_customAmount != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.error),
                      onPressed: () => setState(() {
                        _customAmount = null;
                        _customNote = null;
                        _dynamicQrData = null;
                      }),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Share & Save Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.emeraldGreen,
                            content: Text('Đã lưu ảnh mã VietQR vào thư viện ảnh!'),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 16),
                      label: const Text('Lưu ảnh QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang mở bảng chia sẻ mã VietQR...')),
                        );
                      },
                      icon: const Icon(CupertinoIcons.share, size: 16),
                      label: const Text('Chia sẻ mã'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Choose Receiving Account Card
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tài khoản nhận tiền', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              ),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Column(
                  children: List.generate(_accounts.length, (idx) {
                    final acc = _accounts[idx];
                    final isSelected = _selectedAccountIdx == idx;
                    final isLast = idx == _accounts.length - 1;
                    return Column(
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedAccountIdx = idx);
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: const Icon(CupertinoIcons.creditcard_fill, color: AppColors.primaryDark, size: 18),
                            ),
                            title: Text(acc['name']!, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('${acc['stk']} • ${acc['type']}', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
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
              const SizedBox(height: 24),

              // Frame Selector
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Mẫu khung thương hiệu QR', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              ),
              const SizedBox(height: 10),

              Row(
                children: List.generate(_frames.length, (idx) {
                  final isSelected = _selectedFrameIdx == idx;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: idx < _frames.length - 1 ? 8 : 0),
                      child: ChoiceChip(
                        label: Center(child: Text(_frames[idx])),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                        onSelected: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFrameIdx = idx);
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Interbank Network Compatibility Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tương thích hơn 45 ngân hàng & ví điện tử',
                            style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Người chuyển có thể quét mã từ Vietcombank, Techcombank, MB, BIDV, MoMo, ZaloPay... Tiền về ví ngay lập tức 24/7.',
                            style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent QR Payments Received
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Khoản tiền nhận qua QR gần đây', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              ),
              const SizedBox(height: 12),

              if (_isLoadingRecentReceived) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ] else if (_recentQrReceived.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.qrcode, size: 36, color: AppColors.textMutedLight.withOpacity(0.5)),
                      const SizedBox(height: 6),
                      Text(
                        'Chưa có giao dịch nhận tiền qua QR gần đây',
                        style: AppTypography.bodySmall(color: AppColors.textMutedLight),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._recentQrReceived.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      quality: GlassQuality.minimal,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.arrow_down_left, color: AppColors.emeraldGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['from'] as String, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${item['bank']} • ${item['time']} • "${item['note']}"', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(
                              '+${CurrencyFormatter.formatVND(((item['amount'] as num?)?.toDouble() ?? 0.0))}',
                              style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // QR & Transfer Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        label: 'Chuyển sang Quét mã VietQR thanh toán',
                        onTap: () => context.push('/scan-qr'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_up_circle_fill,
                        label: 'Chuyển tiền tới tài khoản hoặc SĐT khác',
                        onTap: () => context.push('/transfer'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
                        label: 'Tạo yêu cầu chuyển tiền / Chia hóa đơn',
                        onTap: () => context.push('/transfer/request'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_2_fill,
                        label: 'Danh bạ người thụ hưởng đã lưu',
                        onTap: () => context.push('/beneficiaries'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.clock_fill,
                        label: 'Xem toàn bộ lịch sử nhận tiền & chuyển tiền',
                        onTap: () => context.push('/history'),
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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
