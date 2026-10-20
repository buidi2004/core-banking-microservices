import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';
import 'package:sen_hong_bank/presentation/widgets/app_morph_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? phone;
  const ResetPasswordScreen({super.key, this.phone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  Timer? _timer;
  int _secondsLeft = 60;
  int _passStrength = 0; // 0: rỗng, 1: yếu, 2: trung bình, 3: rất mạnh

  @override
  void initState() {
    super.initState();
    _startTimer();
    _passController.addListener(_evalPasswordStrength);
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _evalPasswordStrength() {
    final text = _passController.text;
    if (text.isEmpty) {
      setState(() => _passStrength = 0);
      return;
    }
    int score = 0;
    if (text.length >= 6) score++;
    if (text.contains(RegExp(r'[0-9]')) && text.contains(RegExp(r'[a-zA-Z]'))) score++;
    if (text.length >= 8 && text.contains(RegExp(r'[!@#\$&*~]'))) score++;
    setState(() => _passStrength = score == 0 ? 1 : score);
  }

  void _resendOtp() {
    _startTimer();
    AppAlerts.showSuccess(context, 'Đã gửi lại mã OTP qua tin nhắn SMS!');
  }

  void _requestVoiceOtp() {
    _startTimer();
    AppAlerts.showSuccess(context, 'Tổng đài tự động SenBank đang gọi đến số điện thoại của bạn...');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passController.removeListener(_evalPasswordStrength);
    _otpController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_otpController.text.length < 6) {
      AppAlerts.showWarning(context, 'Vui lòng nhập đủ 6 chữ số mã OTP', title: 'Mã OTP chưa đủ');
      return;
    }
    if (_passController.text.length < 6) {
      AppAlerts.showWarning(context, 'Mật khẩu mới phải có tối thiểu 6 ký tự', title: 'Mật khẩu quá ngắn');
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      AppAlerts.showWarning(context, 'Xác nhận mật khẩu không trùng khớp', title: 'Xác nhận mật khẩu sai');
      return;
    }

    final phone = widget.phone;
    if (phone == null || phone.isEmpty) {
      AppAlerts.showError(context, 'Thiếu số điện thoại khôi phục', title: 'Lỗi');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).resetPassword(
        phoneNumber: phone,
        otp: _otpController.text,
        newPassword: _passController.text,
      );
      if (!mounted) return;
      AppAlerts.showSuccess(context, 'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.', title: 'Thành công');
      context.go('/auth/login');
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(context, extractErrorMessage(error), title: 'Đặt lại mật khẩu thất bại');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPhone = widget.phone ?? 'Số điện thoại chưa xác định';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Đặt Lại Mật Khẩu'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thiết lập mật khẩu mới',
                style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Mã OTP đã được gửi đến số điện thoại $displayPhone. Vui lòng nhập mã và thiết lập mật khẩu bảo mật mới.',
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 24),

              // OTP field
              Text('Mã xác thực OTP (6 số)', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: AppColors.primaryDark, fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.primary),
                  hintText: '• • • • • •',
                  hintStyle: const TextStyle(color: AppColors.textMutedLight, letterSpacing: 4),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 8),

              // OTP Countdown & Resend Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_secondsLeft > 0)
                    Row(
                      children: [
                        const Icon(CupertinoIcons.stopwatch, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text('Gửi lại mã sau ${_secondsLeft}s', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        InkWell(
                          onTap: _resendOtp,
                          child: const Text('Gửi lại SMS OTP', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _requestVoiceOtp,
                          child: const Text('Nhận cuộc gọi Voice OTP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  if (_secondsLeft > 0)
                    InkWell(
                      onTap: _requestVoiceOtp,
                      child: const Text('Gọi Voice OTP', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // New Password
              Text('Mật khẩu mới', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              TextField(
                controller: _passController,
                obscureText: _obscurePass,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(CupertinoIcons.lock_fill, color: AppColors.primary),
                  suffixIcon: MorphEyeButton(
                    isHidden: _obscurePass,
                    color: AppColors.textMutedLight,
                    size: 20,
                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  hintText: 'Tối thiểu 6 ký tự',
                  hintStyle: const TextStyle(color: AppColors.textMutedLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),

              // Password Strength Indicator Bar
              if (_passController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _passStrength / 3.0,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _passStrength == 1
                                ? AppColors.error
                                : (_passStrength == 2 ? AppColors.accentGold : AppColors.emeraldGreen),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _passStrength == 1
                          ? 'Mật khẩu yếu'
                          : (_passStrength == 2 ? 'Mức độ trung bình' : 'Mật khẩu rất mạnh'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _passStrength == 1
                            ? AppColors.error
                            : (_passStrength == 2 ? AppColors.warningText : AppColors.emeraldGreen),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Confirm New Password
              Text('Xác nhận mật khẩu mới', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPassController,
                obscureText: _obscureConfirmPass,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.primary),
                  suffixIcon: MorphEyeButton(
                    isHidden: _obscureConfirmPass,
                    color: AppColors.textMutedLight,
                    size: 20,
                    onTap: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                  ),
                  hintText: 'Nhập lại mật khẩu mới',
                  hintStyle: const TextStyle(color: AppColors.textMutedLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 16),

              // Password Checklist
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.emeraldGreen, size: 16),
                        SizedBox(width: 8),
                        Text('Độ dài tối thiểu 6 ký tự', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.emeraldGreen, size: 16),
                        SizedBox(width: 8),
                        Text('Nên bao gồm cả chữ và số để tăng độ an toàn', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Hoàn tất đặt lại mật khẩu'),
                ),
              ),
              const SizedBox(height: 20),

              // Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Quay lại bước nhập số điện thoại nhận OTP',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: 'Đã nhớ lại mật khẩu? Đăng nhập ngay',
                        onTap: () => context.go('/auth/login'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Cần cấp lại mã PIN giao dịch? Cấp lại PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Chưa tạo mã PIN bảo mật? Thiết lập PIN',
                        onTap: () => context.push('/auth/set-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        label: 'Chưa có tài khoản ví Sen Hồng? Đăng ký',
                        onTap: () => context.push('/auth/register'),
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
                        label: 'Trợ giúp khẩn cấp CSKH 24/7',
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
