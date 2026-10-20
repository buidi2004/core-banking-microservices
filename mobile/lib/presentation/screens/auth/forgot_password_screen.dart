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
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      AppAlerts.showWarning(
        context,
        'Vui lòng nhập số điện thoại đã đăng ký để nhận mã OTP khôi phục.',
        title: 'Chưa nhập số điện thoại',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await AuthRemoteDataSource(local: AuthLocalDataSourceImpl(prefs: prefs)).forgotPassword(_phoneController.text.trim());
      if (!mounted) return;
      context.push('/auth/reset-password?phone=${Uri.encodeComponent(_phoneController.text.trim())}');
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Khôi phục mật khẩu thất bại',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Quên Mật Khẩu'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Icon Header
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(CupertinoIcons.lock_circle_fill, color: AppColors.primary, size: 38),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Khôi Phục Mật Khẩu',
                  style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Xác thực số điện thoại để cấp lại mã đăng nhập an toàn',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                ),
              ),
              const SizedBox(height: 24),

              // Steps Progression Bar
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildStepBadge(step: '1', title: 'Nhập SĐT', isActive: true, isDone: false),
                      Expanded(child: Container(height: 1.5, color: AppColors.primary.withOpacity(0.4))),
                      _buildStepBadge(step: '2', title: 'Xác thực OTP', isActive: false, isDone: false),
                      Expanded(child: Container(height: 1.5, color: AppColors.cardBorderLight)),
                      _buildStepBadge(step: '3', title: 'Tạo mật khẩu', isActive: false, isDone: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Số điện thoại đăng ký ví', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(CupertinoIcons.phone_fill, color: AppColors.primary),
                          hintText: 'Nhập số điện thoại đăng ký',
                          hintStyle: const TextStyle(color: AppColors.textMutedLight),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mã xác thực OTP 6 số sẽ được gửi qua tin nhắn SMS Brandname SenHongBank đến số thuê bao trên.',
                        style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendOtp,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Tiếp tục & Nhận mã OTP'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security Advisory Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.accentGold, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cảnh báo an ninh ngân hàng',
                            style: TextStyle(color: AppColors.warningText, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sen Hồng Bank KHÔNG BAO GIỜ yêu cầu bạn cung cấp mã OTP, mật khẩu hoặc số thẻ qua điện thoại, email hay mạng xã hội. Tuyệt đối không chia sẻ mã OTP cho bất kỳ ai.',
                            style: TextStyle(color: AppColors.warningText.withOpacity(0.95), fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Alternative Recovery Methods
              Text(
                'Phương thức khôi phục khác',
                style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Column(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(CupertinoIcons.person_crop_circle_badge_checkmark, color: AppColors.emeraldGreen, size: 22),
                        ),
                        title: Text('Xác thực khuôn mặt & CCCD gắn chip', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Dành cho trường hợp mất số điện thoại hoặc đổi SIM mới', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                        onTap: () => context.push('/profile/ekyc'),
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(CupertinoIcons.building_2_fill, color: AppColors.primary, size: 22),
                        ),
                        title: Text('Đến phòng giao dịch gần nhất', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Hỗ trợ cấp lại thông tin tại hơn 350 chi nhánh toàn quốc', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng mang theo CCCD gốc đến chi nhánh Sen Hồng Bank gần nhất.')),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.softPurple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(CupertinoIcons.phone_circle_fill, color: AppColors.softPurple, size: 22),
                        ),
                        title: Text('Tổng đài hỗ trợ 24/7 (Miễn phí)', style: AppTypography.titleSmall(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Hotline: 1900 6868 (Bấm phím 1 để gặp điện thoại viên)', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đang kết nối tới tổng đài CSKH Sen Hồng: 1900 6868')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Frequently Asked Questions
              Text(
                'Câu hỏi thường gặp',
                style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              _buildFaqItem(
                q: 'Tôi không nhận được mã xác thực OTP?',
                a: 'Vui lòng kiểm tra lại sóng điện thoại, trạng thái chặn tin nhắn quảng cáo hoặc thử chọn "Gửi lại OTP" sau 60 giây.',
              ),
              const SizedBox(height: 8),
              _buildFaqItem(
                q: 'Tài khoản có bị khóa nếu nhập sai OTP nhiều lần?',
                a: 'Để bảo đảm an toàn, tài khoản sẽ tạm khóa đăng nhập trong 30 phút nếu nhập sai OTP quá 5 lần liên tiếp.',
              ),
              const SizedBox(height: 8),
              _buildFaqItem(
                q: 'Làm thế nào để đổi số điện thoại nhận thông báo?',
                a: 'Bạn vui lòng thực hiện định danh lại CCCD gắn chip tại mục eKYC hoặc liên hệ trực tiếp quầy giao dịch.',
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
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Quên mã PIN giao dịch? Cấp lại mã PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        label: 'Chưa có tài khoản ví? Đăng ký ngay',
                        onTap: () => context.push('/auth/register'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Chưa tạo mã PIN bảo mật? Thiết lập PIN',
                        onTap: () => context.push('/auth/set-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Điều khoản dịch vụ & Chính sách bảo mật',
                        onTap: () => context.push('/auth/terms'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Cần hỗ trợ khẩn cấp? Trung tâm CSKH 24/7',
                        onTap: () => context.push('/support/help-center'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/auth/login');
                    }
                  },
                  icon: const Icon(CupertinoIcons.arrow_left, size: 16, color: AppColors.primaryDark),
                  label: const Text('Quay lại trang đăng nhập', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBadge({required String step, required String title, required bool isActive, required bool isDone}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive || isDone ? AppColors.primary : AppColors.borderLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: isActive || isDone ? Colors.white : AppColors.textMutedLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.primaryDark : AppColors.textSecondaryLight,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem({required String q, required String a}) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(q, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 13)),
        children: [
          Text(a, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 12, height: 1.4)),
        ],
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
