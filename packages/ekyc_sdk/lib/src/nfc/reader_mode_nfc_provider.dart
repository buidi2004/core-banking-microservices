import 'dart:typed_data';

import 'package:flutter_cccd_vn/cccd_vietnam.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:logging/logging.dart';

/// ComProvider mở phiên NFC với **Android ReaderMode flags đầy đủ**.
///
/// Vì sao không dùng [NfcProvider] mặc định: bản `poll()` của nó không truyền
/// `androidReaderModeFlags`, nên Android `enableReaderMode` thiếu cờ
/// `FLAG_READER_SKIP_NDEF_CHECK` — hệ điều hành vẫn tự chạy NDEF discovery
/// (chậm hơn ~500ms và có thể đẩy intent NDEF làm đứt phiên đọc chip).
///
/// Flags áp dụng (bitwise OR, chuẩn NfcAdapter của Android):
///  - `0x80`  FLAG_READER_SKIP_NDEF_CHECK — bỏ NDEF discovery
///  - `0x100` FLAG_READER_NO_PLATFORM_SOUNDS — không beep/vibrate của OS
///  - `0x1|0x2` FLAG_READER_A/B — chỉ polling ISO-DEP (CCCD là ISO 14443-4)
class ReaderModeNfcProvider extends ComProvider {
  static final _log = Logger('ekyc.nfc.reader_mode');

  static const int flagReaderA = 0x1;
  static const int flagReaderB = 0x2;
  static const int flagSkipNdefCheck = 0x80;
  static const int flagNoPlatformSounds = 0x100;

  Duration timeout;
  NFCTag? _tag;
  final String? iosAlertMessage;

  ReaderModeNfcProvider({this.iosAlertMessage, Duration? operationTimeout})
      : timeout = operationTimeout ?? const Duration(seconds: 30),
        super(_log);

  @override
  Future<void> connect() async {
    if (isConnected()) return;
    try {
      // ignore: avoid_print
      print('[SEN HỒNG NFC] Bắt đầu bật ReaderMode: flags=0x183, timeout=${timeout.inSeconds}s, delay=300ms');
      _tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosAlertMessage: iosAlertMessage ?? 'Đưa thẻ CCCD vào sát mặt lưng điện thoại',
        androidPlatformSound: false,
        androidCheckNDEF: false,
        // Android ReaderMode: chỉ ISO-DEP + bỏ NDEF + tắt tiếng hệ thống
        androidReaderModeFlags:
            flagReaderA | flagReaderB | flagSkipNdefCheck | flagNoPlatformSounds,
        readIso14443A: true,
        readIso14443B: true,
        readIso18092: false,
        readIso15693: false,
        extraReaderPresenceCheckDelay: const Duration(milliseconds: 300),
      );
      // ignore: avoid_print
      print('[SEN HỒNG NFC] Đã bắt được sóng NFC! Tag ID=${_tag?.id}, Type=${_tag?.type}, Standard=${_tag?.standard}');
      final standard = _tag!.standard.toLowerCase();
      final isIsoDep = _tag!.type == NFCTagType.iso7816 ||
          standard.contains('14443-4') ||
          standard.contains('iso-dep') ||
          _tag!.type == NFCTagType.mifare_desfire;
      if (!isIsoDep) {
        _log.info('Bỏ qua thẻ không phải ISO-7816: ${_tag!.type}, standard: ${_tag!.standard}');
        // ignore: avoid_print
        print('[SEN HỒNG NFC] CẢNH BÁO: Thẻ không phải ISO 7816 (CCCD gắn chip)!');
        await disconnect();
        throw const ComProviderError('Thẻ không phải ISO 7816 (CCCD gắn chip)');
      }
    } on ComProviderError {
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[SEN HỒNG NFC] Lỗi khi kết nối thẻ: $e');
      throw ComProviderError(e.toString());
    }
  }

  @override
  Future<void> disconnect() async {
    if (!isConnected()) return;
    // ignore: avoid_print
    print('[SEN HỒNG NFC] Đóng phiên kết nối thẻ NFC');
    _tag = null;
    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      throw ComProviderError(e.toString());
    }
  }

  @override
  bool isConnected() => _tag != null;

  @override
  Future<Uint8List> transceive(Uint8List data, {Duration? timeout}) async {
    try {
      return await FlutterNfcKit.transceive(
        data,
        timeout: timeout ?? this.timeout,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[SEN HỒNG NFC] Lỗi APDU transceive: $e');
      throw ComProviderError(e.toString());
    }
  }
}
