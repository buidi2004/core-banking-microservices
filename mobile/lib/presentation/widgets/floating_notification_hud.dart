import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/realtime_notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/datasources/remote/profile_remote_datasource.dart';
import '../../data/datasources/remote/wallet_remote_datasource.dart';
import '../routes/app_router.dart';

class FloatingNotificationData {
  final String id;
  final String title;
  final String body;
  final double amount;
  final String? txId;
  final String? userName;
  final String? accountNumber;
  final String? currentBalance;
  final String? note;
  final String? formattedTime;
  final DateTime timestamp;

  FloatingNotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.amount = 0.0,
    this.txId,
    this.userName,
    this.accountNumber,
    this.currentBalance,
    this.note,
    this.formattedTime,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class InAppNotificationManager {
  static final InAppNotificationManager _instance = InAppNotificationManager._internal();
  factory InAppNotificationManager() => _instance;
  InAppNotificationManager._internal();

  final StreamController<FloatingNotificationData> _controller = StreamController<FloatingNotificationData>.broadcast();
  Stream<FloatingNotificationData> get stream => _controller.stream;

  void show({
    required String title,
    required String body,
    double amount = 0.0,
    String? txId,
    String? userName,
    String? accountNumber,
    String? currentBalance,
    String? note,
    String? formattedTime,
  }) {
    _controller.add(
      FloatingNotificationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        amount: amount,
        txId: txId,
        userName: userName,
        accountNumber: accountNumber,
        currentBalance: currentBalance,
        note: note,
        formattedTime: formattedTime,
      ),
    );
  }
}

class GlobalFloatingNotificationOverlay extends StatefulWidget {
  final Widget child;

  const GlobalFloatingNotificationOverlay({super.key, required this.child});

  @override
  State<GlobalFloatingNotificationOverlay> createState() => _GlobalFloatingNotificationOverlayState();
}

