import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/presentation/widgets/border_beam.dart';
import 'package:sen_hong_bank/presentation/widgets/shader_background.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isAgentTyping = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'agent',
      'name': 'Trợ Lý AI Sen Hồng',
      'text':
          'Xin chào quý khách! Em là Trợ lý AI Tài chính Thông minh 24/7 của Ngân hàng Số Sen Hồng. Em có thể giải đáp ngay mọi thông tin về biểu phí, lãi suất tiết kiệm, hạn mức giao dịch hay quản lý thẻ Visa ạ!',
      'time': 'Vừa xong',
      'sources': <String>['Cẩm nang Sen Hồng'],
    },
  ];

  static const Map<String, String> _docTitleMap = {
    '01_huong_dan_chuyen_tien': 'Hướng dẫn chuyển tiền',
    '02_nap_va_rut_tien': 'Nạp & Rút tiền',
    '03_thanh_toan_hoa_don_tien_ich': 'Thanh toán hóa đơn',
    '04_vay_tieu_dung_quick_loan': 'Vay tiêu dùng Quick Loan',
    '05_tiet_kiem_online_core_savings': 'Tiết kiệm Online',
    '06_quan_ly_the_va_tai_khoan': 'Quản lý thẻ & Tài khoản',
    '07_quy_dinh_sinh_trac_hoc_qd2345': 'Quy định QĐ 2345/QĐ-NHNN',
    '08_tien_ich_xo_so_giai_tri': 'Vé số & Giải trí',
    '09_bieu_phi_va_han_muc_chi_tiet': 'Biểu phí & Hạn mức',
    '10_an_toan_bao_mat_va_canh_bao_lua_dao': 'An toàn & Bảo mật',
    '11_ho_tro_khieu_nai_va_cskh': 'Hỗ trợ CSKH',
    '12_tong_hop_cau_hoi_thuong_gap_faq': 'Câu hỏi thường gặp',
    '13_ma_vietqr_va_chia_tien_split_bill': 'VietQR & Chia tiền nhóm',
    '14_dat_lich_chuyen_tien_dinh_ky': 'Đặt lịch chuyển tiền',
    '15_danh_ba_thu_huong_va_danh_sach_ngan_hang_napas': 'Danh bạ Napas',
    '16_tai_khoan_so_dep_va_chuyen_tien_quoc_te': 'Số đẹp & Kiều hối',
    '17_chuong_trinh_gioi_thieu_va_voucher_uu_dai': 'Ưu đãi & Voucher',
    '18_quan_ly_thiet_bi_va_bao_mat_phien': 'Bảo mật thiết bị',
    '19_dieu_khoan_phap_ly_va_giay_phep_nhnn': 'Điều khoản & Pháp lý',
    '20_cam_nang_toan_dien_cac_man_hinh_va_tinh_nang_app': 'Cẩm nang tính năng',
    '21_kien_truc_he_thong_microservices_va_backend': 'Kiến trúc hệ thống & Backend',
    '22_cam_nang_chuyen_sau_tinh_nang_mobile_va_tien_ich_so': 'Cẩm nang tính năng Mobile',
    '23_tong_hop_toan_bo_tinh_nang_mobile_va_backend_huong_dan_khach_hang': 'Cẩm nang toàn diện Mobile & Backend',
    '24_kho_voucher_uu_dai_doi_tac_va_chuong_trinh_khuyen_mai': 'Kho Voucher & Ưu Đãi Đối Tác',
    '25_ty_gia_ngoai_te_va_kieu_hoi_quoc_te': 'Tỷ giá & Kiều hối quốc tế',
    '26_mang_luoi_chi_nhanh_va_diem_giao_dich': 'Mạng lưới Chi nhánh & ATM',
    '27_huong_dan_biet_danh_tai_khoan_alias_va_vietqr_pro': 'Biệt danh Alias & VietQR Pro',
    '28_giai_dap_tinh_huong_nghiep_vu_kho_va_tu_van_chuyen_sau': 'Tư vấn nghiệp vụ & Tình huống chuyên sâu',
    'bieu_phi_dich_vu': 'Biểu phí dịch vụ',
    'huong_dan_the_visa': 'Hướng dẫn thẻ Visa',
    'lai_suat_tiet_kiem': 'Lãi suất tiết kiệm',
    'quy_dinh_qd2345': 'Quy định QĐ 2345',
    'tai_khoan_va_ekyc': 'Tài khoản & eKYC',
  };

  static String _formatSourceTitle(String raw) {
    var s = raw.trim();
    if (s.toLowerCase().endsWith('.md')) {
      s = s.substring(0, s.length - 3);
    }
    if (_docTitleMap.containsKey(s)) {
      return _docTitleMap[s]!;
    }
    final stripped = s.replaceAll(RegExp(r'^\d+_'), '');
    if (_docTitleMap.containsKey(stripped)) {
      return _docTitleMap[stripped]!;
    }
    if (s.contains(' ') && !s.contains('_')) {
      return s;
    }
    final clean = stripped.replaceAll('_', ' ');
    return clean
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ')
        .trim();
  }

  List<String> _quickReplies = [
    'Tổng quan tài chính của tôi',
    'Kiểm tra số dư ví',
    'Thẻ Visa của tôi',
    'Sổ tiết kiệm của tôi',
    'Khoản vay của tôi',
    'Thông tin eKYC của tôi',
    'Biểu phí chuyển tiền Napas 247',
    'Lãi suất tiết kiệm online',
    'Quy định sinh trắc học QĐ 2345',
    'Cách mở thẻ Visa miễn phí',
  ];

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isAgentTyping) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'sender': 'user',
        'name': 'Tôi',
        'text': cleanText,
        'time': timeStr,
      });
      _isAgentTyping = true;
      _msgCtrl.clear();
    });

    _scrollToBottom();

    try {
      final dio = DioClient.instance.dio;
      final pastMessages = _messages.take(_messages.length - 1).toList();
      final recentHistory = pastMessages.length > 6
          ? pastMessages.sublist(pastMessages.length - 6)
          : pastMessages;
      final historyPayload = recentHistory.map((m) => {
        'role': m['sender'] == 'user' ? 'user' : 'assistant',
        'content': m['text'] ?? '',
      }).toList();

      final response = await dio.post(
        ApiConstants.chat,
        data: {
          'question': cleanText,
          'history': historyPayload,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final answer = data['answer']?.toString() ?? 'Dạ em đã nhận được yêu cầu của quý khách.';
        final rawSources = data['sources'];
        final sources = rawSources is List ? rawSources.map((e) => e.toString()).toList() : <String>[];
        final rawQuick = data['quick_replies'];
        final newQuickReplies = rawQuick is List ? rawQuick.map((e) => e.toString()).toList() : <String>[];
        final rawAction = data['suggested_action'];
        final Map<String, dynamic>? suggestedAction = rawAction is Map ? Map<String, dynamic>.from(rawAction) : null;

        setState(() {
          _isAgentTyping = false;
          _messages.add({
            'sender': 'agent',
            'name': 'Trợ Lý AI Sen Hồng',
            'text': answer,
            'time': timeStr,
            'sources': sources,
            'action': suggestedAction,
          });
          if (newQuickReplies.isNotEmpty) {
            _quickReplies = newQuickReplies;
          }
        });
      } else {
        _handleChatFallback(timeStr);
      }
    } catch (e) {
      if (!mounted) return;
      _handleChatFallback(timeStr);
    }

    _scrollToBottom();
  }

  void _handleChatFallback(String timeStr) {
    setState(() {
      _isAgentTyping = false;
      _messages.add({
        'sender': 'agent',
        'name': 'Trợ Lý AI Sen Hồng',
        'text':
            'Dạ hệ thống AI đang cập nhật dữ liệu trực tuyến. Quý khách có thể xem thông tin biểu phí và lãi suất trong Trung tâm Trợ giúp, hoặc liên hệ Tổng đài CSKH Sen Hồng 1900-SENHONG (1900 736 466) để được hỗ trợ tức thì 24/7 ạ!',
        'time': timeStr,
        'sources': <String>['Trung tâm Trợ giúp Sen Hồng'],
        'action': <String, dynamic>{
          'type': 'NAVIGATE',
          'label': 'Trung tâm trợ giúp',
          'route': '/support/help-center',
        },
      });
    });
  }

  void _showHotlineDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14151E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded,
                        color: Color(0xFF00C9A7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng Đài CSKH 24/7',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Ngân hàng Số Sen Hồng • Phục vụ toàn quốc',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08), width: 0.8),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hotline CSKH (Miễn cước):',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFFCBD5E1))),
                        Text('1900 736 466',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00C9A7))),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Khóa thẻ / Sự cố khẩn cấp:',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFFCBD5E1))),
                        Text('(028) 3822 6688',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(
                        const ClipboardData(text: '1900736466'));
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.phone_in_talk,
                                color: Color(0xFF00E676), size: 18),
                            SizedBox(width: 8),
                            Text('Đã sao chép Hotline: 1900 736 466'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1E2028),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Sao chép Hotline 1900 736 466',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Color(0xFF00C9A7), size: 22),
            SizedBox(width: 8),
            Text('Làm mới cuộc trò chuyện',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        content: const Text(
          'Quý khách có chắc chắn muốn làm mới và bắt đầu một phiên hỗ trợ mới cùng Trợ lý AI Sen Hồng không?',
          style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _messages.add({
                  'sender': 'agent',
                  'name': 'Trợ Lý AI Sen Hồng',
                  'text':
                      'Xin chào quý khách! Em là Trợ lý AI Tài chính Thông minh 24/7 của Ngân hàng Số Sen Hồng. Em có thể giải đáp ngay mọi thông tin về biểu phí, lãi suất tiết kiệm, hạn mức giao dịch hay quản lý thẻ Visa ạ!',
                  'time': 'Vừa xong',
                  'sources': ['Cẩm nang Sen Hồng'],
                });
                _quickReplies = [
                  'Tổng quan tài chính của tôi',
                  'Kiểm tra số dư ví',
                  'Thẻ Visa của tôi',
                  'Sổ tiết kiệm của tôi',
                  'Khoản vay của tôi',
                  'Thông tin eKYC của tôi',
                  'Biểu phí chuyển tiền Napas 247',
                  'Lãi suất tiết kiệm online',
                  'Quy định sinh trắc học QĐ 2345',
                  'Cách mở thẻ Visa miễn phí',
                ];
              });
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF000000),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2028),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Image.asset(
                        'assets/icons/ai_assistant_ghost.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                      radius: 5, backgroundColor: Color(0xFF00E676)),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CSKH Sen Hồng',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(
                    'Trực tuyến 24/7 • Phản hồi tức thì',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Gọi Tổng đài CSKH 1900-SENHONG',
            icon: const Icon(Icons.phone_in_talk_outlined,
                size: 20, color: Color(0xFF00C9A7)),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHotlineDialog(context);
            },
          ),
          IconButton(
            tooltip: 'Làm mới cuộc trò chuyện',
            icon: const Icon(Icons.refresh_rounded,
                size: 20, color: Color(0xFF94A3B8)),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showResetConfirmDialog(context);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ShaderBackground()),
          SafeArea(
            child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0E),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info_circle_fill,
                      size: 15, color: Color(0xFF00C9A7)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kênh Trợ Lý Tự Động. Kênh kết nối trực tiếp chuyên viên CSKH đang được phát triển.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isAgentTyping ? 1 : 0),
                itemBuilder: (context, idx) {
                  if (idx == _messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8, top: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2028),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00C9A7).withValues(alpha: 0.35),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Image.asset(
                                  'assets/icons/ai_assistant_ghost.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181A22),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Trợ lý AI đang suy nghĩ...',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                      fontStyle: FontStyle.italic),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF00C9A7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final msg = _messages[idx];
                  final isUser = msg['sender'] == 'user';
                  final messageText = msg['text']?.toString() ?? '';

                  final bubbleWidget = GestureDetector(
                    onLongPress: () {
                      if (messageText.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: messageText));
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Color(0xFF00E676), size: 18),
                                SizedBox(width: 8),
                                Text('Đã sao chép nội dung tin nhắn'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E2028),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.76),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser ? AppColors.primaryGradient : null,
                      color: isUser ? null : const Color(0xFF14151E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 8),
                        bottomRight: Radius.circular(isUser ? 8 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              msg['name']!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF00C9A7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        _buildMessageContent(msg['text']!, isUser),
                        if (!isUser &&
                             msg['sources'] != null &&
                             (msg['sources'] as List).isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final rawList = msg['sources'] as List;
                              final cleanList = rawList
                                  .map((e) => e.toString().trim())
                                  .where((s) {
                                    final lower = s.toLowerCase();
                                    return !lower.contains('internal_api') &&
                                        !lower.contains('service') &&
                                        !lower.contains('jev') &&
                                        !lower.contains('typesafe') &&
                                        !lower.contains('chao_mung') &&
                                        !lower.contains('hotline') &&
                                        s.isNotEmpty;
                                  })
                                  .map((s) => _formatSourceTitle(s))
                                  .where((s) => s.isNotEmpty && !s.toLowerCase().endsWith('.md'))
                                  .toSet()
                                  .toList();

                              if (cleanList.isEmpty) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: cleanList.map<Widget>((title) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00C9A7).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF00C9A7).withValues(alpha: 0.35),
                                          width: 0.6,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(CupertinoIcons.bookmark_fill,
                                              size: 9.5, color: Color(0xFF00C9A7)),
                                          const SizedBox(width: 4),
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF00C9A7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                        if (!isUser && msg['action'] != null) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final route = msg['action']['route']?.toString();
                              if (route != null && route.isNotEmpty) {
                                try {
                                  context.push(route);
                                } catch (_) {
                                  try {
                                    context.push('/more');
                                  } catch (_) {}
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF00C9A7).withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.arrow_up_right_circle_fill,
                                    size: 15,
                                    color: Color(0xFF00C9A7),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      msg['action']['label']?.toString() ?? 'Xem chi tiết',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF00C9A7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          msg['time']!,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.82)
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                  if (isUser) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: bubbleWidget,
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 8, top: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2028),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00C9A7).withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Image.asset(
                                'assets/icons/ai_assistant_ghost.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Flexible(child: bubbleWidget),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Quick suggestion chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: _quickReplies.map((qr) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF12141C),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      avatar: const Icon(
                        CupertinoIcons.sparkles,
                        size: 13,
                        color: Color(0xFF00C9A7),
                      ),
                      label: Text(
                        qr,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _sendMessage(qr);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // AI Futuristic Pill Message Composer with BorderBeam
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: BorderBeam(
                borderRadius: 28,
                strokeWidth: 1.5,
                duration: const Duration(seconds: 4),
                beamLength: 0.28,
                glowSigma: 8,
                glowOpacity: 0.60,
                colors: const [
                  Color(0xFF7C5CFF), // Futuristic Violet
                  Color(0xFF3BB2FF), // Cyber Cyan
                  Color(0xFFFF6BCB), // Neon Rose
                  Color(0xFF00C9A7), // Sen Hồng Emerald
                ],
                baseBorderColor: const Color(0x18FFFFFF),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12131A),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Attachment / Clip Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã chọn tệp đính kèm hóa đơn/biên lai'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              CupertinoIcons.paperclip,
                              size: 18,
                              color: Color(0xFF9EA3AE),
                            ),
                          ),
                        ),
                      ),

                      // Stretched TextField across the pill
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF0F2F5),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                            hintText: 'Nhập tin nhắn hỗ trợ...',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF717682),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),

                      // Glowing Circular Send Button with Upward Arrow
                      GestureDetector(
                        onTap: () {
                          if (!_isAgentTyping) {
                            HapticFeedback.mediumImpact();
                            _sendMessage(_msgCtrl.text);
                          }
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF00C9A7),
                                Color(0xFF0083B0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C9A7).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isAgentTyping
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }

  Widget _buildMessageContent(String text, bool isUser) {
    final baseColor = isUser ? Colors.white : const Color(0xFFF1F5F9);
    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
        continue;
      }

      final inlineSpans = _parseInlineMarkdown(line, baseColor, isUser);
      spans.addAll(inlineSpans);

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        color: baseColor,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  List<InlineSpan> _parseInlineMarkdown(String line, Color baseColor, bool isUser) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: line.substring(lastMatchEnd, match.start),
          style: TextStyle(color: baseColor),
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        final inner = matchedText.substring(2, matchedText.length - 2);
        final isFinancialHighlight = inner.contains('VNĐ') ||
            inner.contains('đ') ||
            inner.contains('%') ||
            inner.contains('triệu') ||
            inner.contains('tỷ') ||
            inner.contains('đồng') ||
            inner.toLowerCase().contains('miễn phí') ||
            inner.toLowerCase().contains('bước') ||
            inner.toLowerCase().contains('mã') ||
            inner.toUpperCase().contains('SEN') ||
            inner.toUpperCase().contains('VOUCHER') ||
            RegExp(r'\d').hasMatch(inner);
        spans.add(TextSpan(
          text: inner,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isFinancialHighlight
                    ? const Color(0xFF00C9A7)
                    : const Color(0xFFFFFFFF)),
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              inner,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isUser ? Colors.white : const Color(0xFF38BDF8),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: TextStyle(
            color: baseColor.withValues(alpha: 0.9),
            fontStyle: FontStyle.italic,
          ),
        ));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastMatchEnd),
        style: TextStyle(color: baseColor),
      ));
    }

    return spans;
  }
}
