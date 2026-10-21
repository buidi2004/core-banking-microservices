import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/notification_parser.dart';
import 'api_response.dart';

class NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<List<Map<String, dynamic>>> getNotifications(String type, {int page = 0, int size = 20}) async {
    final res = await getNotificationsPage(type: type, page: page, size: size);
    return res['items'] as List<Map<String, dynamic>>;
  }

  Future<Map<String, dynamic>> getNotificationsPage({
    required String type,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.notifications,
      queryParameters: {'type': type, 'page': page, 'size': size},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    final data = json['data'];
    List rawList = [];
    bool isLast = false;
    int totalElements = 0;
    int totalPages = 1;

    if (data is List) {
      rawList = data;
      isLast = rawList.length < size;
      totalElements = rawList.length;
    } else if (data is Map) {
      if (data['content'] is List) {
        rawList = data['content'] as List;
      }
      isLast = (data['last'] ?? data['isLast'] ?? (rawList.length < size)) == true;
      totalElements = (data['totalElements'] as num?)?.toInt() ?? rawList.length;
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    } else if (json['success'] != true) {
      throw apiException(json);
    }

    final items = rawList.map((item) {
      final value = Map<String, dynamic>.from(item as Map);

      // BE trả `dataPayload` (jsonb -> String JSON). Giữ tương thích với các key cũ
      // (`metadata`, `data`) để không vỡ dữ liệu lịch sử.
      Map<String, dynamic> metadata = {};
      final rawPayload = value['dataPayload'] ?? value['metadata'];
      if (rawPayload is String && rawPayload.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawPayload);
          if (decoded is Map) metadata = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      } else if (rawPayload is Map) {
        metadata = Map<String, dynamic>.from(rawPayload);
      } else if (value['data'] is Map) {
        metadata = Map<String, dynamic>.from(value['data'] as Map);
      }

      final content = (value['content'] ?? value['body'] ?? value['message'] ?? '').toString();
      final isRead = (value['isRead'] ?? value['read'] ?? false) == true;
      final payloadType = (metadata['type'] ?? value['type'] ?? '').toString().toUpperCase();

      // M-02, M-03: Chuẩn hóa parse qua NotificationParser
      final amount = NotificationParser.parseAmount(
        metadata: metadata,
        body: content,
        type: payloadType,
      );
      final balanceRaw = NotificationParser.parseEndingBalance(
        metadata: metadata,
        body: content,
      );
      final accountNumber = NotificationParser.parseAccountNumber(
        metadata: metadata,
        body: content,
      );
      final note = NotificationParser.parseNote(
        metadata: metadata,
        body: content,
      );

      return {
        'id': value['id']?.toString() ?? '',
        'userId': value['userId']?.toString() ?? '',
        'title': value['title']?.toString() ?? '',
        'body': content,
        'content': content,
        'message': content,
        'type': payloadType.isNotEmpty ? payloadType : type,
        'time': value['createdAt']?.toString() ?? value['timestamp']?.toString() ?? metadata['timestamp']?.toString() ?? '',
        'isRead': isRead,
        'read': isRead,
        'txId': (metadata['transactionId'] ?? value['transactionId'])?.toString() ?? '',
        'amount': amount,
        'accountNumber': accountNumber,
        'endingBalance': balanceRaw,
        'transactionTime': metadata['timestamp']?.toString() ?? value['createdAt']?.toString(),
        'note': note,
        'metadata': metadata,
        'raw': value,
      };
    }).toList();

    return {
      'items': items,
      'isLast': isLast,
      'page': page,
      'totalElements': totalElements,
      'totalPages': totalPages,
    };
  }

  Future<void> markRead(String id) async {
    final response = await _dio.patch(ApiConstants.readNotification(id));
    _check(response.data);
  }

  Future<void> markAllRead({String? type}) async {
    final response = await _dio.patch(
      ApiConstants.readAllNotifications,
      queryParameters: {if (type != null) 'type': type},
    );
    _check(response.data);
  }

  Future<void> updateSettings({
    required bool transactionEnabled,
    required bool promoEnabled,
  }) async {
    final response = await _dio.put(
      ApiConstants.notificationSettings,
      queryParameters: {
        'transactionEnabled': transactionEnabled,
        'promoEnabled': promoEnabled,
      },
    );
    _check(response.data);
  }

  void _check(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    if (json['success'] != true) throw apiException(json);
  }
}