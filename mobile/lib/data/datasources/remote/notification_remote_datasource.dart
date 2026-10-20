import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
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
      Map<String, dynamic> metadata = {};
      if (value['metadata'] is String && (value['metadata'] as String).isNotEmpty) {
        try {
          metadata = jsonDecode(value['metadata'] as String) as Map<String, dynamic>;
        } catch (_) {}
      } else if (value['data'] is Map) {
        metadata = Map<String, dynamic>.from(value['data'] as Map);
      }

      final content = (value['content'] ?? value['body'] ?? value['message'] ?? '').toString();
      double amount = (metadata['amount'] as num?)?.toDouble() ?? 0.0;
      if (amount == 0.0 && content.isNotEmpty) {
        final match = RegExp(r'PS:\s*([+-]?[\d\.]+)').firstMatch(content);
        if (match != null) {
          final clean = match.group(1)!.replaceAll('.', '');
          amount = double.tryParse(clean) ?? 0.0;
        }
      }

      final isRead = (value['isRead'] ?? value['read'] ?? false) == true;

      final accountMatch = RegExp(r'Tài khoản:\s*([^\n]+)').firstMatch(content)?.group(1)?.trim();
      final balanceMatch = RegExp(r'Số dư cuối:\s*([^\n]+)').firstMatch(content)?.group(1)?.trim();
      final timeMatch = RegExp(r'Thời gian:\s*([^\n]+)').firstMatch(content)?.group(1)?.trim();
      final noteMatch = RegExp(r'Nội dung:\s*([^\n]+)').firstMatch(content)?.group(1)?.trim();

      return {
        'id': value['id']?.toString() ?? '',
        'userId': value['userId']?.toString() ?? '',
        'title': value['title']?.toString() ?? '',
        'body': content,
        'content': content,
        'message': content,
        'type': value['type']?.toString() ?? type,
        'time': value['createdAt']?.toString() ?? value['timestamp']?.toString() ?? '',
        'isRead': isRead,
        'read': isRead,
        'txId': (metadata['transactionId'] ?? value['transactionId'])?.toString() ?? '',
        'amount': amount,
        'accountNumber': accountMatch,
        'endingBalance': balanceMatch,
        'transactionTime': timeMatch,
        'note': noteMatch,
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

  void _check(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    if (json['success'] != true) throw apiException(json);
  }
}