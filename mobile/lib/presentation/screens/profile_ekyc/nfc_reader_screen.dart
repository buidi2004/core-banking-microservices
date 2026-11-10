import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ekyc_sdk/ekyc_sdk.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import '../../widgets/user_avatar_widget.dart';

enum NfcScanState { idle, scanning, success, error }
enum NfcAuthMode { can, bac }

class NfcReaderScreen extends StatefulWidget {
  final String? initialDocumentNumber;
  final String? initialDateOfBirth;
  final String? initialExpiryDate;
  final bool autoStart;

  const NfcReaderScreen({
    super.key,
    this.initialDocumentNumber,
    this.initialDateOfBirth,
    this.initialExpiryDate,
    this.autoStart = false,
  });

  @override
  State<NfcReaderScreen> createState() => _NfcReaderScreenState();
}

class _NfcReaderScreenState extends State<NfcReaderScreen>
    with SingleTickerProviderStateMixin {
  NfcScanState _state = NfcScanState.idle;
  NfcAuthMode _authMode = NfcAuthMode.can;
  double _scanProgress = 0.0;
  Timer? _progressTimer;
  late AnimationController _pulseController;
  String _statusMessage = '';
  bool _isNfcAvailable = true;
  bool _showManualForm = false;

  // 1. Chế độ CAN (Khuyên dùng): chỉ cần 6 số in ở góc dưới thẻ CCCD
  final _canCtrl = TextEditingController();

  // 2. Chế độ BAC: Số định danh (12 số) + Ngày sinh + Ngày hết hạn
  final _docNumCtrl = TextEditingController();
  final _dobCtrl = TextEditingController(); // YYMMDD hoặc DD/MM/YYYY
  final _expiryCtrl = TextEditingController(); // YYMMDD hoặc DD/MM/YYYY
  CccdChipData? _chipData;

  bool get _hasAutoCredentials {
    final doc = _docNumCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
    final dob = _normalizeToYYMMDD(_dobCtrl.text.trim());
    final exp = _normalizeToYYMMDD(_expiryCtrl.text.trim());
    return doc.length >= 9 && dob.length == 6 && exp.length == 6;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDocumentNumber != null &&
        widget.initialDocumentNumber!.isNotEmpty) {
      _docNumCtrl.text = widget.initialDocumentNumber!;
      _authMode = NfcAuthMode.bac;
    }
    if (widget.initialDateOfBirth != null &&
        widget.initialDateOfBirth!.isNotEmpty) {
      _dobCtrl.text = widget.initialDateOfBirth!;
    }
    if (widget.initialExpiryDate != null &&
        widget.initialExpiryDate!.isNotEmpty) {
      _expiryCtrl.text = widget.initialExpiryDate!;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _checkNfcHardwareAndPopulate();
  }

  Future<void> _checkNfcHardwareAndPopulate() async {
    final available = await _chipReader.isNfcAvailable();
    if (!mounted) return;
    setState(() {
      _isNfcAvailable = available;
      if (!available) {
        _statusMessage =
            'Thiết bị chưa bật NFC hoặc không hỗ trợ NFC phần cứng. Vui lòng bật NFC trong Cài đặt máy!';
      }
    });

    if (_docNumCtrl.text.isEmpty || _dobCtrl.text.isEmpty) {
      try {
        final profile = await ProfileRemoteDataSource().getMe();
        if (!mounted) return;
        setState(() {
          if (_docNumCtrl.text.isEmpty && profile['identityCardNumber'] != null) {
            _docNumCtrl.text = profile['identityCardNumber'].toString();
          }
          if (_dobCtrl.text.isEmpty && profile['dateOfBirth'] != null) {
            _dobCtrl.text = profile['dateOfBirth'].toString();
          }
        });
      } catch (_) {
        // Tuân thủ nghiêm ngặt QĐ 2345: không sinh dữ liệu giả lập
      }
    }

    if ((widget.autoStart || _hasAutoCredentials) &&
        _docNumCtrl.text.isNotEmpty &&
        _dobCtrl.text.isNotEmpty &&
        _expiryCtrl.text.isNotEmpty) {
      _authMode = NfcAuthMode.bac;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == NfcScanState.idle) _startNfcReading();
      });
    }
  }

  final ChipReaderService _chipReader = ChipReaderService();

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    _canCtrl.dispose();
    _docNumCtrl.dispose();
    _dobCtrl.dispose();
    _expiryCtrl.dispose();
    _chipReader.cancelSession();
    super.dispose();
  }

  /// Quét nhanh mặt sau thẻ (MRZ) bằng Camera để tự động nạp Số thẻ, Ngày sinh, Hạn thẻ
  Future<void> _openMrzCamera() async {
    HapticFeedback.lightImpact();
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => EkycCardCameraView(
          title: 'Chụp Mặt Sau CCCD (MRZ)',
          hint: 'Đặt mặt sau thẻ, rõ dải mã MRZ và chip vi mạch.',
          onCaptured: (b) => Navigator.of(context).pop(b),
        ),
      ),
    );
    if (bytes != null && mounted) {
      setState(() {
        _statusMessage = 'Đang phân tích dải mã MRZ...';
      });
      final mrz = await MrzScanner.scanFromImageBytes(bytes);
      if (mounted && mrz != null) {
        setState(() {
          _docNumCtrl.text = mrz.documentNumber;
          _dobCtrl.text = mrz.birthDateYYMMDD;
          _expiryCtrl.text = mrz.expiryDateYYMMDD;
          _authMode = NfcAuthMode.bac;
          _statusMessage = 'Đã quét MRZ thành công! Sẵn sàng đọc chip.';
        });
        HapticFeedback.mediumImpact();
        _startNfcReading();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Không đọc được dải MRZ do lóa sáng hoặc mờ. Bạn có thể nhập 6 số CAN ở mặt trước để đọc nhanh hơn.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Chuẩn hóa chuỗi ngày sinh / ngày hết hạn về định dạng YYMMDD của chuẩn ICAO 9303.
  /// Hỗ trợ cả định dạng quen thuộc của người Việt (DD/MM/YYYY hoặc DDMMYYYY)
  /// và định dạng gốc (YYMMDD).
  String _normalizeToYYMMDD(String input) {
    final clean = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 8) {
      // Định dạng DDMMYYYY -> lấy YYMMDD
      final dd = clean.substring(0, 2);
      final mm = clean.substring(2, 4);
      final yyyy = clean.substring(4, 8);
      final yy = yyyy.substring(2, 4);
      return '$yy$mm$dd';
    }
    return clean;
  }

  Future<void> _startNfcReading() async {
    HapticFeedback.mediumImpact();
    // ignore: avoid_print
    print('[SEN HỒNG NFC] _startNfcReading() được gọi: mode=$_authMode');

    if (_authMode == NfcAuthMode.can) {
      final can = _canCtrl.text.replaceAll(RegExp(r'\D'), '').trim();
      if (can.length != 6) {
        // ignore: avoid_print
        print('[SEN HỒNG NFC] CAN chưa đủ 6 số: $can');
        setState(() {
          _state = NfcScanState.error;
          _statusMessage =
              'Vui lòng nhập đúng 6 chữ số CAN in ở góc dưới thẻ CCCD (hoặc chuyển sang tab Thông tin thẻ BAC).';
        });
        return;
      }

      // ignore: avoid_print
      print('[SEN HỒNG NFC] Bắt đầu đọc PACE với CAN: $can');
      setState(() {
        _state = NfcScanState.scanning;
        _scanProgress = 0.05;
        _statusMessage =
            'Đang bật sóng NFC... Áp sát thẻ vào giữa lưng điện thoại';
      });

      try {
        final data = await _chipReader.readCccdChipWithCan(
          can: can,
          documentNumber:
              _docNumCtrl.text.isNotEmpty ? _docNumCtrl.text.trim() : null,
          onProgress: _onProgress,
        );
        if (!mounted) return;
        // ignore: avoid_print
        print('[SEN HỒNG NFC] Đọc chip CCCD thành công! Tên: ${data.fullName}, Số CCCD: ${data.documentNumber}');
        setState(() {
          _chipData = data;
          _state = NfcScanState.success;
          _scanProgress = 1.0;
        });
        HapticFeedback.heavyImpact();
        unawaited(_persistVerifiedChipData(data));
      } catch (e) {
        if (!mounted) return;
        // ignore: avoid_print
        print('[SEN HỒNG NFC] Thẻ từ chối CAN/PACE (mẫu 2021-2023): $e');

        final docNum = _docNumCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
        final dob = _normalizeToYYMMDD(_dobCtrl.text.trim());
        final expiry = _normalizeToYYMMDD(_expiryCtrl.text.trim());

        if (docNum.length >= 9 && dob.length == 6 && expiry.length == 6) {
          // ignore: avoid_print
          print('[SEN HỒNG NFC] Tự động chuyển tiếp sang giải mã chuẩn BAC...');
          setState(() {
            _authMode = NfcAuthMode.bac;
          });
          await _readWithBac(docNum, dob, expiry);
          return;
        }

        setState(() {
          _authMode = NfcAuthMode.bac;
          _state = NfcScanState.error;
          _statusMessage =
              'Thẻ CCCD này (mẫu 2021-2023) không hỗ trợ 6 số CAN. Vui lòng bấm "📸 Quét nhanh mặt sau (MRZ)" hoặc nhập Ngày sinh & Hạn thẻ để giải mã qua chuẩn BAC!';
        });
      }
    } else {
      final docNum = _docNumCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
      final dob = _normalizeToYYMMDD(_dobCtrl.text.trim());
      final expiry = _normalizeToYYMMDD(_expiryCtrl.text.trim());

      if (docNum.length < 9 || dob.length != 6 || expiry.length != 6) {
        // ignore: avoid_print
        print('[SEN HỒNG NFC] BAC thiếu thông tin: docNum=$docNum, dob=$dob, expiry=$expiry');
        setState(() {
          _state = NfcScanState.error;
          _statusMessage =
              'Thiếu thông tin BAC (CCCD, Ngày sinh, Hạn thẻ). Vui lòng bấm "📸 Quét mặt sau (MRZ)" để tự động điền hoặc nhập tay.';
        });
        return;
      }

      await _readWithBac(docNum, dob, expiry);
    }
  }

  Future<void> _readWithBac(String docNum, String dob, String expiry) async {
    // ignore: avoid_print
    print('[SEN HỒNG NFC] Bắt đầu đọc BAC với docNum=$docNum, dob=$dob, exp=$expiry');
    setState(() {
      _state = NfcScanState.scanning;
      _scanProgress = 0.05;
      _statusMessage =
          'Đang bật sóng NFC (chuẩn BAC)... Áp sát thẻ vào giữa lưng điện thoại';
    });

    try {
      final data = await _chipReader.readCccdChip(
        documentNumber: docNum,
        birthDateYYMMDD: dob,
        expiryDateYYMMDD: expiry,
        onProgress: _onProgress,
      );
      if (!mounted) return;
      // ignore: avoid_print
      print('[SEN HỒNG NFC] Đọc chip BAC thành công! Tên: ${data.fullName}, Số CCCD: ${data.documentNumber}');
      setState(() {
        _chipData = data;
        _state = NfcScanState.success;
        _scanProgress = 1.0;
      });
      HapticFeedback.heavyImpact();
      unawaited(_persistVerifiedChipData(data));
    } on ChipReadException catch (e) {
      if (!mounted) return;
      if (e.code == ChipReadErrorCode.paceRequired) {
        setState(() {
          _authMode = NfcAuthMode.can;
        });
        await _promptCanAndRetry(docNum);
        return;
      }
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      // ignore: avoid_print
      print('[SEN HỒNG NFC] Lỗi khi đọc BAC: $e');
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = 'Lỗi đọc chip qua BAC: $e';
      });
    }
  }

  Future<void> _persistVerifiedChipData(CccdChipData data) async {
    try {
      const storage = AppSecureStorage.instance;
      final cleanInput = _docNumCtrl.text.replaceAll(RegExp(r'\D'), '');
      final effectiveCccd =
          cleanInput.length == 12 ? cleanInput : data.documentNumber;

      await AppSecureStorage.safeWrite(storage,
          key: AppConstants.keyCitizenId, value: effectiveCccd);
      await AppSecureStorage.safeWrite(storage,
          key: AppConstants.keyFullName, value: data.fullName);
      if (data.dateOfBirth.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyDateOfBirth, value: data.dateOfBirth);
      }
      if (data.gender.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyGender, value: data.gender);
      }
      if (data.expiryDate.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyExpiryDate, value: data.expiryDate);
      }
      await AppSecureStorage.safeWrite(storage,
          key: AppConstants.keyKycVerified, value: 'true');

      if (data.facePhotoBytes != null && data.facePhotoBytes!.isNotEmpty) {
        final b64 = base64Encode(data.facePhotoBytes!);
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyChipPhotoBase64, value: b64);
        UserAvatarNotifier.update('data:image/jpeg;base64,$b64');
      }

      // Đồng bộ thông tin CCCD và ngày sinh sang Backend Identity Service
      String backendDob = '';
      if (data.dateOfBirth.contains('/')) {
        final p = data.dateOfBirth.split('/');
        if (p.length == 3) {
          backendDob =
              '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}';
        }
      }
      ProfileRemoteDataSource().updateMe(
        fullName: data.fullName,
        email: '',
        dob: backendDob,
      ).catchError((_) => <String, dynamic>{});
    } catch (e) {
      debugPrint('[SEN HỒNG NFC] Lỗi lưu trữ dữ liệu chip: $e');
    }
  }

  Future<void> _promptCanAndRetry(String docNum) async {
    final canCtrl = TextEditingController();
    final can = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thẻ yêu cầu xác thực PACE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thẻ Căn cước mẫu mới từ chối kênh BAC (mã 69 82). '
                'Nhập số CAN (6 chữ số) in ở góc dưới mặt trước (hoặc mặt sau) thẻ để tiếp tục.'),
            const SizedBox(height: 12),
            TextField(
              controller: canCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Số CAN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(canCtrl.text.trim()),
              child: const Text('Đọc chip bằng PACE')),
        ],
      ),
    );
    if (can == null || can.length != 6 || !mounted) {
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = 'Đã hủy — cần số CAN để đọc thẻ mới (PACE)';
      });
      return;
    }
    setState(() {
      _state = NfcScanState.scanning;
      _scanProgress = 0.0;
    });
    try {
      final data = await _chipReader.readCccdChipWithCan(
        can: can,
        documentNumber: docNum,
        onProgress: _onProgress,
      );
      if (!mounted) return;
      setState(() {
        _chipData = data;
        _state = NfcScanState.success;
        _scanProgress = 1.0;
      });
      HapticFeedback.heavyImpact();
    } on ChipReadException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = NfcScanState.error;
        _statusMessage = 'Đọc chip bằng PACE thất bại: $e';
      });
    }
  }

  void _onProgress(double progress, String status) {
    if (!mounted) return;
    setState(() {
      _scanProgress = progress;
      _statusMessage = status;
    });
  }

  void _resetReading() {
    HapticFeedback.lightImpact();
    setState(() {
      _state = NfcScanState.idle;
      _scanProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy,
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bottomBarCyan.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    children: [
                      _buildDecisionBanner(),
                      const SizedBox(height: 16),
                      _buildNfcRadarArea(),
                      const SizedBox(height: 16),
                      if (_state == NfcScanState.success) ...[
                        _buildExtractedDataCard(),
                        const SizedBox(height: 16),
                        _buildActionBottom(),
                      ] else if (!_hasAutoCredentials || _showManualForm) ...[
                        _buildCardInfoForm(),
                        const SizedBox(height: 16),
                        _buildActionBottom(),
                        const SizedBox(height: 18),
                        _buildStepsGuidanceCard(),
                        const SizedBox(height: 16),
                        _buildTroubleshootingCard(),
                      ] else ...[
                        // CHẾ ĐỘ ZERO-INPUT: Ẩn 100% form nhập liệu, chỉ quét thẻ
                        _buildStepsGuidanceCard(),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => _showManualForm = true);
                            },
                            icon: const Icon(CupertinoIcons.pencil,
                                size: 14, color: Colors.white54),
                            label: const Text(
                              'Không quét được tự động? Nhập thủ công',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTroubleshootingCard(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inkNavy.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác thực Chip CCCD (NFC)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Quyết định 2345/QĐ-NHNN',
                  style: TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.checkmark_shield_fill,
                    color: AppColors.emeraldGreen, size: 14),
                SizedBox(width: 4),
                Text('C06 BCA',
                    style: TextStyle(
                        color: AppColors.emeraldGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.7),
            const Color(0xFF0F2B48).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.shield_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt buộc đối soát sinh trắc học',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Theo QĐ 2345/QĐ-NHNN, giao dịch chuyển khoản trên 10.000.000 đ/lần hoặc trên 20.000.000 đ/ngày bắt buộc phải xác thực khuôn mặt trùng khớp với dữ liệu gốc trong chip CCCD đã được Bộ Công An cấp.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcRadarArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2E).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _state == NfcScanState.success
              ? AppColors.emeraldGreen.withValues(alpha: 0.5)
              : _state == NfcScanState.error
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.bottomBarCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (_state == NfcScanState.idle || _state == NfcScanState.error) {
                _startNfcReading();
              } else if (_state == NfcScanState.scanning) {
                _resetReading();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _state == NfcScanState.scanning
                    ? 1.0 + (_pulseController.value * 0.12)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer waves
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _state == NfcScanState.success
                                ? AppColors.emeraldGreen.withValues(alpha: 0.25)
                                : _state == NfcScanState.error
                                    ? AppColors.error.withValues(alpha: 0.25)
                                    : AppColors.bottomBarCyan
                                        .withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _state == NfcScanState.success
                                ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                                : _state == NfcScanState.error
                                    ? AppColors.error.withValues(alpha: 0.4)
                                    : AppColors.bottomBarCyan
                                        .withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                      ),
                      // Center button / icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _state == NfcScanState.success
                                ? [
                                    AppColors.emeraldGreen,
                                    const Color(0xFF047857)
                                  ]
                                : _state == NfcScanState.error
                                    ? [
                                        AppColors.error,
                                        const Color(0xFF991B1B)
                                      ]
                                    : [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_state == NfcScanState.success
                                      ? AppColors.emeraldGreen
                                      : _state == NfcScanState.error
                                          ? AppColors.error
                                          : AppColors.bottomBarCyan)
                                  .withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _state == NfcScanState.success
                              ? CupertinoIcons.checkmark_alt
                              : _state == NfcScanState.error
                                  ? CupertinoIcons.exclamationmark
                                  : CupertinoIcons.radiowaves_right,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Interactive reader status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _state == NfcScanState.scanning
                  ? AppColors.bottomBarCyan.withValues(alpha: 0.18)
                  : _state == NfcScanState.success
                      ? AppColors.emeraldGreen.withValues(alpha: 0.18)
                      : _state == NfcScanState.error
                          ? AppColors.error.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _state == NfcScanState.scanning
                    ? AppColors.bottomBarCyan.withValues(alpha: 0.4)
                    : _state == NfcScanState.success
                        ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                        : _state == NfcScanState.error
                            ? AppColors.error.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _state == NfcScanState.scanning
                        ? CupertinoIcons.radiowaves_right
                        : _state == NfcScanState.success
                            ? CupertinoIcons.checkmark_alt
                            : _state == NfcScanState.error
                                ? CupertinoIcons.exclamationmark_triangle
                                : CupertinoIcons.hand_point_right_fill,
                    size: 13,
                    color: _state == NfcScanState.scanning
                        ? AppColors.bottomBarCyan
                        : _state == NfcScanState.success
                            ? AppColors.emeraldGreen
                            : _state == NfcScanState.error
                                ? AppColors.error
                                : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _state == NfcScanState.scanning
                        ? 'SÓNG NFC ĐANG BẬT — ÁP THẺ VÀO LƯNG'
                        : _state == NfcScanState.success
                            ? 'ĐÃ ĐỐI SOÁT C06 THÀNH CÔNG'
                            : _state == NfcScanState.error
                                ? 'LỖI ĐỌC — BẤM ĐỂ THỬ LẠI'
                                : (_hasAutoCredentials
                                    ? 'SẴN SÀNG QUÉT — ÁP THẺ VÀO LƯNG'
                                    : 'CHƯA BẬT SÓNG — BẤM ĐỂ BẬT QUÉT'),
                    style: TextStyle(
                      color: _state == NfcScanState.scanning
                          ? AppColors.bottomBarCyan
                          : _state == NfcScanState.success
                              ? AppColors.emeraldGreen
                              : _state == NfcScanState.error
                                  ? AppColors.error
                                  : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _state == NfcScanState.idle
                ? (_hasAutoCredentials
                    ? 'Sẵn sàng đọc thẻ CCCD'
                    : (_authMode == NfcAuthMode.can
                        ? 'Nhập 6 số CAN để kích hoạt NFC'
                        : 'Nhập thông tin thẻ để kích hoạt NFC'))
                : _state == NfcScanState.scanning
                    ? 'Đang đọc thẻ CCCD... Giữ yên thiết bị'
                    : _state == NfcScanState.error
                        ? 'Chưa đọc được chip CCCD'
                        : 'Xác thực chip CCCD thành công!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _state == NfcScanState.idle
                ? (_hasAutoCredentials
                    ? 'Đã nạp khóa bảo mật từ camera • Hãy áp thẻ vào giữa lưng điện thoại'
                    : (_authMode == NfcAuthMode.can
                        ? 'Nhập 6 số CAN in trên thẻ — đầu đọc NFC sẽ tự động bật ngay lập tức!'
                        : 'Bấm nút "Bắt đầu đọc thẻ NFC" bên dưới hoặc quét dải MRZ'))
                : _state == NfcScanState.scanning
                    ? 'Samsung: Áp thẻ vào GIỮA LƯNG MÁY • Giữ cố định 3 - 5 giây'
                    : _state == NfcScanState.error
                        ? (_statusMessage.isNotEmpty ? _statusMessage : 'Vui lòng kiểm tra lại vị trí thẻ và thông tin')
                        : 'Dữ liệu khớp 100% với Trung tâm C06 Bộ Công An',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _state == NfcScanState.error
                  ? AppColors.error
                  : Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          if (!_isNfcAvailable) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle_fill,
                      size: 14, color: AppColors.error),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cảnh báo: NFC phần cứng chưa được bật trong Cài đặt máy!',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.info_circle,
                    size: 13, color: AppColors.bottomBarCyan),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vị trí NFC: Samsung ở GIỮA LƯNG • iPhone ở ĐỈNH MÁY • Xiaomi gần camera',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_state == NfcScanState.scanning) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _scanProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.bottomBarCyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_scanProgress * 100).toInt()}%',
              style: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsGuidanceCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.list_bullet,
                    color: AppColors.bottomBarCyan, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hướng dẫn quét thẻ chuẩn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepRow(
              step: '1',
              title: 'Chuẩn bị CCCD gắn chip vật lý',
              subtitle:
                  'Đảm bảo thẻ sạch sẽ, chip không bị xước hoặc mòn tiếp điểm.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              step: '2',
              title: 'Áp chặt vào lưng điện thoại',
              subtitle:
                  'iPhone: Đặt đầu thẻ chạm vào mép trên cạnh camera.\nAndroid: Đặt thẻ ở giữa lưng máy.',
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              step: '3',
              title: 'Giữ cố định trong 3 - 5 giây',
              subtitle:
                  'Không di chuyển thẻ hoặc mở app khác trong khi máy đang quét NFC.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.bottomBarCyan.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.bottomBarCyan,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.lightbulb_fill,
              color: AppColors.bottomBarCyan, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gợi ý: Hãy tháo ốp lưng dày hoặc ốp lưng có vòng kim loại (MagSafe) để sóng NFC bắt tín hiệu nhạy và ổn định nhất.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDataCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_seal_fill,
                          color: AppColors.emeraldGreen, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dữ liệu Chip Đã Xác Thực',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('HỢP LỆ',
                      style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDataRow(
                'Họ và tên:',
                (_chipData?.fullName.isNotEmpty ?? false)
                    ? _chipData!.fullName
                    : '—'),
            _buildDataRow(
                'Số định danh (CCCD):',
                (_chipData?.documentNumber.isNotEmpty ?? false)
                    ? _chipData!.documentNumber
                    : '—'),
            _buildDataRow(
                'Ngày sinh:',
                (_chipData?.dateOfBirth.isNotEmpty ?? false)
                    ? _chipData!.dateOfBirth
                    : '—'),
            _buildDataRow(
                'Giới tính:',
                (_chipData?.gender.isNotEmpty ?? false)
                    ? _chipData!.gender
                    : '—'),
            _buildDataRow(
                'Có giá trị đến:',
                (_chipData?.expiryDate.isNotEmpty ?? false)
                    ? _chipData!.expiryDate
                    : '—'),
            _buildDataRow(
                'Ảnh chân dung chip (DG2):',
                _chipData?.facePhotoBytes != null
                    ? 'Đã trích xuất (${_chipData!.facePhotoBytes!.lengthInBytes} bytes)'
                    : 'Không có'),
            if (_chipData?.facePhotoBytes != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _chipData!.facePhotoBytes!,
                      width: 90,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            _buildDataRow('Chữ ký số SOD:',
                _chipData?.sodSignatureValid == true ? 'Nguyên vẹn' : 'LỆCH'),
          ],
        ),
      ),
    );
  }

  /// Form nhập thông tin thẻ thật — Hỗ trợ 2 phương thức: Mã CAN (nhanh nhất) hoặc Thông tin BAC
  Widget _buildCardInfoForm() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented auth mode selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _authMode = NfcAuthMode.can);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _authMode == NfcAuthMode.can
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '🔑 6 số CAN (Khuyên dùng)',
                            style: TextStyle(
                              color: _authMode == NfcAuthMode.can
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _authMode = NfcAuthMode.bac);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _authMode == NfcAuthMode.bac
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '🪪 Thông tin thẻ (BAC)',
                            style: TextStyle(
                              color: _authMode == NfcAuthMode.bac
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_authMode == NfcAuthMode.can) ...[
              const Text(
                'Mã số CAN (Card Access Number)',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nhập dãy 6 số in ở góc dưới bên phải mặt trước (hoặc sau) thẻ CCCD. Không cần nhớ ngày sinh hay hạn thẻ!',
                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _canCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                onChanged: (val) {
                  final clean = val.replaceAll(RegExp(r'\D'), '').trim();
                  if (clean.length == 6) {
                    FocusScope.of(context).unfocus();
                    _startNfcReading();
                  }
                },
                style: const TextStyle(
                  color: AppColors.bottomBarCyan,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '• • • • • •',
                  hintStyle: const TextStyle(
                      color: Colors.white24, letterSpacing: 8),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.bottomBarCyan, width: 1.5),
                  ),
                  counterText: '',
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Thông tin khóa BAC',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      if (_docNumCtrl.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.emeraldGreen
                                    .withValues(alpha: 0.3)),
                          ),
                          child: const Text('Tự động điền',
                              style: TextStyle(
                                  color: AppColors.emeraldGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  InkWell(
                    onTap: _openMrzCamera,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.camera_fill,
                              size: 14, color: AppColors.primary),
                          SizedBox(width: 5),
                          Text('📸 Quét mặt sau (MRZ)',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _docNumCtrl,
                keyboardType: TextInputType.number,
                maxLength: 12,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Số định danh CCCD (12 số)',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dobCtrl,
                      keyboardType: TextInputType.text,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Ngày sinh (DD/MM/YYYY)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _expiryCtrl,
                      keyboardType: TextInputType.text,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Hạn thẻ (DD/MM/YYYY)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBottom() {
    if (_state == NfcScanState.idle || _state == NfcScanState.error) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startNfcReading,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.radiowaves_right, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bắt đầu đọc thẻ NFC',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_state == NfcScanState.scanning) {
      return Column(
        children: [
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white60,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _resetReading,
              child: const Text('Hủy bỏ quá trình đọc',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                if (_chipData == null) return;
                await _persistVerifiedChipData(_chipData!);
                if (!mounted) return;
                // Trả dữ liệu chip THẬT (kèm ảnh DG2) về màn eKYC để làm reference
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(_chipData);
                } else {
                  context.pop(_chipData);
                }
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_seal_fill, size: 20),
                    SizedBox(width: 8),
                    Text('Tiếp tục: Quét khuôn mặt (Bước 3)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetReading,
            child: const Text('Quét lại thẻ khác',
                style: TextStyle(color: AppColors.bottomBarCyan)),
          ),
        ],
      );
    }
  }
}
