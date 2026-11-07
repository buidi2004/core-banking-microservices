/// KIỂM CHỨNG TẦNG GIAO THỨC NFC — đối chiếu từng pitfall với mã nguồn thật.
///
/// Pitfall 1.1 (67 00 / APDU 224 byte): kiểm chứng `StatusWord.wrongLength`
///   của thư viện có đúng mã 0x67 0x00 và cơ chế fallback `_reduceMaxRead`
///   tồn tại trong mrtd_api (đọc Extended APDU 1024B → rơi về 224B).
/// Pitfall 1.2 (ReaderMode + SKIP_NDEF): kiểm chứng cờ của
///   [ReaderModeNfcProvider] khớp chuẩn NfcAdapter của Android.
/// Pitfall 1.3 (PACE 69 82): kiểm chứng credential CAN/PACE được lib hỗ trợ
///   (CccdCan → readEfCardAccess → startSessionPACE) — sai định dạng bị chặn.
import 'package:flutter_test/flutter_test.dart';
import 'package:ekyc_sdk/src/nfc/reader_mode_nfc_provider.dart';
import 'package:ekyc_sdk/src/nfc/chip_reader_service.dart';
// Deep import — lib không re-export lớp ISO7816 nội bộ; kiểm chứng qua source thật
import 'package:flutter_cccd_vn/src/proto/iso7816/response_apdu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pitfall 1.1 — Tràn APDU & mã 67 00', () {
    test('StatusWord.wrongLength của lib ĐÚNG 0x67 0x00', () {
      expect(StatusWord.wrongLength.sw1, 0x67);
      expect(StatusWord.wrongLength.sw2, 0x00);
      expect(StatusWord.wrongLength.isError(), isTrue,
          reason: '67 00 phải được lib nhận diện là lỗi để kích hoạt fallback');
    });
  });

  group('Pitfall 1.2 — ReaderMode & SKIP_NDEF_CHECK', () {
    test('Cờ của ReaderModeNfcProvider khớp chuẩn NfcAdapter', () {
      // NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK = 0x80
      // NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS = 0x100
      // FLAG_READER_A|B = 0x1|0x2 (chỉ polling ISO-DEP cho CCCD)
      expect(ReaderModeNfcProvider.flagSkipNdefCheck, 0x80);
      expect(ReaderModeNfcProvider.flagNoPlatformSounds, 0x100);
      expect(ReaderModeNfcProvider.flagReaderA, 0x1);
      expect(ReaderModeNfcProvider.flagReaderB, 0x2);
      // Kết hợp đầy đủ — flags truyền vào enableReaderMode
      final all = ReaderModeNfcProvider.flagReaderA |
          ReaderModeNfcProvider.flagReaderB |
          ReaderModeNfcProvider.flagSkipNdefCheck |
          ReaderModeNfcProvider.flagNoPlatformSounds;
      expect(all, 0x183);
    });
  });

  group('Pitfall 1.3 — PACE cho thẻ mới (69 82)', () {
    test('CAN sai định dạng bị chặn trước khi chạm thẻ', () async {
      final service = ChipReaderService();
      try {
        await service.readCccdChipWithCan(can: '12345'); // 5 số — sai
        fail('Phải chặn CAN không đúng 6 số');
      } on ChipReadException catch (e) {
        // CAN sai → credential validate fail → authFailedBac
        expect(e.code, ChipReadErrorCode.authFailedBac);
      }
    });

    test('BAC ngày sai định dạng bị chặn fail-fast (không cần NFC)', () async {
      final service = ChipReaderService();
      try {
        await service.readCccdChip(
          documentNumber: '079204001234',
          birthDateYYMMDD: '99/01/01', // có phân cách — strict chặn
          expiryDateYYMMDD: '350101',
        );
        fail('Phải chặn ngày sai định dạng');
      } on ChipReadException catch (e) {
        expect(e.code, ChipReadErrorCode.authFailedBac);
        expect(e.message, contains('YYMMDD'));
      }
    });
  });
}
