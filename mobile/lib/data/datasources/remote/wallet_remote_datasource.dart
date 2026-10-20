import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/app_secure_storage.dart';
import '../../../domain/entities/wallet_entity.dart';
import 'api_response.dart';

class WalletRemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  WalletRemoteDataSource({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? DioClient().dio,
        _storage = storage ?? AppSecureStorage.instance;

  Future<WalletEntity> getMyWallet() async {
    // 1. Luôn ưu tiên gọi GET /wallets/me để lấy thông tin ví và walletId chính thức từ BE
    try {
      final response = await _dio.get(ApiConstants.walletMe);
      final wallet = _parseWallet(response.data);
      await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyWalletId, value: wallet.walletId);
      return wallet;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    // 2. Dự phòng: Kiểm tra cache walletId đã lưu trước đó
    final cachedWalletId = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyWalletId);
    if (cachedWalletId != null && cachedWalletId.isNotEmpty) {
      try {
        final res = await _dio.get(ApiConstants.walletDetail(cachedWalletId));
        return _parseWallet(res.data);
      } catch (_) {}
    }

    // 3. Fallback theo số điện thoại qua recipient-info
    final phone = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyPhoneNumber);
    if (phone != null && phone.isNotEmpty) {
      final infoRes = await _dio.get(
        ApiConstants.recipientInfo,
        queryParameters: {'phoneNumber': phone},
      );
      final infoJson = Map<String, dynamic>.from(infoRes.data as Map);
      final walletId = infoJson['data']?['walletId'] as String?;
      if (walletId != null && walletId.isNotEmpty) {
        await AppSecureStorage.safeWrite(_storage, key: AppConstants.keyWalletId, value: walletId);
        final walletRes = await _dio.get(ApiConstants.walletDetail(walletId));
        return _parseWallet(walletRes.data);
      }
    }

    throw Exception('WALLET_NOT_FOUND: Không thể tìm thấy thông tin ví');
  }

  WalletEntity _parseWallet(dynamic rawData) {
    final json = Map<String, dynamic>.from(rawData as Map);
    final data = json['data'] as Map<String, dynamic>?;
    if (json['success'] != true || data == null) throw apiException(json);
    return WalletEntity(
      walletId: data['id'] as String,
      userId: data['ownerId'] as String,
      balance: (data['balance'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'VND',
    );
  }
}