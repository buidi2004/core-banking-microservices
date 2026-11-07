import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_cccd_vn/cccd_vietnam.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../models/ekyc_models.dart';
import 'reader_mode_nfc_provider.dart';

/// Mã lỗi nghiệp vụ đọc chip — SDK map để UI hiển thị đúng hướng xử lý.
enum ChipReadErrorCode {
  nfcUnavailable,
  notIsoDepTag,
  authFailedBac, // BAC sai key (số thẻ / ngày sinh / hạn sai)
  paceRequired, // Thẻ mới từ chối BAC (69 82) — cần CAN để dùng PACE
  integrityFailure, // SOD/chữ ký số lệch — dữ liệu chip bị can thiệp
  unsupportedCard,
  readFailed,
}

class ChipReadException implements Exception {
  final ChipReadErrorCode code;
  final String message;
  final String? detail;

  const ChipReadException(this.code, this.message, {this.detail});

  @override
  String toString() => 'ChipReadException($code): $message'
      '${detail != null ? ' | $detail' : ''}';
}

/// Đọc chip CCCD gắn chip theo ICAO 9303 (fork ZeroPass/dmrtd + adapter VN).
///
/// Xử lý trọn bộ pitfall tầng giao thức:
/// - **APDU phân mảnh**: thư viện đọc binary theo khối chuẩn ICAO (DG2 ~15-25KB
///   không phụ thuộc Extended APDU), tránh lỗi `67 00` khi đọc trọn một lần.
/// - **OS cướp phiên**: flutter_nfc_kit poll ISO-DEP → Android `enableReaderMode`
///   với `FLAG_READER_SKIP_NDEF_CHECK` (không còn popup NDEF của hệ điều hành).
/// - **Thẻ mới ưu tiên PACE**: [readCccdChip] dùng BAC; nếu chip từ chối với
///   mã bảo mật (69 82) sẽ trả [ChipReadErrorCode.paceRequired] để UI chuyển
///   sang [readCccdChipWithCan] (PACE bằng 6 số CAN in trên thẻ).
/// - **Nguyên vẹn dữ liệu**: SOD/chữ ký số kiểm tra trong protocol; sai →
///   [ChipReadErrorCode.integrityFailure] (dấu hiệu làm giả phần cứng).
class ChipReaderService {
  /// NFC khả dụng? (flutter_nfc_kit — nhất quán với phiên đọc thật)
  Future<bool> isNfcAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  /// Đọc chip bằng BAC key suy diễn từ MRZ (thẻ CCCD chuẩn).
  Future<CccdChipData> readCccdChip({
    required String documentNumber,
    required String birthDateYYMMDD,
    required String expiryDateYYMMDD,
    Function(double progress, String status)? onProgress,
  }) async {
    final bacDocNum = _normalizeBacDocumentNumber(documentNumber);
    final dob = _parseYYMMDD(birthDateYYMMDD, isBirth: true);
    final expiry = _parseYYMMDD(expiryDateYYMMDD);
    return _read(
      credential: CccdMrz(
        documentNumber: bacDocNum,
        dateOfBirth: dob,
        dateOfExpiry: expiry,
      ),
      documentNumber: documentNumber,
      onProgress: onProgress,
    );
  }

