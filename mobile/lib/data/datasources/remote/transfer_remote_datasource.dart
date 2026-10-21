import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/backend_capabilities.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class TransferRemoteDataSource {
  final Dio _dio;

  /// MOB-002: BE chưa cung cấp API xác thực PIN/OTP (BE-REQ-03) nên mobile phải
  /// chặn giao dịch. Cho phép test inject cờ để kiểm chứng nhánh "đã bật".
  final bool _serverSideTransferAuth;

  /// Kết quả saga P2P đã chạy ở bước init, dùng lại cho bước confirm.
  /// MOB-017: giới hạn tối đa 5 entry, xóa sau khi đọc; không giữ vô hạn.
  static const int _maxCompletedTransfers = 5;
  final Map<String, Map<String, dynamic>> _completedTransfers = {};

  TransferRemoteDataSource({
    Dio? dio,
    bool? serverSideTransferAuth,
  })  : _dio = dio ?? DioClient.sharedDio,
        _serverSideTransferAuth =
            serverSideTransferAuth ?? BackendCapabilities.serverSideTransferAuth;

  Future<Map<String, dynamic>> getRecipient(String value) async {
    final trimmed = value.trim();

    // 1. Kiểm tra nếu là UUID (walletId có dấu gạch nối)
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (uuidRegex.hasMatch(trimmed)) {
      final response = await _dio.get(
        ApiConstants.recipientInfo,
        queryParameters: {'walletId': trimmed},
      );
      return _unwrap(response.data);
    }

    // 2. Nếu là chuỗi hex 32 ký tự không dấu gạch nối (UUID bị bóc gạch nối) -> định dạng lại chuẩn UUID
    final hex32Regex = RegExp(r'^[0-9a-fA-F]{32}$');
    if (hex32Regex.hasMatch(trimmed)) {
      final formattedUuid = '${trimmed.substring(0, 8)}-${trimmed.substring(8, 12)}-${trimmed.substring(12, 16)}-${trimmed.substring(16, 20)}-${trimmed.substring(20)}';
      final response = await _dio.get(
        ApiConstants.recipientInfo,
        queryParameters: {'walletId': formattedUuid},
      );
      return _unwrap(response.data);
    }

    // 3. Xử lý số điện thoại
    final cleanDigits = trimmed.replaceAll(RegExp(r'[\s\.\-]'), '');
    final phoneClean = cleanDigits.startsWith('+84')
        ? '0${cleanDigits.substring(3)}'
        : (cleanDigits.startsWith('84') && cleanDigits.length == 11)
            ? '0${cleanDigits.substring(2)}'
            : cleanDigits;

    final response = await _dio.get(
      ApiConstants.recipientInfo,
      queryParameters: RegExp(r'^\d+$').hasMatch(phoneClean)
          ? {'phoneNumber': phoneClean}
          : {'walletId': trimmed},
    );
    return _unwrap(response.data);
  }

  Future<double> estimateFee(double amount) async {
    final response = await _dio.get(
      ApiConstants.estimateFee,
      queryParameters: {'type': 'TRANSFER', 'amount': amount.round(), 'currency': 'VND'},
    );
    final data = _unwrap(response.data);
    return (data['feeAmount'] as num?)?.toDouble() ?? 0;
  }

  /// Khởi tạo giao dịch P2P qua saga một bước `POST /payments/transfer`.
  ///
  /// **MOB-014 / OPT-01:** nhận trực tiếp `sourceUserId` / `targetUserId` từ
  /// client (session + `recipient-info`) để bỏ 2 `GET /wallets/{id}` dư thừa.
  /// Chỉ quay về `GET /wallets/{id}` khi client chưa truyền userId.
  ///
  /// **MOB-002 (P0):** ném [UnsupportedError] nếu BE chưa có xác thực PIN/OTP.
  Future<Map<String, dynamic>> initTransfer({
    String sourceUserId = '',
    String targetUserId = '',
    required double amount,
    required String note,
    String? idempotencyKey,
    String? sourceWalletId,
    String? targetWalletId,
    String? bankCode,
    String? pinToken,
  }) async {
    if (!_serverSideTransferAuth) {
      throw UnsupportedError(
        'Backend chưa cung cấp API xác thực PIN/OTP (BE-REQ-03). '
        'Giao dịch bị từ chối để tránh rủi ro mất tiền.',
      );
    }

    final String resolvedSourceUserId = await _resolveUserId(
      userId: sourceUserId,
      walletId: sourceWalletId,
      role: 'nguồn',
    );
    final String resolvedTargetUserId = await _resolveUserId(
      userId: targetUserId,
      walletId: targetWalletId,
      role: 'đích',
    );

    // MOB-017: idempotency key ổn định, retry mạng dùng lại đúng key.
    final key = idempotencyKey ??
        'MOBILE-$resolvedSourceUserId-$resolvedTargetUserId-${DateTime.now().microsecondsSinceEpoch}';

    final response = await _dio.post(
      ApiConstants.paymentTransfer,
      data: {
        'sourceUserId': resolvedSourceUserId,
        'targetUserId': resolvedTargetUserId,
        'amount': amount.round(),
        'currency': 'VND',
        'note': note,
        'idempotencyKey': key,
        if (pinToken != null && pinToken.isNotEmpty) 'pinToken': pinToken,
      },
      options: (pinToken != null && pinToken.isNotEmpty)
          ? Options(headers: {'X-Pin-Token': pinToken})
          : null,
    );
    final data = _unwrap(response.data);
    final status = (data['status'] ?? '').toString().toUpperCase();
    if (status == 'FAILED') {
      final reason = (data['failureReason'] ?? data['message'] ?? 'Giao dịch chuyển tiền không thành công').toString();
      throw Exception(reason.contains('INSUFFICIENT') || reason.contains('<')
          ? 'Số dư khả dụng trong ví không đủ để thực hiện giao dịch này.'
          : reason);
    }
    final txId = (data['transactionId'] ?? data['id'] ?? '').toString();
    if (txId.isNotEmpty) {
      _rememberTransfer(txId, data);
    }
    return data;
  }

  /// Bước xác nhận giao dịch.
  ///
  /// Đã tích hợp pinToken xác thực từ /users/pin/verify.
  Future<Map<String, dynamic>> confirmTransfer({
    required String transactionId,
    String? pin,
    String? otp,
    String? pinToken,
  }) async {
    final result = _completedTransfers.remove(transactionId);
    if (result != null) {
      return result;
    }
    // KHÔNG giả lập thành công: không có kết quả saga từ bước init nghĩa là
    // giao dịch chưa từng chạy (hoặc đã mất khỏi cache) ⇒ phải báo lỗi.
    throw StateError(
      'Không tìm thấy kết quả giao dịch $transactionId từ bước khởi tạo. '
      'Vui lòng thực hiện lại giao dịch.',
    );
  }

  Future<String> _resolveUserId({
    required String userId,
    String? walletId,
    required String role,
  }) async {
    if (userId.isNotEmpty) return userId;
    if (walletId == null || walletId.isEmpty) {
      throw ArgumentError(
        'Thiếu ${role == 'nguồn' ? 'sourceUserId' : 'targetUserId'} cho giao dịch chuyển tiền',
      );
    }
    debugPrint(
      '[TransferRemoteDataSource] Thiếu userId ($role), fallback GET /wallets/{id}',
    );
    return _ownerIdOfWallet(walletId);
  }

  /// MOB-017: lưu kết quả saga nhưng giới hạn tối đa 5 entry.
  void _rememberTransfer(String txId, Map<String, dynamic> data) {
    _completedTransfers[txId] = data;
    while (_completedTransfers.length > _maxCompletedTransfers) {
      _completedTransfers.remove(_completedTransfers.keys.first);
    }
  }

  Future<String> _ownerIdOfWallet(String walletId) async {
    final response = await _dio.get(ApiConstants.walletDetail(walletId));
    final data = _unwrap(response.data);
    final ownerId = (data['ownerId'] ?? '').toString();
    if (ownerId.isEmpty) {
      throw Exception('Không xác định được chủ sở hữu ví $walletId');
    }
    return ownerId;
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    if (json['success'] != true || json['data'] is! Map) throw apiException(json);
    return Map<String, dynamic>.from(json['data'] as Map);
  }
}
