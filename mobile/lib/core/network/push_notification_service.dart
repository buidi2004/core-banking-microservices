import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../storage/app_secure_storage.dart';
import '../../data/datasources/remote/device_remote_datasource.dart';
import 'realtime_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM Background Push] Nhận thông báo chạy nền: ${message.messageId}');
  debugPrint('[FCM Background Push] Title: ${message.notification?.title}');
  debugPrint('[FCM Background Push] Body: ${message.notification?.body}');
  debugPrint('[FCM Background Push] Data: ${message.data}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterSecureStorage _storage = AppSecureStorage.instance;
  final DeviceRemoteDataSource _deviceRemote = DeviceRemoteDataSource();

  String? _cachedFcmToken;
  String? get fcmToken => _cachedFcmToken;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[Firebase] Bỏ qua khởi tạo mặc định hoặc đã khởi tạo: $e');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Yêu cầu cấp quyền nhận thông báo đẩy trên thiết bị
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Quyền thông báo đẩy: ${settings.authorizationStatus}');

    // Lấy FCM Token ban đầu
    try {
      _cachedFcmToken = await messaging.getToken();
      debugPrint('[FCM] Device Token: $_cachedFcmToken');
      if (_cachedFcmToken != null) {
        await syncDeviceTokenToBackend(_cachedFcmToken!);
      }
    } catch (e) {
      debugPrint('[FCM] Không thể lấy FCM Token trên môi trường hiện tại: $e');
    }

    // Lắng nghe sự kiện token thay đổi (rotate)
    messaging.onTokenRefresh.listen((newToken) async {
      _cachedFcmToken = newToken;
      debugPrint('[FCM] Token đã cập nhật mới: $newToken');
      await syncDeviceTokenToBackend(newToken);
    });

    // Lắng nghe khi app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] Nhận thông báo: ${message.notification?.title} - ${message.notification?.body}');
      final title = message.notification?.title ?? message.data['title'] ?? 'Biến động số dư';
      final body = message.notification?.body ?? message.data['body'] ?? message.data['content'] ?? '';

      // Tự động đẩy vào Stream của RealtimeNotificationService để UI cập nhật ngay
      final payload = Map<String, dynamic>.from(message.data);
      if (!payload.containsKey('title')) payload['title'] = title;
      if (!payload.containsKey('body')) payload['body'] = body;

      // Kích hoạt cập nhật dữ liệu realtime trên UI
      try {
        RealtimeNotificationService().dispatch(payload);
      } catch (_) {}
    });

    // Lắng nghe khi người dùng bấm vào thông báo từ khay hệ thống
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM App Opened] Người dùng chạm mở thông báo: ${message.data}');
    });

    // Kiểm tra nếu app được mở từ trạng thái terminated
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM Initial Message] App khởi động từ thông báo: ${initialMessage.data}');
    }
  }

  Future<void> syncDeviceTokenToBackend(String token) async {
    try {
      final accessToken = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAccessToken);
      if (accessToken != null && accessToken.isNotEmpty) {
        final deviceType = Platform.isIOS ? 'IOS' : 'ANDROID';
        await _deviceRemote.registerDevice(fcmToken: token, deviceType: deviceType);
        debugPrint('[FCM -> BE] Đã đăng ký thành công FCM Device Token với máy chủ VPS');
      }
    } catch (e) {
      debugPrint('[FCM -> BE] Gặp lỗi khi đồng bộ token với Backend: $e');
    }
  }

  Future<void> unregisterDeviceFromBackend() async {
    try {
      if (_cachedFcmToken != null && _cachedFcmToken!.isNotEmpty) {
        await _deviceRemote.unregisterDevice(_cachedFcmToken!);
        debugPrint('[FCM -> BE] Đã hủy đăng ký FCM Token khỏi máy chủ');
      }
    } catch (e) {
      debugPrint('[FCM -> BE] Lỗi hủy đăng ký thiết bị: $e');
    }
  }
}