  /// Đọc chip bằng PACE + CAN (thẻ Căn cước mẫu mới ưu tiên PACE hơn BAC).
  /// CAN là dãy 6 số in trên thẻ — không suy diễn được từ MRZ.
  Future<CccdChipData> readCccdChipWithCan({
    required String can,
    String? documentNumber,
    Function(double progress, String status)? onProgress,
  }) async {
    final cleanCan = can.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(cleanCan)) {
      throw const ChipReadException(
        ChipReadErrorCode.authFailedBac,
        'Số CAN phải gồm đúng 6 chữ số',
      );
    }
    return _read(
      credential: CccdCan(cleanCan),
      documentNumber: documentNumber ?? cleanCan,
      onProgress: onProgress,
    );
  }

  Future<CccdChipData> _read({
    required CccdCredential credential,
    required String documentNumber,
    Function(double progress, String status)? onProgress,
  }) async {
    if (!await isNfcAvailable()) {
      throw const ChipReadException(
        ChipReadErrorCode.nfcUnavailable,
        'Thiết bị không hỗ trợ NFC hoặc chưa bật NFC trong cài đặt',
      );
    }

    onProgress?.call(0.05, 'Đang chờ áp thẻ CCCD vào mặt lưng điện thoại...');

    final transport = ReaderModeNfcProvider();
    final reader = CccdReader(
      transport: transport,
      protocol: IcaoCccdProtocol(includePortrait: true, includeDg13: false),
      operationTimeout: const Duration(seconds: 30),
      maxRetries: 1,
    );

    try {
      await reader.connect();
      onProgress?.call(
          0.25, 'Đã nhận thẻ — thiết lập kênh bảo mật BAC/PACE...');

      final data = await reader.read(credential,
          onProgress: (completed, total, stage) {
        final ratio = total > 0 ? completed / total : 0.0;
        onProgress?.call(0.3 + 0.6 * ratio, _stageLabel(stage));
      });

      onProgress?.call(0.95, 'Đối chiếu chữ ký số SOD & hoàn tất...');

      final portrait = data.portrait;
      onProgress?.call(1.0, 'Đọc chip thành công');

      return CccdChipData(
        documentNumber: documentNumber,
        fullName: (data.fullName ?? '').trim(),
        dateOfBirth:
            data.dateOfBirth == null ? '' : _formatDDMMYYYY(data.dateOfBirth!),
        gender: (data.gender ?? '').trim(),
        expiryDate: data.dateOfExpiry == null
            ? ''
            : _formatDDMMYYYY(data.dateOfExpiry!),
        facePhotoBytes: portrait,
        sodSignatureValid: true,
      );
    } on CccdAuthenticationException catch (e) {
      throw ChipReadException(
        ChipReadErrorCode.paceRequired,
        'Thẻ yêu cầu xác thực PACE — cần nhập số CAN in trên mặt sau thẻ',
        detail: e.toString(),
      );
    } on CccdIntegrityException catch (e) {
      throw ChipReadException(
        ChipReadErrorCode.integrityFailure,
        'Kiểm tra toàn vẹn dữ liệu chip thất bại (SOD)',
        detail: e.toString(),
      );
    } on CccdCredentialException catch (e) {
      throw ChipReadException(
        ChipReadErrorCode.authFailedBac,
        'Thông tin BAC không hợp lệ (số thẻ / ngày sinh / ngày hết hạn)',
        detail: e.toString(),
      );
    } on CccdUnsupportedCardException catch (e) {
      throw ChipReadException(
        ChipReadErrorCode.unsupportedCard,
        'Loại thẻ/chip không được hỗ trợ',
        detail: e.toString(),
      );
    } on CccdException catch (e) {
      throw ChipReadException(
        ChipReadErrorCode.readFailed,
        'Lỗi đọc chip CCCD',
        detail: e.toString(),
      );
    } on ComProviderError catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('không phải iso') || msg.contains('not iso')) {
        throw ChipReadException(
          ChipReadErrorCode.notIsoDepTag,
          'Thẻ không phải thẻ CCCD gắn chip (ISO 7816). Vui lòng kiểm tra lại.',
          detail: e.toString(),
        );
      } else if (msg.contains('lost') ||
          msg.contains('disconnect') ||
          msg.contains('transceive')) {
        throw ChipReadException(
          ChipReadErrorCode.readFailed,
          'Mất kết nối với thẻ (thẻ bị di chuyển hoặc nhấc ra sớm). Vui lòng áp chặt thẻ vào lưng máy và thử lại.',
          detail: e.toString(),
        );
      } else if (msg.contains('timeout') || msg.contains('hết thời gian')) {
        throw ChipReadException(
          ChipReadErrorCode.readFailed,
          'Hết thời gian chờ kết nối thẻ CCCD. Vui lòng di chuyển thẻ quanh cụm camera hoặc lưng máy để bắt sóng.',
          detail: e.toString(),
        );
      }
      throw ChipReadException(
        ChipReadErrorCode.readFailed,
        'Lỗi giao tiếp sóng NFC',
        detail: e.toString(),
      );
    } catch (e) {
      if (e is ChipReadException) rethrow;
      final msg = e.toString().toLowerCase();
      if (msg.contains('lost') || msg.contains('disconnect')) {
        throw ChipReadException(
          ChipReadErrorCode.readFailed,
          'Mất kết nối với thẻ CCCD. Vui lòng giữ yên thẻ trong suốt 3-5 giây.',
          detail: e.toString(),
        );
      }
      throw ChipReadException(
        ChipReadErrorCode.readFailed,
        'Lỗi không xác định khi đọc thẻ NFC',
        detail: e.toString(),
      );
    } finally {
      try {
        await reader.disconnect();
      } catch (_) {}
    }
  }

  /// Dừng phiên NFC nếu người dùng bấm hủy (tắt ReaderMode)
  Future<void> cancelSession() async {
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  // ------------------------------------------------------------------

  /// MRZ doc number chuẩn ICAO TD1 của VN: 9 ký tự (12 số CCCD → bỏ 3 số mã tỉnh)
  String _normalizeBacDocumentNumber(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    return clean.length == 12 ? clean.substring(3) : clean;
  }

  DateTime _parseYYMMDD(String value, {bool isBirth = false}) {
    final clean = value.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(clean)) {
      throw const ChipReadException(
        ChipReadErrorCode.authFailedBac,
        'Ngày phải có định dạng YYMMDD (đúng 6 chữ số)',
      );
    }
    final yy = int.parse(clean.substring(0, 2));
    final nowYy = DateTime.now().year % 100;
    final year = isBirth ? (yy > nowYy ? 1900 + yy : 2000 + yy) : 2000 + yy;
    return DateTime(
        year, int.parse(clean.substring(2, 4)), int.parse(clean.substring(4, 6)));
  }

  String _formatDDMMYYYY(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _stageLabel(String stage) {
    final s = stage.toLowerCase();
    if (s.contains('dg1') || s.contains('com')) {
      return 'Đang đọc dữ liệu nhân thân (DG1)...';
    }
    if (s.contains('dg2') || s.contains('portrait') || s.contains('ảnh')) {
      return 'Đang đọc ảnh chân dung từ chip (DG2)...';
    }
    if (s.contains('sod') || s.contains('security') || s.contains('chữ ký')) {
      return 'Đang đối chiếu chữ ký số SOD...';
    }
    return 'Đang trao đổi với chip...';
  }
}
