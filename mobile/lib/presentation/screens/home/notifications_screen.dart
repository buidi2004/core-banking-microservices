import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/network/realtime_notification_service.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/notification_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/floating_notification_hud.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0; // 0: Biến động số dư, 1: Khuyến mãi, 2: Hệ thống
  bool _isLoading = true;
  bool _isLoggedIn = true;
  bool _isMarkingAllRead = false;

  // Dữ liệu thực tế 100% từ Backend — KHÔNG DÙNG MOCK DATA
  final List<Map<String, dynamic>> _balanceNotifs = [];
  final List<Map<String, dynamic>> _promoNotifs = [];
  final List<Map<String, dynamic>> _systemNotifs = [];

  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _initRealtime();
  }

  void _initRealtime() async {
    final prefs = await SharedPreferences.getInstance();
    final local = AuthLocalDataSourceImpl(prefs: prefs);
    final token = await local.getAccessToken();
    const secureStorage = FlutterSecureStorage();
    final userId = await secureStorage.read(key: AppConstants.keyUserId);
    var walletId = await secureStorage.read(key: AppConstants.keyWalletId);
    if (walletId == null || walletId.isEmpty) {
      try {
        final wallet = await WalletRemoteDataSource().getMyWallet();
        walletId = wallet.walletId;
      } catch (_) {}
    }

    if (token != null) {
      RealtimeNotificationService().connect(
        walletId: walletId,
        userId: userId,
        accessToken: token,
      );
      _notifSub = RealtimeNotificationService().notificationStream.listen((data) {
        if (!mounted) return;
        final title = (data['title'] ?? data['data']?['title'] ?? 'Biến động số dư').toString();
        final body = (data['content'] ?? data['body'] ?? data['message'] ?? data['data']?['content'] ?? data['data']?['body'] ?? data['data']?['message'] ?? '').toString();
        final amount = double.tryParse((data['transactionAmount'] ?? data['amount'] ?? data['data']?['amount'] ?? '0').toString()) ?? 0.0;
        final txId = (data['transactionId'] ?? data['data']?['transactionId'] ?? data['id'])?.toString();

        setState(() {
          _balanceNotifs.insert(0, {
            'id': txId ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'title': title,
            'body': body,
            'content': body,
            'message': body,
            'time': 'Vừa xong',
            'isRead': false,
            'read': false,
            'txId': txId ?? '',
            'amount': amount,
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = await AuthLocalDataSourceImpl(prefs: prefs).getAccessToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    _isLoggedIn = true;
    try {
      final api = NotificationRemoteDataSource();
      final results = await Future.wait([
        api.getNotifications('BALANCE'),
        api.getNotifications('PROMOTION'),
        api.getNotifications('SYSTEM'),
      ]);

      if (!mounted) return;
      setState(() {
        _balanceNotifs
          ..clear()
          ..addAll(results[0]);
        _promoNotifs
          ..clear()
          ..addAll(results[1]);
        _systemNotifs
          ..clear()
          ..addAll(results[2]);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppAlerts.showError(
        context,
        extractErrorMessage(error),
        title: 'Lỗi tải thông báo',
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead) return;
    HapticFeedback.mediumImpact();
    setState(() => _isMarkingAllRead = true);
    try {
      await NotificationRemoteDataSource().markAllRead();
      if (!mounted) return;
      setState(() {
        for (var n in _balanceNotifs) {
          n['isRead'] = true;
          n['read'] = true;
        }
        for (var n in _promoNotifs) {
          n['isRead'] = true;
          n['read'] = true;
        }
        for (var n in _systemNotifs) {
          n['isRead'] = true;
          n['read'] = true;
        }
      });
      AppAlerts.showSuccess(
        context,
        'Đã đánh dấu đọc tất cả thông báo',
        title: 'Thông báo',
      );
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Thao tác không thành công',
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  String _formatNotifTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _triggerRealFloatingNotification() async {
    if (_balanceNotifs.isNotEmpty) {
      final latest = _balanceNotifs.first;
      final body = (latest['body'] ?? '').toString();
      final title = (latest['title'] ?? 'Biến động số dư').toString();
      final amount = (latest['amount'] is num)
          ? (latest['amount'] as num).toDouble()
          : (double.tryParse(latest['amount']?.toString() ?? '0') ?? 0.0);
      final txId = latest['txId']?.toString() ?? latest['id']?.toString();
      final time = _formatNotifTime(latest['time']?.toString());

      InAppNotificationManager().show(
        title: title,
        body: body,
        amount: amount,
        txId: txId,
        formattedTime: time.isNotEmpty ? time : null,
      );
    } else {
      // Khi danh sách rỗng, lấy thông tin 100% thực tế từ Profile và Ví Backend
      try {
        final profile = await ProfileRemoteDataSource().getMe();
        final realName = (profile['fullName'] ?? profile['name'] ?? '').toString();
        const storage = FlutterSecureStorage();
        final realPhone = await storage.read(key: AppConstants.keyPhoneNumber) ?? '';
        final wallet = await WalletRemoteDataSource().getMyWallet();
        final balanceFormatted = CurrencyFormatter.formatVND(wallet.balance);
        final now = DateTime.now();
        final timeFormatted = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

        InAppNotificationManager().show(
          title: 'Thông báo tài khoản',
          body: 'Tài khoản: $realPhone\nSố dư hiện tại: $balanceFormatted\nThời gian: $timeFormatted\nNội dung: Trạng thái tài khoản hoạt động bình thường',
          amount: 0.0,
          userName: realName.isNotEmpty ? realName : null,
          accountNumber: realPhone.isNotEmpty ? realPhone : null,
          currentBalance: balanceFormatted,
          note: 'Trạng thái tài khoản hoạt động bình thường',
          formattedTime: timeFormatted,
          txId: 'SYS_${now.millisecondsSinceEpoch}',
        );
      } catch (e) {
        final now = DateTime.now();
        final timeFormatted = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
        InAppNotificationManager().show(
          title: 'Thông báo hệ thống',
          body: 'Hệ thống SenBank hoạt động ổn định',
          formattedTime: timeFormatted,
          note: 'Hệ thống SenBank hoạt động ổn định',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList;
    if (_selectedTab == 0) {
      currentList = _balanceNotifs;
    } else if (_selectedTab == 1) {
      currentList = _promoNotifs;
    } else {
      currentList = _systemNotifs;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Thông Báo'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Thử thông báo nổi',
            icon: const Icon(CupertinoIcons.bell_fill, color: AppColors.warning),
            onPressed: _triggerRealFloatingNotification,
          ),
          if (_isLoggedIn)
            IconButton(
              tooltip: 'Đọc tất cả',
              icon: _isMarkingAllRead
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(CupertinoIcons.checkmark_circle),
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
            ),
          IconButton(
            tooltip: 'Cài đặt thông báo',
            icon: const Icon(CupertinoIcons.gear_alt),
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3 Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _buildTab(0, 'Biến động số dư'),
                  const SizedBox(width: 8),
                  _buildTab(1, 'Khuyến mãi'),
                  const SizedBox(width: 8),
                  _buildTab(2, 'Hệ thống'),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: KeyedSubtree(
                  key: ValueKey('tab_${_selectedTab}_loading_$_isLoading'),
                  child: _buildContent(currentList),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> currentList) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (!_isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            quality: GlassQuality.standard,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.lock_shield, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('Đăng nhập để xem thông báo', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                  const SizedBox(height: 8),
                  Text(
                    'Xem biến động số dư, ưu đãi và tin tức hệ thống từ ngân hàng',
                    style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.push('/auth/login'),
                    child: const Text('Đăng nhập ngay'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (currentList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedTab == 0 ? CupertinoIcons.arrow_up_arrow_down_circle : CupertinoIcons.bell_slash,
                    size: 56,
                    color: AppColors.textMutedLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedTab == 0 ? 'Chưa có biến động số dư nào' : 'Chưa có thông báo nào trong mục này',
                    style: AppTypography.bodyMedium(color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kéo xuống để cập nhật từ máy chủ',
                    style: AppTypography.bodySmall(color: AppColors.textMutedLight.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        itemCount: currentList.length,
        itemBuilder: (context, idx) {
          final item = currentList[idx];
          final isRead = (item['isRead'] ?? item['read'] ?? false) == true;
          final isBalance = _selectedTab == 0;
          final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          final bodyStr = (item['content'] ?? item['body'] ?? item['message'] ?? '').toString();
          final titleStr = (item['title'] ?? '').toString();
          final timeStr = (item['time'] ?? '').toString();
          final txIdStr = (item['txId'] ?? '').toString();
          final isPositive = amount > 0 || bodyStr.contains('PS: +');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              quality: GlassQuality.minimal,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      item['isRead'] = true;
                      item['read'] = true;
                    });
                    final id = item['id']?.toString();
                    if (id != null && id.isNotEmpty) {
                      NotificationRemoteDataSource().markRead(id);
                    }
                    if (isBalance) {
                      final uri = Uri(
                        path: '/history/detail',
                        queryParameters: {
                          'id': txIdStr,
                          'title': titleStr,
                          'amount': amount.toString(),
                          'time': timeStr,
                          'note': bodyStr,
                        },
                      );
                      context.push(uri.toString());
                    } else if (_selectedTab == 1) {
                      context.push('/promotions');
                    } else {
                      context.push('/settings/security');
                    }
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: isBalance
                            ? (isPositive ? AppColors.emeraldGreen.withOpacity(0.18) : AppColors.primary.withOpacity(0.18))
                            : (_selectedTab == 1 ? AppColors.accentGold.withOpacity(0.18) : AppColors.vividTeal.withOpacity(0.18)),
                        child: Icon(
                          isBalance
                              ? (isPositive ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_up_circle_fill)
                              : (_selectedTab == 1 ? CupertinoIcons.gift_fill : CupertinoIcons.bell_fill),
                          color: isBalance
                              ? (isPositive ? AppColors.emeraldGreen : AppColors.primary)
                              : (_selectedTab == 1 ? AppColors.accentGold : AppColors.vividTeal),
                          size: 20,
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          titleStr,
                          style: AppTypography.titleMedium(
                            color: isRead ? AppColors.textSecondaryLight : AppColors.textPrimaryLight,
                          ).copyWith(fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isBalance && amount != 0)
                        Text(
                          '${isPositive ? "+" : "-"}${CurrencyFormatter.formatVND(amount.abs())}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? AppColors.emeraldGreen : AppColors.error,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        bodyStr,
                        style: AppTypography.bodySmall(
                          color: isRead ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                        ).copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatNotifTime(timeStr),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                          ),
                          const Text('Xem chi tiết ›', style: TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        selected: isSelected,
        onSelected: (val) {
          if (_selectedTab != index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedTab = index);
          }
        },
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.bottomBarCyan : Colors.transparent,
          width: 1.2,
        ),
        shadowColor: AppColors.bottomBarGlow.withOpacity(0.4),
        elevation: isSelected ? 3 : 0,
      ),
    );
  }
}
