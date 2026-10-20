import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _agreeTerms = true;
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  int _calculatePassStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.contains(RegExp(r'[0-9]'))) score++;
    if (pass.contains(RegExp(r'[a-zA-Z]'))) score++;
    if (pass.length >= 8 && pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passController.text;
    final strength = _calculatePassStrength(pass);

    Color strengthColor = AppColors.textMutedLight;
    String strengthLabel = 'Chưa nhập';
    if (strength == 1) {
      strengthColor = AppColors.error;
      strengthLabel = 'Yếu';
    } else if (strength == 2) {
      strengthColor = AppColors.accentGold;
      strengthLabel = 'Trung bình';
    } else if (strength >= 3) {
      strengthColor = AppColors.emeraldGreen;
      strengthLabel = 'Mạnh';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Registration Steps Tracker (2 Steps)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, 'Thông tin', isActive: true, isDone: false),
                  _buildStepConnector(isDone: false),
                  _buildStepIndicator(2, 'Tạo mã PIN', isActive: false, isDone: false),
                ],
              ),
              const SizedBox(height: 20),

              Text('Mở ví Sen Hồng', style: AppTypography.displayMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Đăng ký tài khoản tài chính số miễn phí chỉ trong 2 phút', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 20),

              // Phone Number Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại đăng ký (Chính chủ)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(CupertinoIcons.phone_fill, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 14),

              // Full Name Field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Họ và tên (như trên CCCD)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(CupertinoIcons.person_fill, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 14),

              // Password Field
              TextField(
                controller: _passController,
                obscureText: _obscurePass,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(CupertinoIcons.lock_fill, color: AppColors.primary),
                  suffixIcon: MorphEyeButton(
                    isHidden: _obscurePass,
                    color: AppColors.textSecondaryLight,
                    size: 20,
                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 8),

              // Password Strength Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: strength / 4,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Độ bảo mật: $strengthLabel',
                      style: TextStyle(color: strengthColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Referral Code Field (Optional)
              TextField(
                controller: _referralController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Mã người giới thiệu (Tùy chọn nhận 50.000đ)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  prefixIcon: const Icon(CupertinoIcons.gift_fill, color: AppColors.accentGold),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 14),

              // Anti-fraud security notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.emeraldGreen, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quy định NHNN: Mỗi cá nhân chỉ được mở 01 ví chính chủ liên kết với đúng số CCCD gắn chip.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _agreeTerms = v ?? true),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/auth/terms'),
                      child: Text.rich(
                        TextSpan(
                          text: 'Tôi đồng ý với ',
                          style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                          children: const [
                            TextSpan(
                              text: 'Điều khoản dịch vụ & Chính sách bảo mật',
                              style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agreeTerms
                      ? () async {
                          final phone = _phoneController.text.trim();
                          final name = _nameController.text.trim();
                          final pass = _passController.text;
                          if (phone.isEmpty) {
                            HapticFeedback.vibrate();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập số điện thoại'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          if (name.isEmpty) {
                            HapticFeedback.vibrate();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập họ và tên'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          if (pass.length < 6) {
                            HapticFeedback.vibrate();
                            AppAlerts.showWarning(
                              context,
                              'Mật khẩu phải có tối thiểu 6 ký tự để đảm bảo an toàn.',
                              title: 'Mật khẩu quá ngắn',
                            );
                            return;
                          }
                          setState(() => _isLoading = true);
                          final router = GoRouter.of(context);
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await AuthRemoteDataSource(
                              local: AuthLocalDataSourceImpl(prefs: prefs),
                            ).register(
                              phoneNumber: phone,
                              fullName: _nameController.text.trim(),
                              password: _passController.text,
                              deviceId: 'flutter-${DateTime.now().millisecondsSinceEpoch}',
                            );
                            if (!mounted) return;
                            router.push('/auth/set-pin');
                          } catch (error) {
                            if (!mounted || !context.mounted) return;
                            AppAlerts.showError(
                              context,
                              extractErrorMessage(error),
                              title: 'Đăng ký không thành công',
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Tiếp tục tạo mã PIN'),
                ),
              ),
              const SizedBox(height: 16),

              // Login Router Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Đã có tài khoản ví?', style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight)),
                  TextButton(
                    onPressed: () => context.push('/auth/login'),
                    child: const Text('Đăng nhập ngay', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Auth Navigation Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Đã có tài khoản nhưng chưa tạo PIN? Thiết lập PIN',
                        onTap: () => context.push('/auth/set-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                        label: 'Quên mật khẩu đăng nhập? Khôi phục mật khẩu',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Quên mã PIN thanh toán? Cấp lại mã PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Xem Điều khoản dịch vụ & Chính sách quyền riêng tư',
                        onTap: () => context.push('/auth/terms'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Cần hỗ trợ đăng ký? Hotline CSKH 1900 6868',
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
