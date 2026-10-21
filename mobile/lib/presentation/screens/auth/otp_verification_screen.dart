import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sen_hong_bank/core/network/permission_service.dart';
import 'package:sen_hong_bank/core/storage/app_session.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/custom_pin_numpad.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phone;
  final String? email;

  /// Dữ liệu đăng ký (fullName, password, deviceId) — chỉ có trong luồng đăng ký.
  /// Tài khoản chỉ được tạo SAU KHI mã OTP được xác thực thành công.
  final Map<String, dynamic>? extra;

  const OtpVerificationScreen({super.key, this.phone, this.email, this.extra});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otp = '';
  int _selectedChannel = 0; // 0: Gmail, 1: SMS, 2: Smart OTP
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Ưu tiên chọn Gmail nếu có email được truyền từ luồng đăng ký/quên mật khẩu
    if (widget.email != null && widget.email!.isNotEmpty) {
      _selectedChannel = 0;
    } else {
      _selectedChannel = 1;
    }
  }

  Future<void> _resendOtp() async {
    final phone = widget.phone ?? '';
    if (phone.isEmpty) return;
    try {
      await AuthRemoteDataSource().sendOtp(phone, purpose: 'REGISTER', email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.email != null && widget.email!.isNotEmpty
                ? 'Mã OTP mới đã được gửi tới Gmail ${widget.email} (hiệu lực 180s)'
                : 'Mã OTP mới đã được gửi thành công (hiệu lực 180s)',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi mã OTP: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onOtpChanged(String value) async {
    setState(() => _otp = value);
    if (value.length == 6) {
      if (_isVerifying) return;
      setState(() => _isVerifying = true);
      try {
        final phone = widget.phone ?? '';
        final success = await AuthRemoteDataSource().verifyOtp(
          phoneNumber: phone,
          otp: value,
          purpose: 'REGISTER',
        );
        if (!mounted) return;
        if (success) {
          // Luồng đăng ký: chỉ tạo tài khoản SAU KHI xác thực Gmail thành công.
          final extra = widget.extra;
          final isRegistration =
              extra != null && (extra['password'] as String?)?.isNotEmpty == true;
          if (isRegistration) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await AuthRemoteDataSource(
                local: AuthLocalDataSourceImpl(prefs: prefs),
              ).register(
                phoneNumber: widget.phone ?? '',
                fullName: (extra['fullName'] as String?) ?? '',
                password: extra['password'] as String,
                deviceId: (extra['deviceId'] as String?) ??
                    'flutter-${DateTime.now().millisecondsSinceEpoch}',
                email: widget.email,
              );
              if (!mounted) return;
              AppSession.unlocked = true;
              unawaited(PermissionService().requestAllAppPermissions());
            } catch (e) {
              if (!mounted) return;
              HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tạo tài khoản không thành công: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
          }
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực mã OTP thành công! Tiến hành thiết lập mã PIN 6 số.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/auth/set-pin');
        } else {
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã OTP không chính xác hoặc đã hết hạn'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _otp = '');
        }
      } catch (e) {
        if (!mounted) return;
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác thực: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _otp = '');
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.phone;
    final displayPhone = (p != null && p.length >= 7)
        ? '${p.substring(0, 3)} ••• ${p.substring(p.length - 3)}'
        : (p != null && p.isNotEmpty ? p : 'Số điện thoại đăng ký');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Xác Thực Bảo Mật OTP'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              // Registration Steps Tracker (3 Steps: 1 Thông tin -> 2 OTP Gmail -> 3 Tạo mã PIN)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, 'Thông tin', isActive: false, isDone: true),
                  _buildStepConnector(isDone: true),
                  _buildStepIndicator(2, 'OTP Gmail', isActive: true, isDone: false),
                  _buildStepConnector(isDone: false),
                  _buildStepIndicator(3, 'Tạo mã PIN', isActive: false, isDone: false),
                ],
              ),
              const SizedBox(height: 16),

              // Banner Thông tin OTP
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.shield_fill, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mã xác thực OTP gồm 6 chữ số có hiệu lực trong 180 giây. Vui lòng kiểm tra Gmail hoặc SMS và nhập mã bên dưới.',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.3, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Method toggle: Gmail OTP vs SMS OTP vs Smart OTP
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedChannel = 0),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedChannel == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedChannel == 0
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.mail_solid, size: 15, color: _selectedChannel == 0 ? AppColors.primary : AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Text('Gmail OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedChannel == 0 ? AppColors.primary : AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedChannel = 1),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedChannel == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedChannel == 1
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.chat_bubble_text_fill, size: 15, color: _selectedChannel == 1 ? AppColors.primary : AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Text('SMS OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedChannel == 1 ? AppColors.primary : AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedChannel = 2);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chế độ Smart OTP: Mã sinh tự động bảo mật cao theo chuẩn PKI.')),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedChannel == 2 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedChannel == 2
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.shield_lefthalf_fill, size: 15, color: _selectedChannel == 2 ? AppColors.primary : AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Text('Smart OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedChannel == 2 ? AppColors.primary : AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedChannel == 0
                        ? CupertinoIcons.mail_solid
                        : (_selectedChannel == 2 ? CupertinoIcons.lock_shield_fill : CupertinoIcons.device_phone_portrait),
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Nhập Mã Xác Thực 6 Số', style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                _selectedChannel == 0 && widget.email != null && widget.email!.isNotEmpty
                    ? 'Mã xác thực OTP đã được gửi đến Gmail:\n${widget.email}\n(Vui lòng kiểm tra Hộp thư đến hoặc Thư rác/Spam)'
                    : (_selectedChannel == 2
                        ? 'Mã bảo mật Smart OTP được sinh tự động trên thiết bị chính chủ của bạn'
                        : 'Mã xác thực một lần (OTP) đã gửi qua SMS tới số $displayPhone'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 14),

              // Anti-fraud security warning banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'CẢNH BÁO: Ngân hàng KHÔNG BAO GIỜ yêu cầu cung cấp OTP. Tuyệt đối không chia sẻ mã này cho bất kỳ ai!',
                        style: TextStyle(fontSize: 11, color: AppColors.errorText, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // PIN Numpad
              CustomPinNumpad(
                pin: _otp,
                maxDigits: 6,
                onPinChanged: _onOtpChanged,
              ),
              const SizedBox(height: 16),

              // Resend & Voice OTP actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _resendOtp,
                    icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 16),
                    label: Text(
                      widget.email != null && widget.email!.isNotEmpty
                          ? 'Gửi lại OTP Gmail'
                          : 'Gửi lại mã OTP SMS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Text(' • ', style: TextStyle(color: AppColors.textSecondaryLight)),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng nhận cuộc gọi OTP đang được phát triển. Vui lòng nhận mã qua Gmail hoặc SMS.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.phone_arrow_up_right, size: 16),
                    label: const Text('Nhận cuộc gọi OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quay lại Đăng ký button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/auth/register');
                    }
                  },
                  icon: const Icon(CupertinoIcons.arrow_left, size: 18),
                  label: const Text('Quay lại Thông tin Đăng ký'),
                ),
              ),
              const SizedBox(height: 12),

              // Về Trang Chủ button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(CupertinoIcons.home, size: 18),
                  label: const Text('Về Trang Chủ'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Auth Navigation Router Hub
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.pencil_circle_fill,
                        label: 'Đổi số điện thoại / Sửa thông tin đăng ký',
                        onTap: () => context.push('/auth/register'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: 'Quay lại màn hình Đăng nhập',
                        onTap: () => context.go('/auth/login'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_circle_fill,
                        label: 'Quên mật khẩu? Khôi phục mật khẩu',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Quên mã PIN giao dịch? Cấp lại mã PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Xem Điều khoản dịch vụ & Quy định bảo mật',
                        onTap: () => context.push('/auth/terms'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Không nhận được OTP? Hotline CSKH 1900 6688',
                        onTap: () => context.push('/support/help-center'),
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

  Widget _buildStepIndicator(int step, String label, {required bool isActive, required bool isDone}) {
    final color = isDone ? AppColors.emeraldGreen : (isActive ? AppColors.primary : AppColors.textMutedLight);
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: color,
          child: Text('$step', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 36,
      height: 2,
      color: isDone ? AppColors.emeraldGreen : AppColors.borderSubtle,
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
              child: Text(label, style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 14),
          ],
        ),
      ),
    );
  }
}
