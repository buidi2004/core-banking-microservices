import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _isAgreed = true;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Toàn bộ điều khoản',
    'Bảo vệ dữ liệu (NĐ 13)',
    'Sinh trắc học (QĐ 2345)',
    'Hạn mức & Biểu phí',
    'Tra soát & Khiếu nại',
  ];

  void _downloadTermsPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đang tải văn bản Điều khoản & Chính sách bảo mật (PDF, 2.4 MB)...'),
      ),
    );
  }

  void _contactLegalSupport() {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.phone_circle_fill, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text('Phòng Pháp Chế & CSKH', style: AppTypography.titleLarge(color: AppColors.primaryDark)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nếu quý khách có thắc mắc hoặc yêu cầu giải thích về các điều khoản sử dụng, chính sách xử lý dữ liệu cá nhân hay thủ tục tra soát khiếu nại, vui lòng liên hệ:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(CupertinoIcons.phone_fill, color: AppColors.emeraldGreen),
              title: const Text('Hotline Pháp Lý 24/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('1900 6868 (1.000đ/phút) - Nhánh 3'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang gọi Tổng đài Hỗ trợ Pháp lý Sen Hồng 1900 6868...')),
                  );
                },
                child: const Text('Gọi ngay'),
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(CupertinoIcons.mail, color: AppColors.primary),
              title: Text('Hộp Thư Tiếp Nhận Khiếu Nại', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('legal@senhongbank.vn'),
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
        title: const Text('Điều Khoản Dịch Vụ'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Tải văn bản PDF',
            icon: const Icon(CupertinoIcons.arrow_down_doc_fill, color: AppColors.primary),
            onPressed: _downloadTermsPdf,
          ),
          IconButton(
            tooltip: 'Liên hệ pháp lý',
            icon: const Icon(CupertinoIcons.question_circle_fill, color: AppColors.primary),
            onPressed: _contactLegalSupport,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.textPrimaryLight, AppColors.cardDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimaryLight.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.bottomBarCyan.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.bottomBarCyan, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'CƠ SỞ PHÁP LÝ & AN NINH TÀI CHÍNH',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hệ thống Ví điện tử và Dịch vụ Ngân hàng số Sen Hồng tuân thủ nghiêm ngặt theo Giấy phép Hoạt động Cung ứng Dịch vụ Trung gian Thanh toán do Ngân hàng Nhà nước Việt Nam cấp, Nghị định 13/2023/NĐ-CP và Quyết định 2345/QĐ-NHNN.',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: _downloadTermsPdf,
                          icon: const Icon(CupertinoIcons.doc_text, size: 14),
                          label: const Text('Tải văn bản PDF', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bottomBarCyan,
                            foregroundColor: AppColors.textPrimaryLight,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: _contactLegalSupport,
                          icon: const Icon(CupertinoIcons.phone_fill, size: 14),
                          label: const Text('Hỗ trợ pháp lý', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (idx) {
                    final isSelected = _selectedCategoryIndex == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_categories[idx]),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategoryIndex = idx);
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Terms Content Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ĐIỀU KHOẢN & ĐIỀU KIỆN SỬ DỤNG VÍ ĐIỆN TỬ SEN HỒNG', style: AppTypography.titleLarge(color: AppColors.primaryDark).copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Phiên bản 2.4 • Cập nhật: 01/01/2026 • Ban hành kèm Quyết định số 108/2026/QĐ-SHB', style: AppTypography.bodySmall(color: AppColors.textMutedLight)),
                      const Divider(height: 24, color: AppColors.cardBorderLight),

                      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 0) ...[
                        _buildSection(
                          'Chương I: Định nghĩa & Quy định chung',
                          '1.1. "Ví Sen Hồng" là tài khoản thanh toán điện tử mở trên hệ sinh thái ứng dụng của Công ty Cổ phần Tài chính Sen Hồng, được kết nối liên thông với tài khoản thanh toán tại các Ngân hàng thương mại được cấp phép tại Việt Nam.\n'
                          '1.2. "Khách hàng" (Chủ tài khoản) là cá nhân từ đủ 15 tuổi trở lên có đầy đủ năng lực hành vi dân sự hoặc đại diện hợp pháp của tổ chức đăng ký sử dụng dịch vụ.\n'
                          '1.3. Bằng việc bấm nút "Đăng ký" hoặc "Đồng ý", khách hàng thừa nhận đã nghiên cứu kỹ lưỡng, hiểu rõ và cam kết tuân thủ không điều kiện toàn bộ quy định trong bản Thỏa thuận này.',
                        ),
                      ],

                      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1) ...[
                        _buildSection(
                          'Chương II: Bảo vệ Dữ liệu Cá nhân (Nghị định 13/2023/NĐ-CP)',
                          '2.1. Sen Hồng cam kết thu thập và xử lý dữ liệu cá nhân cơ bản (Họ tên, ngày sinh, số CCCD, hình ảnh chân dung, số điện thoại, địa chỉ email) và dữ liệu cá nhân nhạy cảm (dữ liệu sinh trắc học khuôn mặt, thông tin tài chính, lịch sử giao dịch) hoàn toàn đúng theo quy định tại Nghị định số 13/2023/NĐ-CP.\n'
                          '2.2. Mục đích xử lý dữ liệu: Để thực hiện định danh khách hàng điện tử (eKYC), thẩm định phòng chống rửa tiền (AML/CFT), thực thi xác thực sinh trắc học và phát hiện gian lận giao dịch.\n'
                          '2.3. Quyền của chủ thể dữ liệu: Khách hàng có quyền yêu cầu xem, chỉnh sửa, trích xuất hoặc rút lại sự đồng ý đối với dữ liệu cá nhân của mình bằng cách gửi yêu cầu qua email legal@senhongbank.vn hoặc mục "Hồ sơ cá nhân" trên ứng dụng.',
                        ),
                      ],

                      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2) ...[
                        _buildSection(
                          'Chương III: Xác thực Sinh Trắc Học & Quyết Định 2345/QĐ-NHNN',
                          '3.1. Tuân thủ Quyết định 2345/QĐ-NHNN của Thống đốc Ngân hàng Nhà nước, mọi giao dịch chuyển tiền giá trị trên 10.000.000 VNĐ/lần hoặc tổng lũy kế giao dịch trong ngày vượt 20.000.000 VNĐ BẮT BUỘC phải xác thực bằng nhận diện khuôn mặt (Face Match) khớp với dữ liệu sinh trắc học lưu trong chip vi mạch của thẻ CCCD đã thu thập qua eKYC.\n'
                          '3.2. Sen Hồng áp dụng tiêu chuẩn mã hóa khóa công khai PKI (Sen Smart OTP) nhằm chống giả mạo SIM và ngăn chặn mã độc đánh cắp tin nhắn SMS OTP.',
                        ),
                      ],

                      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3) ...[
                        _buildSection(
                          'Chương IV: Hạn Mức Giao Dịch & Biểu Phí Dịch Vụ',
                          '4.1. Hạn mức giao dịch được phân theo cấp độ định danh:\n'
                          '  • Cấp 1 (Chưa định danh eKYC): Tối đa 5.000.000 VNĐ/ngày, không hỗ trợ chuyển liên ngân hàng.\n'
                          '  • Cấp 2 (Đã KYC CCCD gắn chip): Tối đa 100.000.000 VNĐ/ngày.\n'
                          '  • Cấp 3 (Định danh nâng cao): Tối đa 500.000.000 VNĐ/ngày.\n'
                          '4.2. Miễn 100% phí chuyển tiền nội bộ giữa các ví Sen Hồng và thanh toán hóa đơn thiết yếu (Điện, Nước, Internet, Viện phí, Học phí).\n'
                          '4.3. Giao dịch chuyển tiền liên ngân hàng NAPAS 24/7 được thông báo biểu phí công khai, minh bạch trên màn hình trước khi khách hàng ký lệnh chuyển tiền.',
                        ),
                      ],

                      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 4) ...[
                        _buildSection(
                          'Chương V: Quy Trình Xử Lý Khiếu Nại, Tra Soát & SLA',
                          '5.1. Thời hạn tiếp nhận khiếu nại: Khách hàng có quyền gửi tra soát trong vòng 60 ngày kể từ ngày phát sinh giao dịch tranh chấp.\n'
                          '5.2. Cam kết thời gian xử lý (SLA):\n'
                          '  • Lỗi giao dịch nội bộ Sen Hồng: Xử lý và hoàn tiền trong vòng tối đa 24 giờ làm việc.\n'
                          '  • Lỗi chuyển liên ngân hàng NAPAS 24/7: Phối hợp ngân hàng thụ hưởng giải quyết trong 3 đến 5 ngày làm việc.\n'
                          '5.3. Trường hợp hai bên không thể thương lượng hòa giải, tranh chấp sẽ được đưa ra giải quyết tại Trung tâm Trọng tài Quốc tế Việt Nam (VIAC) theo Quy tắc tố tụng trọng tài của Trung tâm này.',
                        ),
                      ],

                      _buildSection(
                        'Chương VI: Trách Nhiệm Bảo Mật Của Khách Hàng',
                        'Khách hàng cam kết giữ bí mật tuyệt đối mật khẩu, mã PIN giao dịch 6 số và mã OTP. Tuyệt đối không chia sẻ mã bảo mật, không nhấp vào đường link lạ giả mạo nhân viên ngân hàng. Sen Hồng không chịu trách nhiệm đối với các tổn thất phát sinh do lỗi bất cẩn làm lộ thông tin bảo mật từ phía người dùng.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Agreement Checkbox
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _isAgreed = v ?? true),
                      ),
                      Expanded(
                        child: Text(
                          'Tôi xác nhận đã đọc, hiểu rõ toàn bộ nội dung và đồng ý chịu ràng buộc bởi các Điều khoản & Chính sách bảo mật trên.',
                          style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Button
              ElevatedButton(
                onPressed: _isAgreed
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.emeraldGreen,
                            content: Text('Xác nhận đồng ý Điều khoản & Điều kiện thành công!'),
                          ),
                        );
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      }
                    : null,
                child: const Text('Tôi Đã Đọc Và Hoàn Toàn Đồng Ý'),
              ),
              const SizedBox(height: 20),

              // Auth Navigation Router Hub Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildRouterTile(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        label: 'Tiếp tục Đăng ký tài khoản ví mới',
                        onTap: () => context.push('/auth/register'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        label: 'Đã có tài khoản? Quay lại Đăng nhập',
                        onTap: () => context.push('/auth/login'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                        label: 'Quên mật khẩu? Khôi phục tài khoản',
                        onTap: () => context.push('/auth/forgot-password'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_shield_fill,
                        label: 'Quên mã PIN giao dịch? Cấp lại mã PIN',
                        onTap: () => context.push('/auth/forgot-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.lock_fill,
                        label: 'Kích hoạt / Thiết lập mã PIN giao dịch mới',
                        onTap: () => context.push('/auth/set-pin'),
                      ),
                      const Divider(height: 1, indent: 40, color: AppColors.cardBorderLight),
                      _buildRouterTile(
                        icon: CupertinoIcons.phone_circle_fill,
                        label: 'Trung tâm trợ giúp & Pháp lý CSKH 24/7',
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 12, height: 1.45)),
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
