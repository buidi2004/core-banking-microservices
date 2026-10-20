import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/support_remote_datasource.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _faqSearchCtrl = TextEditingController();
  String _faqFilter = '';

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    try {
      final remoteFaqs = await SupportRemoteDataSource().getFaq();
      if (remoteFaqs.isNotEmpty && mounted) {
        setState(() {
          _faqs = remoteFaqs.map((f) => {
            'q': (f['question'] ?? '').toString(),
            'a': (f['answer'] ?? '').toString(),
          }).where((f) => f['q']!.isNotEmpty).toList();
        });
      }
    } catch (_) {}
  }

  List<Map<String, String>> _faqs = [
    {
      'q': 'Tôi muốn nâng hạn mức giao dịch chuyển tiền trên 100 triệu?',
      'a': 'Quý khách vui lòng hoàn tất định danh eKYC CCCD gắn chip tại mục "Hồ sơ cá nhân" để nâng lên Cấp 2 (100tr/ngày). Để nâng lên Cấp 3 (500tr/ngày), quý khách đăng ký Chữ ký số PKI / Smart OTP nâng cao.',
    },
    {
      'q': 'Tại sao giao dịch chuyển tiền trên 10 triệu phải quét khuôn mặt?',
      'a': 'Theo Quyết định 2345/QĐ-NHNN của Thống đốc Ngân hàng Nhà nước, từ 01/07/2024 mọi giao dịch chuyển tiền trên 10 triệu đồng/lần hoặc tổng giao dịch trong ngày trên 20 triệu đồng bắt buộc phải khớp sinh trắc học khuôn mặt với dữ liệu chip CCCD (C06).',
    },
    {
      'q': 'Làm sao để lấy lại mã PIN giao dịch khi bị quên hoặc khóa thẻ?',
      'a': 'Quý khách vào "Cài đặt bảo mật" -> Chọn "Quên mã PIN". Hệ thống sẽ kích hoạt luồng đối soát Face Match trực tiếp và gửi OTP xác thực danh tính để tạo mã PIN mới an toàn.',
    },
    {
      'q': 'Giao dịch chuyển tiền thành công nhưng bên kia chưa nhận được?',
      'a': 'Giao dịch Napas 24/7 thông thường đến ngay tức thì sau 3-5 giây. Một số ngân hàng thụ hưởng bảo trì có thể chậm tối đa 30 phút. Bạn có thể bấm nút "Tra soát / Khiếu nại GD" ngay trên Biên lai điện tử để hệ thống kích hoạt điện tra soát tự động.',
    },
    {
      'q': 'Phí duy trì tài khoản và chuyển tiền tại Sen Hồng Bank?',
      'a': 'Sen Hồng Bank áp dụng chính sách Zero Fee trọn đời: Miễn phí mở tài khoản số đẹp, miễn phí duy trì, miễn 100% phí chuyển tiền liên ngân hàng 24/7 và phí thanh toán hóa đơn.',
    },
  ];

  final List<Map<String, String>> _branches = const [
    {
      'name': 'Hội Sở Chính - Sen Hồng Tower',
      'address': 'Tòa nhà Sen Hồng, 54 Liễu Giai, P. Cống Vị, Q. Ba Đình, Hà Nội',
      'time': '08:00 - 17:00 (Thứ 2 - Thứ 6)',
      'phone': '(024) 3888 6688',
    },
    {
      'name': 'Chi Nhánh Sài Gòn - Bến Thành',
      'address': 'Số 128 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh',
      'time': '08:00 - 17:00 (Thứ 2 - Thứ 6)',
      'phone': '(028) 3999 6688',
    },
    {
      'name': 'Cây Nộp Rút Tự Động (CDM 24/7) Hoàn Kiếm',
      'address': '22 Phố Hàng Bài, Q. Hoàn Kiếm, Hà Nội (Phục vụ 24/7)',
      'time': 'Hoạt động 24/7 mọi ngày trong tuần',
      'phone': '1900 6688',
    },
  ];

  void _createTicketModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

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
                  Expanded(
                    child: Text(
                      'Gửi Yêu Cầu Hỗ Trợ Kỹ Thuật',
                      style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark, color: AppColors.textPrimaryLight)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  labelText: 'Vấn đề cần hỗ trợ (ví dụ: Tra soát Napas)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết nội dung sự cố...',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final subject = titleCtrl.text.trim();
                    final msg = contentCtrl.text.trim();
                    if (subject.isEmpty || msg.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền đủ tiêu đề và nội dung')),
                      );
                      return;
                    }
                    try {
                      final res = await SupportRemoteDataSource().createTicket(
                        subject: subject,
                        initialMessage: msg,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        final ticketId = res['id'] ?? 'TK2026';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.emeraldGreen,
                            content: Text('Yêu cầu hỗ trợ đã tạo thành công! Mã Ticket: #$ticketId'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Không thể gửi yêu cầu hỗ trợ: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Gửi yêu cầu tiếp nhận'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _faqSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqFilter.isEmpty
        ? _faqs
        : _faqs.where((f) {
            final q = f['q']!.toLowerCase();
            final a = f['a']!.toLowerCase();
            final filter = _faqFilter.toLowerCase();
            return q.contains(filter) || a.contains(filter);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Trung Tâm Trợ Giúp'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Live Chat',
            icon: const Icon(CupertinoIcons.chat_bubble_2_fill),
            onPressed: () => context.push('/support/live-chat'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            // 24/7 Emergency Assistance Banner (Khẩn Cấp Khóa Thẻ / TK)
            _buildEmergencyHotlineCard(),
            const SizedBox(height: 16),

            // Anti-fraud advisory box
            _buildAntiFraudNotice(),
            const SizedBox(height: 20),

            // Quick Support Box
            GlassCard(
              quality: GlassQuality.minimal,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.headphones, color: AppColors.bottomBarCyan, size: 38),
                    const SizedBox(height: 10),
                    Text('Chăm Sóc Khách Hàng 24/7', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                    const SizedBox(height: 4),
                    Text(
                      'Đội ngũ chuyên viên Sen Hồng luôn túc trực hỗ trợ quý khách mọi lúc, kể cả ngày lễ Tết',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/support/live-chat'),
                            icon: const Icon(CupertinoIcons.bubble_left_bubble_right_fill, size: 18),
                            label: const Text('Chat 24/7'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                            ),
                            onPressed: () => _createTicketModal(context),
                            icon: const Icon(CupertinoIcons.ticket_fill, size: 18),
                            label: const Text('Gửi Ticket'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Active Ticket Tracker
            _buildTicketStatusCard(),
            const SizedBox(height: 24),

            // Branch & ATM Network
            Text('Mạng Lưới Chi Nhánh & ATM Sen Hồng', style: AppTypography.titleMedium(color: AppColors.primaryDark)),
            const SizedBox(height: 12),
            ..._branches.map((b) => _buildBranchCard(b)),
            const SizedBox(height: 24),

            // FAQ with Search
            Text('Câu Hỏi Thường Gặp (FAQ)', style: AppTypography.titleMedium(color: AppColors.primaryDark)),
            const SizedBox(height: 10),
            TextField(
              controller: _faqSearchCtrl,
              onChanged: (val) => setState(() => _faqFilter = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm câu hỏi thắc mắc...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 18, color: AppColors.textSecondaryLight),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
              ),
            ),
            const SizedBox(height: 12),

            ...filteredFaqs.map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  quality: GlassQuality.minimal,
                  child: ExpansionTile(
                    shape: const Border(),
                    title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimaryLight)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(f['a']!, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHotlineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.error, AppColors.errorText],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.35),
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
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.phone_fill, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ĐƯỜNG DÂY NÓNG KHẨN CẤP 24/7', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Text('Hotline: 1900 6688 (Miễn phí)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Khóa thẻ khẩn cấp / Khóa tài khoản tức thì khi mất thiết bị hoặc nghi ngờ bị lộ mã PIN, mật khẩu trong 30 giây.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.errorText,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => context.push('/cards'),
                  icon: const Icon(CupertinoIcons.lock_shield_fill, size: 16),
                  label: const Text('Khóa thẻ tức thì', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang kết nối cuộc gọi khẩn cấp 1900 6688...')),
                    );
                  },
                  icon: const Icon(CupertinoIcons.phone_arrow_up_right, size: 16),
                  label: const Text('Gọi tổng đài', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAntiFraudNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.shield_slash_fill, color: AppColors.warningText, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảnh Báo An Ninh: Phòng Chống Gian Lận Lừa Đảo',
                  style: TextStyle(color: AppColors.warningText, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                SizedBox(height: 3),
                Text(
                  'Ngân hàng Sen Hồng KHÔNG BAO GIỜ yêu cầu khách hàng cung cấp mã OTP, mã PIN, hoặc chuyển tiền vào tài khoản cán bộ công an. Tuyệt đối không bấm vào các đường link lạ.',
                  style: TextStyle(fontSize: 11, color: AppColors.warningText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStatusCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bottomBarCyan.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.ticket, color: AppColors.bottomBarCyan, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Ticket #TK2026-9921', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                      SizedBox(width: 8),
                      Text('ĐANG XỬ LÝ', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text('Tra soát chuyển tiền Napas 24/7 • Cập nhật lúc 09:15', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(Map<String, String> b) {
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
                  Text(b['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                  const Icon(CupertinoIcons.location_fill, color: AppColors.bottomBarCyan, size: 16),
                ],
              ),
              const SizedBox(height: 4),
              Text(b['address']!, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(CupertinoIcons.clock, size: 12, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(b['time']!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

