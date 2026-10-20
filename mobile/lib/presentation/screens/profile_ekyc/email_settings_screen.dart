import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _taxCodeCtrl = TextEditingController();
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _invoiceAddressCtrl = TextEditingController();

  bool _receiveVat = true;
  bool _receiveMonthlyStatement = true;
  bool _receiveSecurityAlerts = true;
  bool _receivePromoNews = false;
  bool _protectPdfWithPassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    const storage = FlutterSecureStorage();
    try {
      final savedName = await storage.read(key: AppConstants.keyFullName);
      if (savedName != null && savedName.isNotEmpty && mounted) {
        setState(() => _companyNameCtrl.text = savedName.toUpperCase());
      }
      final me = await ProfileRemoteDataSource().getMe();
      if (mounted) {
        setState(() {
          final mail = me['email'] as String? ?? '';
          if (mail.isNotEmpty) _emailCtrl.text = mail;
          final name = me['fullName'] as String? ?? me['name'] as String? ?? '';
          if (name.isNotEmpty) _companyNameCtrl.text = name.toUpperCase();
          final cccd = me['idNumber'] as String? ?? me['citizenId'] as String? ?? '';
          if (cccd.isNotEmpty) _taxCodeCtrl.text = cccd;
          final addr = me['address'] as String? ?? '';
          if (addr.isNotEmpty) _invoiceAddressCtrl.text = addr;
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _deliveryHistory => [
    {
      'title': 'Sao kê tài khoản Tháng 08/2026 (PDF)',
      'date': '01/09/2026 - 06:00',
      'email': _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'Email đã xác thực',
      'status': 'Đã gửi thành công',
      'icon': CupertinoIcons.doc_text_fill,
      'isSuccess': true,
    },
    {
      'title': 'Hóa đơn điện tử VAT #EVN-882910',
      'date': '15/08/2026 - 14:22',
      'email': _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'Email đã xác thực',
      'status': 'Đã gửi thành công',
      'icon': CupertinoIcons.checkmark_seal_fill,
      'isSuccess': true,
    },
    {
      'title': 'Cảnh báo đăng nhập từ thiết bị lạ',
      'date': '03/08/2026 - 19:40',
      'email': _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'Email đã xác thực',
      'status': 'Đã gửi thành công',
      'icon': CupertinoIcons.shield_lefthalf_fill,
      'isSuccess': true,
    },
  ];

  void _verifyEmailOtp() {
    final otpCtrl = TextEditingController();
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
                      'Xác Thực Email Mới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Hệ thống đã gửi mã OTP gồm 6 chữ số đến hộp thư "${_emailCtrl.text}". Vui lòng kiểm tra hộp thư đến hoặc mục thư rác (Spam).',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.primaryDark),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: const TextStyle(letterSpacing: 8, color: AppColors.textMutedLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  if (otpCtrl.text.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số OTP xác thực')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppColors.emeraldGreen, content: Text('Đã xác thực email ${_emailCtrl.text} thành công!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Xác nhận OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đã cập nhật cài đặt email & thông tin hóa đơn VAT thành công!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cài Đặt Email & Hóa Đơn VAT'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Email Input & Verification Status
            Text('Địa chỉ email nhận thông báo', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: const Icon(CupertinoIcons.mail, color: AppColors.primary),
                suffixIcon: GestureDetector(
                  onTap: _verifyEmailOtp,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen, size: 14),
                        SizedBox(width: 4),
                        Text('Đã xác minh', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Xác thực lần cuối ngày 15/08/2026. Tất cả sao kê và hóa đơn VAT sẽ được gửi về hộp thư này.',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),

            // Toggle Options
            Text('Tùy chọn nhận tài liệu điện tử', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 12),

            GlassCard(
              quality: GlassQuality.minimal,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _receiveVat,
                    activeTrackColor: AppColors.primary,
                    title: Text('Hóa đơn điện tử VAT', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                    subtitle: Text('Tự động gửi hóa đơn GTGT sau mỗi lần thanh toán phí dịch vụ hoặc nợ cước', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    onChanged: (v) => setState(() => _receiveVat = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.cardBorderLight),
                  SwitchListTile.adaptive(
                    value: _receiveMonthlyStatement,
                    activeTrackColor: AppColors.primary,
                    title: Text('Sao kê tài khoản định kỳ', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                    subtitle: Text('Gửi file PDF tổng kết thu chi tài khoản vào ngày 01 hàng tháng', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    onChanged: (v) => setState(() => _receiveMonthlyStatement = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.cardBorderLight),
                  SwitchListTile.adaptive(
                    value: _receiveSecurityAlerts,
                    activeTrackColor: AppColors.primary,
                    title: Text('Cảnh báo an ninh & Đăng nhập mới', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                    subtitle: Text('Thông báo ngay lập tức khi phát hiện đăng nhập từ trình duyệt hoặc thiết bị lạ', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    onChanged: (v) => setState(() => _receiveSecurityAlerts = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.cardBorderLight),
                  SwitchListTile.adaptive(
                    value: _receivePromoNews,
                    activeTrackColor: AppColors.primary,
                    title: Text('Tin tức ưu đãi & Hoàn tiền', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                    subtitle: Text('Nhận các voucher khuyến mãi thanh toán hóa đơn độc quyền từ đối tác Sen Hồng', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    onChanged: (v) => setState(() => _receivePromoNews = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security PDF Protection
            Text('Bảo mật file PDF sao kê', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 12),

            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _protectPdfWithPassword,
                      activeTrackColor: AppColors.primary,
                      title: Text('Đặt mật khẩu mã hóa file sao kê', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      subtitle: Text('Chống mở trộm sao kê khi gửi qua email. Mật khẩu mặc định là 6 số cuối CCCD của bạn.', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                      onChanged: (v) => setState(() => _protectPdfWithPassword = v),
                    ),
                    if (_protectPdfWithPassword) ...[
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.lock_shield_fill, color: AppColors.emeraldGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mật khẩu mở file hiện tại: •••••• (6 số cuối CCCD)',
                              style: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // VAT Invoicing Information
            Text('Thông tin xuất hóa đơn VAT', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 6),
            Text('Dùng để xuất hóa đơn điện tử cho các khoản phí dịch vụ, cước giao dịch theo quy định Bộ Tài chính', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 12),

            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã số thuế (MST)', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _taxCodeCtrl,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('Tên đơn vị / Cá nhân nộp thuế', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _companyNameCtrl,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('Địa chỉ đăng ký kinh doanh / Thường trú', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _invoiceAddressCtrl,
                      style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 15),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Delivery History Log
            Text('Lịch sử gửi tài liệu gần đây', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 12),

            ..._deliveryHistory.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] as String, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${item['date']} • ${item['email']}', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Thành công', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Lưu cài đặt email & hóa đơn VAT'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
