import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'api_response.dart';

class TransferRemoteDataSource {
  final Dio _dio;

  /// Kết quả saga P2P đã chạy ở bước init, dùng lại cho bước confirm.
  final Map<String, Map<String, dynamic>> _completedTransfers = {};

  TransferRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient().dio;

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
      queryParameters: {'type': 'TRANSFER', 'amount': amount, 'currency': 'VND'},
    );
    final data = _unwrap(response.data);
    return (data['feeAmount'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, dynamic>> initTransfer({
    required String sourceWalletId,
    required String targetWalletId,
    required double amount,
    required String note,
    String? bankCode,
  }) async {
    // Backend microservices chỉ có endpoint saga P2P một bước: POST /payments/transfer.
    // Mobile cần userId (không phải walletId), nên tra ownerId của 2 ví trước.
    final sourceUserId = await _ownerIdOfWallet(sourceWalletId);
    final targetUserId = await _ownerIdOfWallet(targetWalletId);

    final response = await _dio.post(
      ApiConstants.paymentTransfer,
      data: {
        'sourceUserId': sourceUserId,
        'targetUserId': targetUserId,
        'amount': amount.round(),
        'currency': 'VND',
        'note': note,
        'idempotencyKey':
            'MOBILE-$sourceWalletId-$targetWalletId-${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    final data = _unwrap(response.data);
    final txId = (data['transactionId'] ?? data['id'] ?? '').toString();
    if (txId.isNotEmpty) {
      _completedTransfers[txId] = data;
    }
    return data;
  }

  /// Bước xác nhận (PIN/OTP) đã được người dùng nhập trước khi gọi initTransfer.
  /// Saga đã chạy xong ở bước trên nên chỉ cần trả lại kết quả đã lưu.
  Future<Map<String, dynamic>> confirmTransfer({
    required String transactionId,
    String? pin,
    String? otp,
  }) async {
    final result = _completedTransfers[transactionId];
    if (result == null) {
      throw Exception('Không xác nhận được giao dịch, vui lòng kiểm tra lịch sử');
    }
    return result;
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