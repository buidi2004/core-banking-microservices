import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class SessionRemoteDataSource {
  final Dio _dio;

  SessionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

  /// Lấy danh sách sessions từ BE
  /// GET /sessions => data là List<SessionResponse>
  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await _dio.get(ApiConstants.sessions);
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true || json['data'] is! List) throw apiException(json);
    return (json['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Alias cho getSessions()
  Future<List<Map<String, dynamic>>> getActiveSessions() => getSessions();

  /// Thu hồi một phiên đăng nhập thiết bị cụ thể
  /// DELETE /sessions/{sessionId}
  Future<Map<String, dynamic>> revokeSession(String sessionId) async {
    final response = await _dio.delete(ApiConstants.sessionDetail(sessionId));
    final json = Map<String, dynamic>.from(response.data as Map);
    if (json['success'] != true) throw apiException(json);
    if (json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    return {'success': true};
  }

  /// Alias cho revokeSession()
  Future<Map<String, dynamic>> deleteSession(String sessionId) => revokeSession(sessionId);

  /// Thu hồi tất cả các phiên đăng nhập khác ngoại trừ phiên hiện tại
  Future<void> revokeAllOtherSessions({String? currentSessionId}) async {
    final sessions = await getSessions();
    for (final session in sessions) {
      final isCurrent = session['isCurrentDevice'] == true;
      final id = session['id']?.toString();
      if (!isCurrent && id != null && id != currentSessionId) {
        try {
          await revokeSession(id);
        } catch (_) {}
      }
    }
  }
}