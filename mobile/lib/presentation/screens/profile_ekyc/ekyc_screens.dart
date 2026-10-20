import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

class EKycScreen extends StatefulWidget {
  const EKycScreen({super.key});

  @override
  State<EKycScreen> createState() => _EKycScreenState();
}

class _EKycScreenState extends State<EKycScreen> {
  final int _step = 1; // 1: Front ID, 2: Back ID, 3: Face Liveness, 4: Complete
  final bool _isCapturing = false;

  void _nextStep() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('eKYC chưa thể hoàn tất: cần tích hợp camera và upload ảnh lên storage trước khi gửi BE.')),
    );
  }

  void _readNfcChip() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.radiowaves_right, color: AppColors.primary, size: 54),
            const SizedBox(height: 14),
            Text('Đọc Chip CCCD Qua Sóng NFC', style: AppTypography.titleLarge(color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            const Text(
              'Áp mặt sau của thẻ CCCD gắn chip sát vào phần lưng phía trên của điện thoại để hệ thống đối chiếu chữ ký số ICAO Bộ Công An.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppColors.emeraldGreen, content: Text('Đã đọc dữ liệu chip vi mạch CCCD thành công qua NFC!')),
                );
              },
              child: const Text('Bắt đầu quét NFC'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuidanceModal() {
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
              children: [
                const Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Quy Chuẩn Chụp Ảnh eKYC', style: AppTypography.titleLarge(color: AppColors.primaryDark)),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuidanceItem('1. Thẻ CCCD chính chủ:', 'Sử dụng thẻ căn cước gắn chip còn hạn sử dụng, không dùng bản sao photo, không dùng màn hình điện thoại khác.'),
            _buildGuidanceItem('2. Tránh lóa sáng & bóng gương:', 'Không bật đèn flash chiếu thẳng vào thẻ, tránh chụp dưới bóng đèn huỳnh quang làm mờ số CCCD.'),
            _buildGuidanceItem('3. Nhận diện khuôn mặt:', 'Tháo kính râm, khẩu trang và mũ. Giữ máy ngang tầm mắt và làm theo hiệu lệnh chớp mắt trên màn hình.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu quy chuẩn'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight, height: 1.35)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Xác Thực eKYC (Bước $_step/3)'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Đọc NFC',
            icon: const Icon(CupertinoIcons.radiowaves_right, color: AppColors.primary),
            onPressed: _readNfcChip,
          ),
          IconButton(
            tooltip: 'Hướng dẫn eKYC',
            icon: const Icon(CupertinoIcons.question_circle_fill, color: AppColors.primary),
            onPressed: _showGuidanceModal,
          ),
        ],
      ),
      body: SafeArea(
        child: _step == 4 ? _buildSuccessView() : _buildStepView(),
      ),
    );
  }

  Widget _buildStepView() {
    String stepTitle = '';
    String stepInstruction = '';
    IconData stepIcon = CupertinoIcons.camera_fill;

    if (_step == 1) {
      stepTitle = 'Chụp mặt trước CCCD gắn chip';
      stepInstruction = 'Đặt mặt trước thẻ nằm trọn vẹn trong khung hình, đảm bảo rõ nét, không lóa sáng.';
      stepIcon = CupertinoIcons.creditcard_fill;
    } else if (_step == 2) {
      stepTitle = 'Chụp mặt sau CCCD gắn chip';
      stepInstruction = 'Đặt mặt sau thẻ, rõ dải mã vạch MRZ và chip vi mạch.';
      stepIcon = CupertinoIcons.creditcard;
    } else if (_step == 3) {
      stepTitle = 'Quét khuôn mặt (Face Liveness)';
      stepInstruction = 'Nhìn thẳng vào camera, giữ điện thoại ngang tầm mắt và chớp mắt nhẹ.';
      stepIcon = CupertinoIcons.person_crop_circle;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (idx) {
              final stepNum = idx + 1;
              final isCurrent = stepNum == _step;
              final isDone = stepNum < _step;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDone
                        ? AppColors.emeraldGreen
                        : (isCurrent ? AppColors.primary : AppColors.borderLight),
                    child: isDone
                        ? const Icon(CupertinoIcons.checkmark, size: 14, color: Colors.white)
                        : Text('$stepNum', style: TextStyle(fontSize: 12, color: isCurrent ? Colors.white : AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
                  ),
                  if (idx < 2)
                    Container(
                      width: 40,
                      height: 2,
                      color: isDone ? AppColors.emeraldGreen : AppColors.borderLight,
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 18),

          Text(stepTitle, textAlign: TextAlign.center, style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 4),
          Text(stepInstruction, textAlign: TextAlign.center, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 20),

          // Camera Viewfinder Simulation
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Simulated guide frame
                  if (_step == 3)
                    Container(
                      width: 220,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(120),
                        border: Border.all(color: AppColors.emeraldGreen, width: 2.5),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.person_alt, size: 100, color: Colors.white24),
                      ),
                    ),
                  if (_step != 3)
                    Container(
                      width: 280,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Icon(stepIcon, size: 64, color: Colors.white24),
                      ),
                    ),

                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _step == 3 ? 'AI Face Liveness: 99.8%' : 'AI OCR: Tự động căn chỉnh',
                        style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _nextStep,
              icon: _isCapturing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(CupertinoIcons.camera_fill, size: 20),
              label: Text(_isCapturing ? 'Đang xử lý hình ảnh...' : (_step == 3 ? 'Hoàn tất quét khuôn mặt' : 'Chụp ảnh & Tiếp tục')),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 54),
          ),
          const SizedBox(height: 20),
          Text('Xác Thực eKYC Thành Công!', style: AppTypography.displaySmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Hệ thống đã đối soát thành công thông tin CCCD gắn chip và sinh trắc học khuôn mặt của quý khách.\nTài khoản đã được nâng lên Cấp 2 với hạn mức 100.000.000đ/ngày.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            child: const Text('Về hồ sơ cá nhân'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Về màn hình chính'),
          ),
          const SizedBox(height: 24),

          // Router Hub Card
          GlassCard(
            quality: GlassQuality.minimal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildRouterTile(
                    icon: CupertinoIcons.chart_bar_circle_fill,
                    label: 'Xem bảng hạn mức chi tiêu mới (Kyc Level)',
                    onTap: () => context.push('/profile/kyc-level'),
                  ),
                  const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                  _buildRouterTile(
                    icon: CupertinoIcons.doc_text_fill,
                    label: 'Quản lý thông tin giấy tờ CCCD đã duyệt',
                    onTap: () => context.push('/profile/identity'),
                  ),
                  const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                  _buildRouterTile(
                    icon: CupertinoIcons.lock_shield_fill,
                    label: 'Kích hoạt Chữ ký số Smart OTP PKI',
                    onTap: () => context.push('/profile/digital-signature'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
