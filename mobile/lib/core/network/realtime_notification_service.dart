import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/app_secure_storage.dart';
import 'dio_client.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  StompClient? _stompClient;
  final StreamController<Map<String, dynamic>> _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final Set<String> _activeSubscribedTopics = {};

  String? _currentWalletId;
  String? _currentUserId;

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  bool get isConnected => _stompClient?.connected ?? false;

  void dispatch(Map<String, dynamic> payload) {
    if (!_notificationController.isClosed) {
      _notificationController.add(payload);
    }
  }

  Future<void> connect({
    String? walletId,
    String? userId,
    required String accessToken,
  }) async {
    const storage = AppSecureStorage.instance;

    // 1. Xác định walletId: Tham số truyền vào -> Cache secure storage -> Gọi API GET /wallets/me
    var targetWalletId = walletId;
    if (targetWalletId == null || targetWalletId.isEmpty) {
      targetWalletId = await AppSecureStorage.safeRead(storage, key: AppConstants.keyWalletId);
    }
    if (targetWalletId == null || targetWalletId.isEmpty) {
      try {
        final dio = DioClient().dio;
        final res = await dio.get(
          ApiConstants.walletMe,
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
        final json = Map<String, dynamic>.from(res.data as Map);
        final data = json['data'] as Map<String, dynamic>?;
        targetWalletId = data?['id']?.toString();
        if (targetWalletId != null && targetWalletId.isNotEmpty) {
          await AppSecureStorage.safeWrite(storage, key: AppConstants.keyWalletId, value: targetWalletId);
        }
      } catch (e) {
        debugPrint('[WebSocket STOMP] Chưa lấy được walletId từ /wallets/me: $e');
      }
    }
    _currentWalletId = targetWalletId;

    // 2. Xác định userId
    var targetUserId = userId;
    if (targetUserId == null || targetUserId.isEmpty) {
      targetUserId = await AppSecureStorage.safeRead(storage, key: AppConstants.keyUserId);
    }
    _currentUserId = targetUserId;

    // 3. Nếu StompClient đã kết nối từ trước, đăng ký ngay lập tức các topic mới
    if (_stompClient != null && _stompClient!.connected) {
      _subscribeAllActiveTopics();
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: (StompFrame frame) {
          debugPrint('[WebSocket STOMP] Đã kết nối thành công tới máy chủ VPS');
          _activeSubscribedTopics.clear();
          _subscribeAllActiveTopics();
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[WebSocket STOMP] Lỗi kết nối WebSocket: $error');
        },
        onStompError: (StompFrame frame) {
          debugPrint('[WebSocket STOMP] Lỗi khung STOMP: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          debugPrint('[WebSocket STOMP] Đã ngắt kết nối WebSocket');
          _activeSubscribedTopics.clear();
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $accessToken',
        },
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _stompClient?.activate();
  }

  /// Đăng ký tất cả các topic cần lắng nghe
  void _subscribeAllActiveTopics() {
    if (_stompClient == null || !_stompClient!.connected) return;

    // ✅ ĐÚNG THEO BE: /topic/wallets/{walletId}/notifications
    if (_currentWalletId != null && _currentWalletId!.isNotEmpty) {
      final walletTopic = '/topic/wallets/$_currentWalletId/notifications';
      _subscribeTopic(walletTopic);
    }

    // Dự phòng thêm: /topic/users/{userId}/notifications
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      final userTopic = '/topic/users/$_currentUserId/notifications';
      _subscribeTopic(userTopic);
    }
  }

  void _subscribeTopic(String destination) {
    if (_activeSubscribedTopics.contains(destination)) return;
    _activeSubscribedTopics.add(destination);
    debugPrint('[WebSocket STOMP] Đang subscribe: $destination');

    _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null && frame.body!.isNotEmpty) {
          try {
            final payload = jsonDecode(frame.body!) as Map<String, dynamic>;
            debugPrint('[WebSocket STOMP] Nhận thông báo từ [$destination]: $payload');
            _notificationController.add(payload);
          } catch (e) {
            debugPrint('[WebSocket STOMP] Lỗi giải mã tin nhắn từ [$destination]: $e');
          }
        }
      },
    );
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _activeSubscribedTopics.clear();
    _currentWalletId = null;
    _currentUserId = null;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
  }
}