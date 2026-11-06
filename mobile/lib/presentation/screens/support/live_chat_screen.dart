import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

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
    'Biểu phí chuyển tiền Napas 247',
    'Lãi suất tiết kiệm online',
    'Quy định sinh trắc học QĐ 2345',
    'Cách mở thẻ Visa miễn phí',
  ];

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

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
      final historyPayload = _messages.take(_messages.length - 1).map((m) => {
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
            'Dạ hệ thống AI đang cập nhật dữ liệu trực tuyến. Quý khách có thể xem thông tin biểu phí và lãi suất trong mục Cài đặt, hoặc liên hệ Tổng đài CSKH Sen Hồng 1900-SENHONG (1900 736 466) để được hỗ trợ tức thì 24/7 ạ!',
        'time': timeStr,
        'sources': <String>[],
      });
    });
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.35),
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
                      radius: 5, backgroundColor: AppColors.emeraldGreen),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Trực tuyến 24/7 • Phản hồi tức thì',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.successTextLight),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.08),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info_circle_fill,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kênh Trợ Lý Tự Động. Kênh kết nối trực tiếp chuyên viên CSKH đang được phát triển.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondaryLight),
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
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.25),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
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
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
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
                                      color: AppColors.textSecondaryLight,
                                      fontStyle: FontStyle.italic),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryDark),
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

                  final bubbleWidget = Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.74),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser ? AppColors.primaryGradient : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 8),
                        bottomRight: Radius.circular(isUser ? 8 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isUser ? 0.15 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              msg['name']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryDark,
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
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDark.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.primaryDark.withOpacity(0.18),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(CupertinoIcons.bookmark_fill,
                                              size: 9.5, color: AppColors.primaryDark),
                                          const SizedBox(width: 3.5),
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryDark,
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
                                context.push(route);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryDark.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.arrow_up_right_circle_fill,
                                    size: 15,
                                    color: AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      msg['action']['label']?.toString() ?? 'Xem chi tiết',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          msg['time']!,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white.withOpacity(0.82)
                                : AppColors.textSecondaryLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
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
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
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
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderLight),
                      label: Text(qr,
                          style: const TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      onPressed: () => _sendMessage(qr),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Message Composer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(top: BorderSide(color: AppColors.borderLight)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.paperclip,
                        color: AppColors.primaryText),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Đã chọn tệp đính kèm hóa đơn/biên lai'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: AppColors.textPrimaryLight),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn hỗ trợ...',
                        hintStyle:
                            const TextStyle(color: AppColors.textMutedLight),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight)),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.bottomBarGlow.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.paperplane_fill,
                          color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_msgCtrl.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String text, bool isUser) {
    final baseColor = isUser ? Colors.white : AppColors.textPrimaryLight;
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
        spans.add(TextSpan(
          text: inner,
          style: TextStyle(
            color: isUser ? Colors.white : (inner.contains('VNĐ') ? AppColors.primaryDark : AppColors.textPrimaryLight),
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
              color: isUser ? Colors.white.withOpacity(0.2) : AppColors.primaryDark.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              inner,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isUser ? Colors.white : AppColors.primaryDark,
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
            color: baseColor.withOpacity(0.9),
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