class _GlobalFloatingNotificationOverlayState extends State<GlobalFloatingNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  StreamSubscription? _managerSub;
  StreamSubscription? _realtimeSub;

  FloatingNotificationData? _currentNotification;
  Timer? _dismissTimer;

  String? _cachedUserName;
  String? _cachedAccountNumber;
  String? _cachedBalance;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);

    _prewarmUserData();

    // Lắng nghe từ InAppNotificationManager
    _managerSub = InAppNotificationManager().stream.listen(_displayNotification);

    // Lắng nghe trực tiếp từ Realtime WebSocket STOMP
    _realtimeSub = RealtimeNotificationService().notificationStream.listen((payload) async {
      final title = (payload['title'] ?? payload['data']?['title'] ?? 'Biến động số dư').toString();
      final body = (payload['content'] ?? payload['body'] ?? payload['message'] ?? payload['data']?['content'] ?? payload['data']?['body'] ?? payload['data']?['message'] ?? '').toString();
      var amount = double.tryParse((payload['transactionAmount'] ?? payload['amount'] ?? payload['data']?['amount'] ?? '0').toString()) ?? 0.0;
      final txId = (payload['transactionId'] ?? payload['data']?['transactionId'] ?? payload['id'])?.toString();

      // Bóc tách thông tin cấu trúc từ body
      String? account = RegExp(r'Tài khoản:\s*([^\n]+)').firstMatch(body)?.group(1)?.trim();
      String? balanceStr = RegExp(r'Số dư cuối:\s*([^\n]+)').firstMatch(body)?.group(1)?.trim();
      String? timeStr = RegExp(r'Thời gian:\s*([^\n]+)').firstMatch(body)?.group(1)?.trim();
      String? noteStr = RegExp(r'Nội dung:\s*([^\n]+)').firstMatch(body)?.group(1)?.trim();

      if (amount == 0.0) {
        final psMatch = RegExp(r'PS:\s*([+-]?[\d\.]+)').firstMatch(body);
        if (psMatch != null) {
          amount = double.tryParse(psMatch.group(1)!.replaceAll('.', '')) ?? 0.0;
        }
      }

      // Đọc SĐT thật từ storage nếu body chưa có
      if (account == null || account.isEmpty) {
        try {
          const storage = FlutterSecureStorage();
          account = await storage.read(key: AppConstants.keyPhoneNumber);
        } catch (_) {}
      }

      // Đọc số dư thật từ ví nếu body chưa có
      if (balanceStr == null || balanceStr.isEmpty) {
        try {
          final wallet = await WalletRemoteDataSource().getMyWallet();
          balanceStr = CurrencyFormatter.formatVND(wallet.balance);
        } catch (_) {}
      }

      // Lấy tên người dùng thực tế từ profile
      String? userName = payload['userName']?.toString() ?? payload['fullName']?.toString();
      if (userName == null || userName.isEmpty) {
        try {
          final profile = await ProfileRemoteDataSource().getMe();
          userName = (profile['fullName'] ?? profile['name'])?.toString();
        } catch (_) {}
      }

      if (timeStr == null || timeStr.isEmpty) {
        final now = DateTime.now();
        timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      }

      _displayNotification(
        FloatingNotificationData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          amount: amount,
          txId: txId,
          userName: userName,
          accountNumber: account,
          currentBalance: balanceStr,
          note: noteStr,
          formattedTime: timeStr,
        ),
      );
    });

    _ensureRealtimeConnected();
  }

  Future<void> _ensureRealtimeConnected() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.keyAccessToken);
      if (token == null || token.isEmpty) return;
      var userId = await storage.read(key: AppConstants.keyUserId);
      if (userId == null || userId.isEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final normalized = base64Url.normalize(parts[1]);
          final payloadStr = utf8.decode(base64Url.decode(normalized));
          final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
          userId = (payload['sub'] ?? payload['userId'])?.toString();
          if (userId != null && userId.isNotEmpty) {
            await storage.write(key: AppConstants.keyUserId, value: userId);
          }
        }
      }
      var walletId = await storage.read(key: AppConstants.keyWalletId);
      if (walletId == null || walletId.isEmpty) {
        try {
          final wallet = await WalletRemoteDataSource().getMyWallet();
          walletId = wallet.walletId;
        } catch (_) {}
      }
      RealtimeNotificationService().connect(
        walletId: walletId,
        userId: userId,
        accessToken: token,
      );
    } catch (_) {}
  }

  Future<void> _prewarmUserData() async {
    try {
      const storage = FlutterSecureStorage();
      _cachedAccountNumber = await storage.read(key: AppConstants.keyPhoneNumber);
      final profile = await ProfileRemoteDataSource().getMe();
      _cachedUserName = (profile['fullName'] ?? profile['name'])?.toString();
      final wallet = await WalletRemoteDataSource().getMyWallet();
      _cachedBalance = CurrencyFormatter.formatVND(wallet.balance);
    } catch (_) {}
  }

  Future<void> _displayNotification(FloatingNotificationData rawData) async {
    String? account = rawData.accountNumber;
    String? balanceStr = rawData.currentBalance;
    String? timeStr = rawData.formattedTime;
    String? noteStr = rawData.note;
    String? userName = rawData.userName;
    double amount = rawData.amount;

    // Phân tích từ body nếu chưa có
    account ??= RegExp(r'Tài khoản:\s*([^\n]+)').firstMatch(rawData.body)?.group(1)?.trim();
    balanceStr ??= RegExp(r'Số dư cuối:\s*([^\n]+)').firstMatch(rawData.body)?.group(1)?.trim();
    timeStr ??= RegExp(r'Thời gian:\s*([^\n]+)').firstMatch(rawData.body)?.group(1)?.trim();
    noteStr ??= RegExp(r'Nội dung:\s*([^\n]+)').firstMatch(rawData.body)?.group(1)?.trim();

    if (amount == 0.0) {
      final psMatch = RegExp(r'PS:\s*([+-]?[\d\.]+)').firstMatch(rawData.body);
      if (psMatch != null) {
        amount = double.tryParse(psMatch.group(1)!.replaceAll('.', '')) ?? 0.0;
      }
    }

    // Nạp thông tin thật từ bộ nhớ hoặc API
    account ??= _cachedAccountNumber;
    if (account == null || account.isEmpty) {
      try {
        const storage = FlutterSecureStorage();
        account = await storage.read(key: AppConstants.keyPhoneNumber);
        _cachedAccountNumber = account;
      } catch (_) {}
    }

    userName ??= _cachedUserName;
    if (userName == null || userName.isEmpty) {
      try {
        final profile = await ProfileRemoteDataSource().getMe();
        userName = (profile['fullName'] ?? profile['name'])?.toString();
        _cachedUserName = userName;
      } catch (_) {}
    }

    balanceStr ??= _cachedBalance;
    if (balanceStr == null || balanceStr.isEmpty) {
      try {
        final wallet = await WalletRemoteDataSource().getMyWallet();
        balanceStr = CurrencyFormatter.formatVND(wallet.balance);
        _cachedBalance = balanceStr;
      } catch (_) {}
    }

    if (timeStr == null || timeStr.isEmpty) {
      final now = rawData.timestamp;
      timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    }

    if (noteStr == null || noteStr.isEmpty) {
      noteStr = rawData.body.isNotEmpty ? rawData.body : 'Giao dịch ngân hàng';
    }

    final enriched = FloatingNotificationData(
      id: rawData.id,
      title: rawData.title,
      body: rawData.body,
      amount: amount,
      txId: rawData.txId,
      userName: userName,
      accountNumber: account,
      currentBalance: balanceStr,
      note: noteStr,
      formattedTime: timeStr,
      timestamp: rawData.timestamp,
    );

    _dismissTimer?.cancel();
    if (!mounted) return;
    setState(() => _currentNotification = enriched);
    _animController.forward(from: 0.0);

    // Thời gian hiển thị 6.5s để người dùng kịp đọc đầy đủ các thông tin
    _dismissTimer = Timer(const Duration(milliseconds: 6500), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) setState(() => _currentNotification = null);
        });
      }
    });
  }

  void _dismissNow() {
    _dismissTimer?.cancel();
    if (mounted) {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _currentNotification = null);
      });
    }
  }

  void _handleNotificationTap(FloatingNotificationData notif) {
    _dismissTimer?.cancel();
    if (mounted) setState(() => _currentNotification = null);

    try {
      if (notif.txId != null && notif.txId!.isNotEmpty) {
        final uri = Uri(
          path: '/history/detail',
          queryParameters: {
            'id': notif.txId!,
            'title': notif.title,
            'amount': notif.amount.toString(),
            'note': (notif.note != null && notif.note!.isNotEmpty) ? notif.note! : notif.body,
          },
        );
        appRouter.push(uri.toString());
      } else {
        appRouter.push('/notifications');
      }
    } catch (_) {
      try {
        appRouter.push('/notifications');
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _managerSub?.cancel();
    _realtimeSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = _currentNotification;

    final bool isDeduction = notif != null && (
      notif.body.contains('PS: -') ||
      notif.body.contains('PS:-') ||
      notif.amount < 0 ||
      (notif.title.toLowerCase().contains('chuyển tiền') && !notif.title.toLowerCase().contains('nhận')) ||
      notif.title.toLowerCase().contains('rút tiền') ||
      notif.title.toLowerCase().contains('thanh toán')
    );

    final bool isAddition = notif != null && !isDeduction && (
      notif.body.contains('PS: +') ||
      notif.body.contains('PS:+') ||
      notif.amount > 0 ||
      notif.title.toLowerCase().contains('nạp tiền') ||
      notif.title.toLowerCase().contains('nhận tiền')
    );

    final bool hasAmount = notif != null && (notif.amount != 0 || notif.body.contains('PS:'));

    final Color accentColor = isAddition
        ? AppColors.emeraldGreen
        : isDeduction
            ? AppColors.error
            : AppColors.primary;

    final Color badgeBg = isAddition
        ? AppColors.successBg
        : isDeduction
            ? AppColors.errorBg
            : AppColors.infoBg;

    final Color badgeBorder = isAddition
        ? AppColors.successBorder
        : isDeduction
            ? AppColors.errorBorder
            : AppColors.infoBorder;

    final Color badgeText = isAddition
        ? AppColors.successText
        : isDeduction
            ? AppColors.errorText
            : AppColors.infoText;

    return Stack(
      children: [
        widget.child,
        if (notif != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Material(
                      type: MaterialType.transparency,
                      child: DefaultTextStyle(
                        style: GoogleFonts.plusJakartaSans(
                          decoration: TextDecoration.none,
                          color: AppColors.textPrimaryLight,
                        ),
                        child: Dismissible(
                          key: ValueKey(notif.id),
                          direction: DismissDirection.up,
                          onDismissed: (_) {
                            _dismissTimer?.cancel();
                            setState(() => _currentNotification = null);
                          },
                          child: GestureDetector(
                            onTap: () => _handleNotificationTap(notif),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.97),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.35),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 24,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Top Bar: Badge + Date/Time + Close "X"
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius: BorderRadius.circular(7),
                                              border: Border.all(
                                                color: badgeBorder,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isAddition
                                                      ? CupertinoIcons.arrow_down_left_circle_fill
                                                      : isDeduction
                                                          ? CupertinoIcons.arrow_up_right_circle_fill
                                                          : CupertinoIcons.bell_fill,
                                                  size: 13,
                                                  color: badgeText,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  hasAmount
                                                      ? (isAddition ? 'TIỀN VÀO (+)' : isDeduction ? 'TIỀN RA (-)' : 'BIẾN ĐỘNG SỐ DƯ')
                                                      : 'SENBANK THÔNG BÁO',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: badgeText,
                                                    letterSpacing: 0.5,
                                                    decoration: TextDecoration.none,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                notif.formattedTime ??
                                                    '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')} ${notif.timestamp.day.toString().padLeft(2, '0')}/${notif.timestamp.month.toString().padLeft(2, '0')}/${notif.timestamp.year}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textSecondaryLight,
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: _dismissNow,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.dividerLight,
                                                  ),
                                                  child: const Icon(
                                                    CupertinoIcons.xmark,
                                                    size: 13,
                                                    color: AppColors.textSecondaryLight,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // 2. Title & Amount
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.title,
                                              style: GoogleFonts.plusJakartaSans(
                                                color: AppColors.textPrimaryLight,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.5,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                          if (hasAmount) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '${isAddition ? '+' : isDeduction ? '-' : ''}${CurrencyFormatter.formatVND(notif.amount.abs())}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: accentColor,
                                                letterSpacing: -0.3,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 9),

                                      // 3. Detailed Information Box (Tên chủ TK, Số tài khoản, Nội dung)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(13),
                                          border: Border.all(color: AppColors.borderLight),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (notif.userName != null && notif.userName!.isNotEmpty) ...[
                                              Row(
                                                children: [
                                                  const Icon(CupertinoIcons.person_fill, size: 12, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Chủ TK: ',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      color: AppColors.textSecondaryLight,
                                                      fontWeight: FontWeight.w500,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      notif.userName!.toUpperCase(),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        color: AppColors.textPrimaryLight,
                                                        fontWeight: FontWeight.w700,
                                                        decoration: TextDecoration.none,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4.5),
                                            ],
                                            if (notif.accountNumber != null && notif.accountNumber!.isNotEmpty) ...[
                                              Row(
                                                children: [
                                                  const Icon(CupertinoIcons.creditcard_fill, size: 12, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Số tài khoản: ',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      color: AppColors.textSecondaryLight,
                                                      fontWeight: FontWeight.w500,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '${notif.accountNumber} (Ví Sen Hồng)',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.5,
                                                        color: AppColors.textPrimaryLight,
                                                        fontWeight: FontWeight.w600,
                                                        decoration: TextDecoration.none,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4.5),
                                            ],
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.only(top: 1.5),
                                                  child: Icon(CupertinoIcons.chat_bubble_text_fill, size: 12, color: AppColors.primary),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Nội dung: ',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11.5,
                                                    color: AppColors.textSecondaryLight,
                                                    fontWeight: FontWeight.w500,
                                                    decoration: TextDecoration.none,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    (notif.note != null && notif.note!.isNotEmpty) ? notif.note! : notif.body,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      color: AppColors.textPrimaryLight,
                                                      height: 1.3,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 4. Highlighted Current Balance
                                      if (notif.currentBalance != null && notif.currentBalance!.isNotEmpty) ...[
                                        const SizedBox(height: 8.5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: AppColors.infoTealBg,
                                            borderRadius: BorderRadius.circular(11),
                                            border: Border.all(color: AppColors.infoTealBorder),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(CupertinoIcons.money_dollar_circle_fill, size: 15, color: AppColors.infoTealText),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Số dư hiện tại:',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.5,
                                                      color: AppColors.infoTealText,
                                                      fontWeight: FontWeight.w600,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                notif.currentBalance!.contains('VND') || notif.currentBalance!.contains('đ')
                                                    ? notif.currentBalance!
                                                    : '${notif.currentBalance} VND',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.infoTealText,
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 8.5),

                                      // 5. Footer
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (notif.txId != null && notif.txId!.isNotEmpty)
                                            Text(
                                              'Mã GD: ${notif.txId!.length > 16 ? notif.txId!.substring(0, 16) : notif.txId}...',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: AppColors.textMutedLight,
                                                decoration: TextDecoration.none,
                                              ),
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          Row(
                                            children: [
                                              Text(
                                                'Chạm để xem chi tiết',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              const Icon(CupertinoIcons.chevron_right, size: 10, color: AppColors.primary),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
