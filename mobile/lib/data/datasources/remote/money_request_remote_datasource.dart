import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/backend_capabilities.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_secure_storage.dart';
import 'api_response.dart';

class MoneyRequestRemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  MoneyRequestRemoteDataSource({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? DioClient().dio,
        _storage = storage ?? AppSecureStorage.instance;

  /// Lấy danh sách money request nhận được - gọi GET /payments/money-requests/user/{userId}
  Future<List<Map<String, dynamic>>> getReceived({String? userId}) async {
    final activeUserId = userId ?? await AppSecureStorage.safeRead(_storage, key: AppConstants.keyUserId);
    if (activeUserId == null || activeUserId.isEmpty) {
      return [];
    }
    final response = await _dio.get(ApiConstants.moneyRequestsUser(activeUserId));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Lấy danh sách money request gửi đi
  Future<List<Map<String, dynamic>>> getSent() async {
    if (!BackendCapabilities.moneyRequestDetail) {
      return [];
    }
    final response = await _dio.get(ApiConstants.moneyRequestsSent);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Lấy chi tiết money request
  Future<Map<String, dynamic>> getDetail(String id) async {
    if (!BackendCapabilities.moneyRequestDetail) {
      throw UnsupportedError('Backend chưa hỗ trợ API chi tiết yêu cầu tiền (BE-REQ-06)');
    }
    final response = await _dio.get(ApiConstants.moneyRequestDetail(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  /// Tạo money request - body: {requesterId, targetUserId, amount, note?, expiresInHours?}
  Future<Map<String, dynamic>> create({
    String? requesterId,
    String? targetUserId,
    String? payerUserId,
    required double amount,
    String currency = 'VND',
    String? note,
    String? message,
    int? expiresInHours,
  }) async {
    final activeRequesterId = requesterId ?? await AppSecureStorage.safeRead(_storage, key: AppConstants.keyUserId) ?? '';
    final activeTargetUserId = targetUserId ?? payerUserId ?? '';
    final activeNote = note ?? message;

    final response = await _dio.post(
      ApiConstants.moneyRequests,
      data: {
        'requesterId': activeRequesterId,
        'targetUserId': activeTargetUserId,
        'amount': amount.toInt(),
        if (activeNote != null && activeNote.isNotEmpty) 'note': activeNote,
        if (expiresInHours != null && expiresInHours > 0) 'expiresInHours': expiresInHours,
      },
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  /// ACCEPT money request - thêm queryParameter payerUserId
  Future<Map<String, dynamic>> accept(String id, {required String payerUserId}) async {
    final response = await _dio.post(
      ApiConstants.moneyRequestAccept(id),
      queryParameters: {'payerUserId': payerUserId},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  /// REJECT money request - thêm queryParameter payerUserId
  Future<Map<String, dynamic>> reject(String id, {required String payerUserId}) async {
    final response = await _dio.post(
      ApiConstants.moneyRequestReject(id),
      queryParameters: {'payerUserId': payerUserId},
    );
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  /// Hủy money request
  Future<Map<String, dynamic>> cancel(String id) async {
    if (!BackendCapabilities.moneyRequestCancel) {
      throw UnsupportedError('Hủy money request chưa hỗ trợ do BE chưa cung cấp API (BE-REQ-06).');
    }
    final response = await _dio.post(ApiConstants.moneyRequestCancel(id));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
