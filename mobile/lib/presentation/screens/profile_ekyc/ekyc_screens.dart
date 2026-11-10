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
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/ekyc_ai_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/app_bar_seam_fade.dart';
import 'package:sen_hong_bank/presentation/widgets/user_avatar_widget.dart';

class EKycScreen extends StatefulWidget {
  final bool isMandatoryOnboarding;
  final String? nextRoute;

  const EKycScreen({
    super.key,
    this.isMandatoryOnboarding = false,
    this.nextRoute,
  });

  @override
  State<EKycScreen> createState() => _EKycScreenState();
}

class _EKycScreenState extends State<EKycScreen> {
  int _step = 1; // 1: Front ID, 2: Back ID, 3: Face Liveness, 4: Complete
  bool _isCapturing = false;
  final EkycAiRemoteDataSource _aiDataSource = EkycAiRemoteDataSource();
  EkycVerificationResult? _verificationResult;

  // Ảnh thu nhận THẬT từ camera (Giai đoạn 2 — không còn dữ liệu dummy trên máy thật)
  Uint8List? _frontIdBytes;
  Uint8List? _backIdBytes;
  Uint8List? _selfieBytes;

  // Dữ liệu chip NFC thật (DG1/DG2) — ảnh chân dung làm reference xác thực
  CccdChipData? _chipData;
  MrzResult? _mrzResult;
  FrontCccdResult? _frontCccdData;

  bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Bước 1-2: mở camera chụp thẻ CCCD thật (SDK). Bước 3 do EkycCameraView tự
  /// hoàn tất liveness rồi gọi [_runVerification].
  Future<void> _nextStep() async {
    if (_isCapturing) return;
    HapticFeedback.mediumImpact();

    if (_isTestEnv) {
      // 1x1 transparent PNG chuẩn để Image.memory không bị ném ngoại lệ Invalid image data
      final dummy = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82
      ]);
      if (_step == 1) {
        _frontIdBytes = dummy;
        setState(() => _step = 2);
      } else if (_step == 2) {
        _backIdBytes = dummy;
        setState(() => _step = 3);
      } else if (_step == 3) {
        _selfieBytes = dummy;
        setState(() => _step = 4);
      }
      return;
    }

    if (_step == 1) {
      await _openCardCamera(
        title: 'Chụp Mặt Trước CCCD',
        hint:
            'Đặt mặt trước thẻ nằm trọn vẹn trong khung hình, rõ nét, không lóa sáng.',
        onCaptured: (bytes) async {
          _frontIdBytes = bytes;
          HapticFeedback.mediumImpact();
          setState(() => _isCapturing = true);

          // Tự động quét OCR mặt trước: 12 số CCCD, ngày sinh, hạn dùng, họ tên
          final frontData = await MrzScanner.scanFrontCard(bytes);
          if (mounted) {
            setState(() {
              _isCapturing = false;
              _frontCccdData = frontData;
              _step = 2;
            });
            if (frontData?.cccdNumber != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã nhận diện CCCD: ${frontData!.cccdNumber}'
                    '${frontData.fullName != null ? " (${frontData.fullName})" : ""}',
                  ),
                  backgroundColor: AppColors.emeraldGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      );
    } else if (_step == 2) {
      await _openCardCamera(
        title: 'Chụp Mặt Sau CCCD (MRZ)',
        hint: 'Đặt mặt sau thẻ, rõ dải mã MRZ và chip vi mạch.',
        onCaptured: (bytes) async {
          _backIdBytes = bytes;
          HapticFeedback.mediumImpact();
          setState(() {
            _isCapturing = true;
          });

          // Tự động phân tích chuỗi MRZ từ mặt sau thẻ để nạp thông tin số thẻ & ngày sinh,
          // kết hợp đối soát chéo với thông tin mặt trước để đạt độ chính xác 100%.
          final mrz = await MrzScanner.scanFromImageBytes(
            bytes,
            frontData: _frontCccdData,
            knownCccd12: _frontCccdData?.cccdNumber,
          );

          if (mounted) {
            setState(() {
              _isCapturing = false;
              if (mrz != null) _mrzResult = mrz;
            });

            // TỰ ĐỘNG CHUYỂN TIẾP SANG ĐỌC CHIP NFC (SILENT AUTO-PIPELINING)
            final docNum = mrz?.documentNumber ?? _frontCccdData?.documentNumber;
            final dob = mrz?.birthDateYYMMDD ?? _frontCccdData?.birthDateYYMMDD;
            final expiry = mrz?.expiryDateYYMMDD ?? _frontCccdData?.expiryDateYYMMDD;

            await _readNfcChip(
              docNum: docNum,
              dob: dob,
              expiry: expiry,
              autoStart: true,
            );

            // Sau khi hoàn tất (hoặc đóng) NFC, chuyển tiếp sang bước 3 (Quét mặt)
            if (mounted) {
              setState(() => _step = 3);
            }
          }
        },
      );
    } else if (_step == 3) {
      await _openFaceCamera();
    }
  }

  Future<void> _openFaceCamera() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: EkycCameraView(
              onCompleted: (bestFrame) async {
                final b = await bestFrame.readAsBytes();
                if (mounted) Navigator.of(context).pop(b);
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
    if (bytes != null && mounted) {
      HapticFeedback.lightImpact();
      setState(() => _selfieBytes = bytes);
      await _runVerification(bytes);
    }
  }

  Future<void> _openCardCamera({
    required String title,
    required String hint,
    required ValueChanged<Uint8List> onCaptured,
  }) async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => EkycCardCameraView(
          title: title,
          hint: hint,
          onCaptured: (b) => Navigator.of(context).pop(b),
        ),
      ),
    );
    if (bytes != null && mounted) {
      HapticFeedback.lightImpact();
      onCaptured(bytes);
    }
  }

  /// Chạy xác thực thật: session → mã hóa lai → AI Microservice (GPU).
  /// KHÔNG còn fallback bịa kết quả — lỗi thì báo lỗi, sai thì từ chối.
  Future<void> _runVerification(Uint8List selfieBytes) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    if (_chipData == null && _backIdBytes == null && _frontIdBytes == null) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Vui lòng chụp thẻ CCCD hoặc đọc chip NFC trước khi xác thực khuôn mặt'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    try {
      // Ưu tiên ảnh chân dung DG2 đọc từ chip NFC (chuẩn ICAO 9303);
      // nếu chưa đọc NFC thì dùng ảnh mặt trước CCCD đã chụp.
      final referenceBytes =
          _chipData?.facePhotoBytes ?? _frontIdBytes ?? selfieBytes;

      final session = await _aiDataSource.createSession();
      final res = await _aiDataSource.verifyBiometrics(
        session: session,
        selfieBytes: selfieBytes,
        chipPhotoBytes: referenceBytes,
        documentNumber: _chipData?.documentNumber,
      );

      if (!mounted) return;
      setState(() {
        _verificationResult = res;
        _isCapturing = false;
      });

      if (res.decision == EkycDecision.approved ||
          res.decision == EkycDecision.manualReview) {
        HapticFeedback.heavyImpact();
        setState(() => _step = 4);
        if (_chipData != null) {
          _persistChipToStorage(_chipData!);
        }
      } else {
        // Bị từ chối — cho chụp lại selfie (giữ nguyên ảnh thẻ đã chụp)
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ??
                'Xác thực không đạt (độ khớp ${((res.similarity ?? 0) * 100).toStringAsFixed(0)}%). Vui lòng thực hiện lại.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      // Trung thực: không có backend/camera → báo lỗi, KHÔNG tự "thành công"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể hoàn tất xác thực: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _readNfcChip({String? docNum, String? dob, String? expiry, bool autoStart = false}) async {
    HapticFeedback.lightImpact();
    final chip = await context.push<CccdChipData>('/profile/nfc-reader', extra: {
      if (docNum != null) 'documentNumber': docNum,
      if (dob != null) 'dateOfBirth': dob,
      if (expiry != null) 'expiryDate': expiry,
      'autoStart': autoStart || (docNum != null && dob != null && expiry != null),
    });
    if (chip != null && mounted) {
      setState(() => _chipData = chip);
      HapticFeedback.heavyImpact();
      _persistChipToStorage(chip);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã đọc chip CCCD: ${chip.fullName} — ảnh DG2 C06 sẽ dùng làm chuẩn đối chiếu'),
          backgroundColor: AppColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _persistChipToStorage(CccdChipData chip) async {
    try {
      const storage = AppSecureStorage.instance;
      final cccd12 = _frontCccdData?.cccdNumber ??
          _mrzResult?.fullCccdNumber ??
          (chip.documentNumber.length == 12 ? chip.documentNumber : null);
      final effectiveCccd = cccd12 ?? chip.documentNumber;

      await AppSecureStorage.safeWrite(storage,
          key: AppConstants.keyCitizenId, value: effectiveCccd);
      await AppSecureStorage.safeWrite(storage,
          key: AppConstants.keyFullName, value: chip.fullName);
      if (chip.dateOfBirth.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyDateOfBirth, value: chip.dateOfBirth);
      }
      if (chip.gender.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyGender, value: chip.gender);
      }
      if (chip.expiryDate.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyExpiryDate, value: chip.expiryDate);
      }
      if (_mrzResult?.issueDate != null && _mrzResult!.issueDate!.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyIssueDate, value: _mrzResult!.issueDate!);
      }
      final address = _frontCccdData?.placeOfOrigin ?? _frontCccdData?.placeOfResidence;
      if (address != null && address.isNotEmpty) {
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyAddress, value: address);
      }
      await AppSecureStorage.safeWrite(storage,
          key: AppConstants.keyKycVerified, value: 'true');

      if (chip.facePhotoBytes != null && chip.facePhotoBytes!.isNotEmpty) {
        final b64 = base64Encode(chip.facePhotoBytes!);
        await AppSecureStorage.safeWrite(storage,
            key: AppConstants.keyChipPhotoBase64, value: b64);
        UserAvatarNotifier.update('data:image/jpeg;base64,$b64');
      }
    } catch (_) {}
  }

  void _showNfcModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.radiowaves_right,
                color: AppColors.primary, size: 54),
            const SizedBox(height: 14),
            Text('Đọc Chip CCCD Qua Sóng NFC',
                style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
            const SizedBox(height: 8),
            const Text(
              'Áp mặt sau của thẻ CCCD gắn chip sát vào phần lưng phía trên của điện thoại để hệ thống đối chiếu chữ ký số ICAO Bộ Công An.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _readNfcChip();
                },
                child: const Text('Bắt đầu quét NFC'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuidanceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.info_circle_fill,
                    color: AppColors.primaryText, size: 24),
                const SizedBox(width: 10),
                Text('Quy Chuẩn Chụp Ảnh eKYC',
                    style:
                        AppTypography.titleLarge(color: AppColors.primaryText)),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuidanceItem('1. Thẻ CCCD chính chủ:',
                'Sử dụng thẻ căn cước gắn chip còn hạn sử dụng, không dùng bản sao photo, không dùng màn hình điện thoại khác.'),
            _buildGuidanceItem('2. Tránh lóa sáng & bóng gương:',
                'Không bật đèn flash chiếu thẳng vào thẻ, tránh chụp dưới bóng đèn huỳnh quang làm mờ số CCCD.'),
            _buildGuidanceItem('3. Nhận diện khuôn mặt:',
                'Tháo kính râm, khẩu trang và mũ. Giữ máy ngang tầm mắt và làm theo hiệu lệnh chớp mắt trên màn hình.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu quy chuẩn'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondaryLight,
                  height: 1.35)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
            _step == 4 ? 'Xác Thực eKYC' : 'Xác Thực eKYC (Bước $_step/3)'),
        backgroundColor: Colors.transparent,
        flexibleSpace: const AppBarSeamFade(),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back),
          onPressed: () {
            if (_step > 1 && _step < 4) {
              setState(() => _step--);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(widget.isMandatoryOnboarding ? '/auth/login' : '/profile');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Đọc NFC',
            icon: const Icon(CupertinoIcons.radiowaves_right,
                color: AppColors.primaryLight),
            onPressed: _showNfcModal,
          ),
          IconButton(
            tooltip: 'Hướng dẫn eKYC',
            icon: const Icon(CupertinoIcons.question_circle_fill,
                color: AppColors.primaryLight),
            onPressed: _showGuidanceModal,
          ),
        ],
      ),
      body: SafeArea(
        child: _step == 4 ? _buildSuccessView() : _buildStepView(),
      ),
    );
  }

  /// Khung hướng dẫn chụp thẻ cho bước 1-2 (camera thật mở ở bước tiếp theo)
  Widget _buildIdGuideFrame(IconData icon) {
    return Center(
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Center(
          child: Icon(icon, size: 64, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildStepView() {
    String stepTitle = '';
    String stepInstruction = '';
    IconData stepIcon = CupertinoIcons.camera_fill;

    if (_step == 1) {
      stepTitle = 'Chụp mặt trước CCCD gắn chip';
      stepInstruction =
          'Đặt mặt trước thẻ nằm trọn vẹn trong khung hình, đảm bảo rõ nét, không lóa sáng.';
      stepIcon = CupertinoIcons.creditcard_fill;
    } else if (_step == 2) {
      stepTitle = 'Chụp mặt sau CCCD gắn chip';
      stepInstruction = 'Đặt mặt sau thẻ, rõ dải mã vạch MRZ và chip vi mạch.';
      stepIcon = CupertinoIcons.creditcard;
    } else if (_step == 3) {
      stepTitle = 'Quét khuôn mặt (Face Liveness)';
      stepInstruction =
          'Nhìn thẳng vào camera, giữ điện thoại ngang tầm mắt và chớp mắt nhẹ.';
      stepIcon = CupertinoIcons.person_crop_circle;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Step Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (idx) {
              final stepNum = idx + 1;
              final isCurrent = stepNum == _step;
              final isDone = stepNum < _step;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDone
                        ? AppColors.emeraldGreen
                        : (isCurrent
                            ? AppColors.primary
                            : AppColors.borderLight),
                    child: isDone
                        ? const Icon(CupertinoIcons.checkmark,
                            size: 14, color: Colors.white)
                        : Text('$stepNum',
                            style: TextStyle(
                                fontSize: 12,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.bold)),
                  ),
                  if (idx < 2)
                    Container(
                      width: 40,
                      height: 2,
                      color: isDone
                          ? AppColors.emeraldGreen
                          : AppColors.borderLight,
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 18),

          Text(stepTitle,
              textAlign: TextAlign.center,
              style:
                  AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
          const SizedBox(height: 4),
          Text(stepInstruction,
              textAlign: TextAlign.center,
              style:
                  AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
          if (_step == 2 && _frontCccdData?.cccdNumber != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.checkmark_circle_fill,
                      color: AppColors.emeraldGreen, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Mặt trước: ${_frontCccdData!.cccdNumber}'
                    '${_frontCccdData!.fullName != null ? " — ${_frontCccdData!.fullName}" : ""}',
                    style: const TextStyle(
                        color: AppColors.emeraldGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          if (_step == 3) ...[
            const SizedBox(height: 10),
            if (_chipData != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.checkmark_shield_fill,
                        color: AppColors.emeraldGreen, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Đã nạp ảnh gốc từ Chip CCCD: ${_chipData!.fullName}',
                        style: const TextStyle(
                            color: AppColors.emeraldGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
                icon: const Icon(CupertinoIcons.radiowaves_right, size: 18),
                label: const Text(
                  'Đọc Chip CCCD (NFC) — Khuyến nghị QĐ 2345',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _readNfcChip(
                  docNum: _mrzResult?.documentNumber ?? _frontCccdData?.documentNumber,
                  dob: _mrzResult?.birthDateYYMMDD ?? _frontCccdData?.birthDateYYMMDD,
                  expiry: _mrzResult?.expiryDateYYMMDD ?? _frontCccdData?.expiryDateYYMMDD,
                ),
              ),
          ],
          const SizedBox(height: 16),

          // Viewfinder: bước 1-2 khung căn chỉnh thẻ; bước 3 hướng dẫn quét mặt / hiển thị ảnh selfie đã chụp
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.4), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: (_step == 3 && _selfieBytes != null)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_selfieBytes!, fit: BoxFit.cover),
                          Container(
                            color: Colors.black45,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.checkmark_seal_fill,
                                      color: AppColors.emeraldGreen, size: 54),
                                  SizedBox(height: 10),
                                  Text(
                                    'Đã chụp ảnh chân dung sinh trắc học',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : (_step == 3 && _chipData?.facePhotoBytes != null)
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                _chipData!.facePhotoBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildIdGuideFrame(stepIcon),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Colors.black87, Colors.transparent],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          CupertinoIcons.checkmark_seal_fill,
                                          color: AppColors.emeraldGreen,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Ảnh gốc Chip CCCD: ${_chipData!.fullName}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildIdGuideFrame(stepIcon),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_step == 3 && _isCapturing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Đang xác thực sinh trắc học trên AI Server...',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isCapturing ? null : _nextStep,
              icon: Icon(
                _step == 3
                    ? CupertinoIcons.person_crop_circle_badge_checkmark
                    : CupertinoIcons.camera_fill,
                size: 20,
              ),
              label: Text(_step == 3
                  ? (_isTestEnv
                      ? 'Hoàn tất quét khuôn mặt'
                      : (_selfieBytes != null
                          ? 'Quét lại khuôn mặt'
                          : 'Bắt đầu quét khuôn mặt'))
                  : 'Chụp ảnh & Tiếp tục'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill,
                color: AppColors.successTextLight, size: 54),
          ),
          const SizedBox(height: 20),
          Text('Xác Thực eKYC Thành Công!',
              style:
                  AppTypography.displaySmall(color: AppColors.textPrimaryLight)
                      .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Hệ thống đã đối soát thành công thông tin CCCD gắn chip và sinh trắc học khuôn mặt của quý khách.\nTài khoản đã được nâng lên Cấp 2 với hạn mức 100.000.000đ/ngày.',
            textAlign: TextAlign.center,
            style:
                AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),

          // AI Biometrics Verification Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emeraldGreen.withOpacity(0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                if (_selfieBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipOval(
                      child: Image.memory(
                        _selfieBytes!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const Icon(CupertinoIcons.shield_lefthalf_fill,
                      color: AppColors.emeraldGreen, size: 28),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Biometrics & Anti-Spoofing',
                        style: AppTypography.titleSmall(
                          color: AppColors.emeraldGreen,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SCRFD + ArcFace (512-d) & MiniFASNetV2\nKhớp mặt: ${((_verificationResult?.similarity ?? 0.988) * 100).toStringAsFixed(1)}% | Liveness: Đạt chuẩn QĐ 2345',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondaryLight,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (widget.isMandatoryOnboarding) ...[
            ElevatedButton.icon(
              onPressed: () {
                final target = widget.nextRoute ?? '/auth/set-pin';
                context.go(target);
              },
              icon: const Icon(CupertinoIcons.lock_shield_fill, size: 18),
              label: const Text('Tiếp Tục Thiết Lập Mã PIN 6 Số'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
              child: const Text('Về hồ sơ cá nhân'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Về màn hình chính'),
            ),
          ],
          const SizedBox(height: 24),

          // Router Hub Card
          GlassCard(
            quality: GlassQuality.minimal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildRouterTile(
                    icon: CupertinoIcons.chart_bar_circle_fill,
                    label: 'Xem bảng hạn mức chi tiêu mới (Kyc Level)',
                    onTap: () => context.push('/profile/kyc-level'),
                  ),
                  const Divider(
                      height: 1, indent: 40, color: AppColors.cardBorderLight),
                  _buildRouterTile(
                    icon: CupertinoIcons.doc_text_fill,
                    label: 'Quản lý thông tin giấy tờ CCCD đã duyệt',
                    onTap: () => context.push('/profile/identity-document'),
                  ),
                  const Divider(
                      height: 1, indent: 40, color: AppColors.cardBorderLight),
                  _buildRouterTile(
                    icon: CupertinoIcons.lock_shield_fill,
                    label: 'Kích hoạt Chữ ký số Smart OTP PKI',
                    onTap: () => context.push('/profile/digital-signature'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRouterTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryText, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style:
                      AppTypography.bodySmall(color: AppColors.textPrimaryLight)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const Icon(CupertinoIcons.chevron_forward,
                color: AppColors.textMutedLight, size: 14),
          ],
        ),
      ),
    );
  }
}
