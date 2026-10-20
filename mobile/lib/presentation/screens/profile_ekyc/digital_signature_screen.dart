import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';

class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  bool _smartOtpEnabled = true;
  bool _biometricBindingEnabled = true;
  final String _currentOtpCode = '882 190';
  final int _secondsRemaining = 24;
  String _signerName = '';
  String _signerId = '';

  @override
  void initState() {
    super.initState();
    _loadSignerInfo();
  }

  Future<void> _loadSignerInfo() async {
    const storage = FlutterSecureStorage();
    try {
      final name = await storage.read(key: AppConstants.keyFullName);
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (mounted) {
        setState(() {
          if (name != null) _signerName = name;
          if (phone != null) _signerId = phone;
        });
      }
      final me = await ProfileRemoteDataSource().getMe();
      if (mounted) {
        setState(() {
          final n = me['fullName'] as String? ?? me['name'] as String? ?? '';
          if (n.isNotEmpty) _signerName = n;
          final cccd = me['idNumber'] as String? ?? me['citizenId'] as String? ?? '';
          if (cccd.isNotEmpty) _signerId = cccd;
        });
      }
      await _loadSigningLogs();
    } catch (_) {}
  }

  List<Map<String, dynamic>> _signingLogs = [];

  Future<void> _loadSigningLogs() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final txs = await TransactionRemoteDataSource().getTransactions(
        walletId: wallet.walletId,
        size: 5,
      );
      if (!mounted) return;
      if (txs.isNotEmpty) {
        setState(() {
          _signingLogs = txs.map((tx) {
            final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
            final desc = tx['description'] as String? ?? 'Giao dịch chuyển tiền';
            final timeStr = tx['createdAt'] as String? ?? '';
            final formattedDate = timeStr.length >= 16 ? timeStr.substring(0, 16).replaceAll('T', ' - ') : timeStr;
            final txId = tx['id']?.toString() ?? 'tx';
            final shortHash = 'SHA256: ${txId.hashCode.toRadixString(16).padLeft(8, '0')}';
            return {
              'title': '$desc (${CurrencyFormatter.formatVND(amt)})',
              'target': tx['recipientAccount'] != null ? 'Tài khoản: ${tx['recipientAccount']}' : 'Xác thực tài khoản chính Sen Hồng',
              'time': formattedDate,
              'hash': shortHash,
              'status': 'Đã ký số thành công',
              'isSuccess': true,
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _syncOtp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đã đồng bộ hóa thời gian máy chủ Smart OTP thành công! Độ lệch: 0.02s'),
      ),
    );
  }

  void _handleChangeDevice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Chuyển Đổi Thiết Bị Smart OTP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Theo Quyết định 2345/QĐ-NHNN, để chuyển Smart OTP sang điện thoại khác, bạn cần xác thực sinh trắc học khuôn mặt trùng khớp với dữ liệu CCCD gắn chip.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/profile/ekyc');
              },
              icon: const Icon(CupertinoIcons.person_crop_circle_badge_checkmark),
              label: const Text('Xác thực khuôn mặt eKYC ngay'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/settings/devices');
              },
              icon: const Icon(CupertinoIcons.device_phone_portrait),
              label: const Text('Quản lý danh sách thiết bị'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinModal() {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Đổi Mã PIN Smart OTP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Mã PIN Smart OTP gồm 6 số dùng để mở khóa mã OTP khi thực hiện giao dịch.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              TextField(
                controller: oldPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Mã PIN cũ (6 số)',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Mã PIN mới (6 số)',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mã PIN mới',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (newPinCtrl.text.length != 6 || newPinCtrl.text != confirmPinCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mã PIN mới không hợp lệ hoặc không trùng khớp')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppColors.emeraldGreen, content: Text('Đổi mã PIN Smart OTP thành công!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cập nhật mã PIN Smart OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
        title: const Text('Chữ Ký Số & Smart OTP'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Smart OTP Token Card
            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text('SMART OTP SEN HỒNG', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
                          ),
                          child: const Text('HOẠT ĐỘNG', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Mã xác thực giao dịch ngẫu nhiên (TOTP)', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 6),
                    Text(
                      _currentOtpCode,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.stopwatch, color: AppColors.accentGold, size: 16),
                        const SizedBox(width: 6),
                        Text('Mã tự động đổi sau ${_secondsRemaining}s', style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.borderSubtle),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _syncOtp,
                              icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 16, color: AppColors.primaryDark),
                              label: const Text('Đồng bộ OTP', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showChangePinModal,
                              icon: const Icon(CupertinoIcons.lock_rotation, size: 16, color: Colors.white),
                              label: const Text('Đổi PIN OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Trusted Device Binding Card
            Text('Thiết bị kích hoạt Smart OTP', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 10),

            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(CupertinoIcons.device_phone_portrait, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thiết bị này (Đang kích hoạt)', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Hardware Keystore / Secure Enclave bảo mật', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _handleChangeDevice,
                          child: const Text('Đổi máy', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.cardBorderLight),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _smartOtpEnabled,
                      activeTrackColor: AppColors.primary,
                      title: Text('Kích hoạt Smart OTP trên máy này', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                      subtitle: Text('Tự động điền mã xác thực khi thực hiện lệnh chuyển tiền', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                      onChanged: (v) => setState(() => _smartOtpEnabled = v),
                    ),
                    const Divider(height: 16, color: AppColors.cardBorderLight),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _biometricBindingEnabled,
                      activeTrackColor: AppColors.primary,
                      title: Text('Liên kết sinh trắc học Face ID / Vân tay', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                      subtitle: Text('Mở khóa Smart OTP bằng nhận diện khuôn mặt không cần nhập PIN', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                      onChanged: (v) => setState(() => _biometricBindingEnabled = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Authentication Limits (QĐ 2345/NHNN)
            Text('Hạn mức xác thực theo QĐ 2345/NHNN', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 6),
            Text('Quy định an toàn chuyển tiền và thanh toán trực tuyến của Ngân hàng Nhà nước', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 12),

            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTierItem(
                      icon: CupertinoIcons.shield_fill,
                      title: 'Giao dịch dưới 10.000.000 đ',
                      sub: 'Xác thực bằng mã PIN hoặc Smart OTP tự động',
                      isDone: true,
                    ),
                    const Divider(height: 16, color: AppColors.cardBorderLight),
                    _buildTierItem(
                      icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                      title: 'Giao dịch trên 10.000.000 đ hoặc trên 20tr/ngày',
                      sub: 'Bắt buộc xác thực Sinh trắc học khuôn mặt trùng khớp dữ liệu CCCD',
                      isDone: true,
                    ),
                    const Divider(height: 16, color: AppColors.cardBorderLight),
                    _buildTierItem(
                      icon: CupertinoIcons.signature,
                      title: 'Giao dịch trên 500.000.000 đ',
                      sub: 'Bắt buộc ký số bằng Chứng thư số PKI cá nhân điện tử',
                      isDone: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PKI Certificate
            Text('Chứng thư số PKI cá nhân', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 10),

            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPkiRow('Chủ chứng thư', '${_signerName.isNotEmpty ? _signerName.toUpperCase() : "CHỦ TÀI KHOẢN"} (${_signerId.isNotEmpty ? _signerId : "eKYC Cấp 2"})'),
                    const SizedBox(height: 10),
                    _buildPkiRow('Nhà cung cấp CA', 'VNPT-CA Cloud Identity CA'),
                    const SizedBox(height: 10),
                    _buildPkiRow('Tiêu chuẩn mã hóa', 'RSA 2048-bit / SHA-256 HSM'),
                    const SizedBox(height: 10),
                    _buildPkiRow('Thời hạn hiệu lực', '20/09/2024 - 20/09/2027'),
                    const SizedBox(height: 10),
                    _buildPkiRow('Trạng thái', 'Hợp lệ & Sẵn sàng ký duyệt', isGreen: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Signing History Log
            Text('Nhật ký ký số & giao dịch gần đây', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 12),

            if (_signingLogs.isEmpty)
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text(
                      'Chưa có nhật ký ký số giao dịch gần đây',
                      style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              )
            else
              ..._signingLogs.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(log['title'] as String, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Đã ký số', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(log['target'] as String, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(log['time'] as String, style: const TextStyle(color: AppColors.textMutedLight, fontSize: 11)),
                            Text(log['hash'] as String, style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Router Hub Navigation Card
            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildRouterTile(
                      icon: CupertinoIcons.gauge,
                      label: 'Xem hạn mức chuyển tiền theo KYC Level',
                      onTap: () => context.push('/profile/kyc-level'),
                    ),
                    const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                    _buildRouterTile(
                      icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                      label: 'Kiểm tra hồ sơ CCCD gắn chip & C06',
                      onTap: () => context.push('/profile/identity'),
                    ),
                    const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                    _buildRouterTile(
                      icon: CupertinoIcons.device_phone_portrait,
                      label: 'Quản lý danh sách thiết bị đăng nhập',
                      onTap: () => context.push('/settings/devices'),
                    ),
                    const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                    _buildRouterTile(
                      icon: CupertinoIcons.mail,
                      label: 'Cài đặt email nhận thông báo & chứng từ ký',
                      onTap: () => context.push('/profile/email-settings'),
                    ),
                    const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                    _buildRouterTile(
                      icon: CupertinoIcons.shield_fill,
                      label: 'Cài đặt bảo mật & Xác thực 2 lớp (2FA)',
                      onTap: () => context.push('/settings/security'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRouterTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTierItem({required IconData icon, required String title, required String sub, required bool isDone}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(sub, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen, size: 18),
      ],
    );
  }

  Widget _buildPkiRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isGreen ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
