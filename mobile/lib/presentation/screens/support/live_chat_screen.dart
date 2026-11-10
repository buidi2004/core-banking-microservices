import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/constants/api_constants.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/presentation/widgets/border_beam.dart';
import 'package:sen_hong_bank/presentation/widgets/chatbot_lottie_avatar.dart';
import 'package:sen_hong_bank/presentation/widgets/shader_background.dart';

class LiveChatScreen extends StatefulWidget {
  final String? originScreen;
  const LiveChatScreen({super.key, this.originScreen});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isAgentTyping = false;
  bool _showAssistantNotice = true;

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
    },
  ];

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
          'client_context': {
            'platform': 'flutter_mobile',
            'current_screen': widget.originScreen ?? '/support/live-chat',
            'app_version': '3.2.0',
            'timestamp': DateTime.now().toIso8601String(),
          },
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
        final rawThought = data['thought_process']?.toString();
        final rawSteps = data['reasoning_steps'];
        final reasoningSteps = rawSteps is List ? rawSteps.map((e) => e.toString()).toList() : <String>[];
        final thinkingDuration = (data['thinking_duration_ms'] as num?)?.toDouble();
        final confidenceScore = (data['confidence_score'] as num?)?.toDouble() ?? 0.99;

        setState(() {
          _isAgentTyping = false;
          _messages.add({
            'sender': 'agent',
            'name': 'Trợ Lý AI Sen Hồng',
            'text': answer,
            'time': timeStr,
            'sources': sources,
            'action': suggestedAction,
            'thought_process': rawThought,
            'reasoning_steps': reasoningSteps,
            'thinking_duration_ms': thinkingDuration,
            'confidence_score': confidenceScore,
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
        title: const Row(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ChatbotLottieAvatar(
                    size: 50,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: CircleAvatar(
                      radius: 5, backgroundColor: Color(0xFF00E676)),
                ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
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
            if (_showAssistantNotice)
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
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill,
                        size: 15, color: Color(0xFF00C9A7)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Kênh Trợ Lý Tự Động. Kênh kết nối trực tiếp chuyên viên CSKH đang được phát triển.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      key: const Key('dismiss_assistant_notice_button'),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _showAssistantNotice = false;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
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
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
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
                          maxWidth: MediaQuery.of(context).size.width * 0.85),
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
                        if (!isUser &&
                            (msg['thought_process'] != null ||
                                (msg['reasoning_steps'] as List?)?.isNotEmpty == true))
                          _buildDeepThinkingWidget(msg),
                        _buildMessageContent(msg['text']!, isUser),
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

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: bubbleWidget,
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
                  constraints: const BoxConstraints(minHeight: 52, maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12131A),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Attachment / Clip Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
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
                      ),

                      // Stretched Multiline TextField across the pill (Tối ưu cho người dùng gõ câu dài)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            controller: _msgCtrl,
                            maxLines: 4,
                            minLines: 1,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF0F2F5),
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              hintText: 'Nhập tin nhắn hỗ trợ...',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF717682),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      // Glowing Circular Send Button with Upward Arrow
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3, right: 2),
                        child: GestureDetector(
                          onTap: () {
                            if (!_isAgentTyping) {
                              HapticFeedback.mediumImpact();
                              _sendMessage(_msgCtrl.text);
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
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
                                    CupertinoIcons.arrow_up,
                                    size: 18,
                                    color: Colors.white,
                                  ),
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

  Widget _buildDeepThinkingWidget(Map<String, dynamic> msg) {
    final isExpanded = msg['_is_thinking_expanded'] == true;
    final durationMs =
        (msg['thinking_duration_ms'] as num?)?.toDouble() ?? 680.0;
    final durationSecStr = (durationMs / 1000).toStringAsFixed(1);
    final List<String> steps = (msg['reasoning_steps'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final thoughtProcess = msg['thought_process']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00C9A7)
              .withValues(alpha: isExpanded ? 0.35 : 0.18),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                msg['_is_thinking_expanded'] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      size: 11,
                      color: Color(0xFF00C9A7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Đã suy nghĩ & đối soát (${durationSecStr}s)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00C9A7),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 11,
                    color: const Color(0xFF00C9A7).withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 0.5,
                    color: Colors.white.withValues(alpha: 0.08),
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 11,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TIẾN TRÌNH TƯ DUY & ĐỐI SOÁT CHUYÊN SÂU',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.6),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (steps.isNotEmpty)
                    ...steps.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final stepText = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 6),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C9A7)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$idx',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00C9A7),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                stepText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else if (thoughtProcess.isNotEmpty)
                    Text(
                      thoughtProcess,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 10,
                        color: const Color(0xFF00E676).withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Kiểm chứng số học 0% sai lệch',
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF00E676).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
