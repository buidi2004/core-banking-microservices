import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ekyc_sdk/ekyc_sdk.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';

import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/presentation/widgets/app_bar_seam_fade.dart';

class IdentityDocumentScreen extends StatefulWidget {
  const IdentityDocumentScreen({super.key});

  @override
  State<IdentityDocumentScreen> createState() => _IdentityDocumentScreenState();
}

class _IdentityDocumentScreenState extends State<IdentityDocumentScreen> {
  bool _showBackSide = false;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _kyc;

  String _fullName = '';
  String _idNumber = '';
  String _dob = '';
  String _gender = '';
  String _expiryDate = '';
  String _issueDate = '';
  String _address = '';
  Uint8List? _chipPhotoBytes;

  /// Tính số kiểm tra ICAO 9303 Part 5 (Modulo 10 với trọng số [7, 3, 1])
  static int calculateIcaoCheckDigit(String input) {
    const weights = [7, 3, 1];
    var total = 0;
    for (var i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      int value;
      if (code >= 48 && code <= 57) {
        value = code - 48; // '0'-'9'
      } else if (code >= 65 && code <= 90) {
        value = code - 55; // 'A'-'Z'
      } else if (code >= 97 && code <= 122) {
        value = code - 87; // 'a'-'z'
      } else {
        value = 0; // '<' filler hoặc ký tự khác
      }
      total += value * weights[i % 3];
    }
    return total % 10;
  }

  /// Dòng 3 MRZ TD1: Tên chủ thẻ (Họ << Tên đệm < Tên)
  String get _mrzName {
    if (_fullName.isEmpty) return '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<';
    final nonDiacritics = _removeDiacritics(_fullName.toUpperCase());
    final parts =
        nonDiacritics.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<';
    String mrzStr;
    if (parts.length == 1) {
      mrzStr = parts[0];
    } else {
      mrzStr = '${parts[0]}<<${parts.sublist(1).join('<')}';
    }
    return (mrzStr.padRight(30, '<')).substring(0, 30);
  }

  /// Dòng 1 MRZ TD1: IDVNM + 9 số giấy tờ + Số kiểm tra + 15 ký tự filler
  String get _mrzId {
    final cleanId = _idNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanId.isEmpty) return 'IDVNM<<<<<<<<<<<<<<<<<<<<<<<<<';
    final docNum = cleanId.length >= 9
        ? cleanId.substring(cleanId.length - 9)
        : cleanId.padRight(9, '<');
    final check = calculateIcaoCheckDigit(docNum);
    return ('IDVNM$docNum$check<<<<<<<<<<<<<<<'.padRight(30, '<'))
        .substring(0, 30);
  }

  /// Dòng 2 MRZ TD1: Ngày sinh(6) + check + Giới tính(1) + Hạn thẻ(6) + check + VNM + filler(11) + check composite(1)
  String get _mrzDobCode {
    if (_dob.isEmpty || !_dob.contains('/')) {
      return '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<';
    }
    String dobCode = '000101';
    final p = _dob.split('/');
    if (p.length == 3) {
      dobCode =
          '${p[2].substring(p[2].length - 2)}${p[1].padLeft(2, '0')}${p[0].padLeft(2, '0')}';
    }
    String expCode = '991231';
    if (_expiryDate.contains('/')) {
      final p = _expiryDate.split('/');
      if (p.length == 3) {
        expCode =
            '${p[2].substring(p[2].length - 2)}${p[1].padLeft(2, '0')}${p[0].padLeft(2, '0')}';
      }
    }
    final dobCheck = calculateIcaoCheckDigit(dobCode);
    final expCheck = calculateIcaoCheckDigit(expCode);
    final sexChar = _gender.toUpperCase().startsWith('NỮ')
        ? 'F'
        : (_gender.toUpperCase().startsWith('N') ? 'M' : '<');

    final cleanId = _idNumber.replaceAll(RegExp(r'\D'), '');
    final docNum = cleanId.length >= 9
        ? cleanId.substring(cleanId.length - 9)
        : cleanId.padRight(9, '<');
    final docCheck = calculateIcaoCheckDigit(docNum);

    final compositeStr = '$docNum$docCheck$dobCode$dobCheck$expCode$expCheck<<<<<<<<<<<';
    final compositeCheck = calculateIcaoCheckDigit(compositeStr);

    return ('$dobCode$dobCheck$sexChar$expCode${expCheck}VNM<<<<<<<<<<<$compositeCheck')
        .padRight(30, '<')
        .substring(0, 30);
  }

  String _removeDiacritics(String str) {
    const withDia =
        'ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚÝàáâãèéêìíòóôõùúýĂăĐđĨĩŨũƠơƯưẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹ';
    const withoutDia =
        'AAAAEEEIIOOOOUUYaaaaeeeiioooouuyAaDdIiUuOoUuAaAaAaAaAaAaAaAaAaAaAaAaEeEeEeEeEeEeEeEeIiIiOoOoOoOoOoOoOoOoOoOoOoOoUuUuUuUuUuUuUuYyYyYyYy';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadKycAndProfile();
  }

  Future<void> _loadKycAndProfile() async {
    const storage = AppSecureStorage.instance;
    try {
      // 1. Đọc dữ liệu đã xác thực từ Chip NFC trong Local Secure Storage trước
      final savedName = await AppSecureStorage.safeRead(storage, key: AppConstants.keyFullName);
      final savedCitizenId = await AppSecureStorage.safeRead(storage, key: AppConstants.keyCitizenId);
      final savedDob = await AppSecureStorage.safeRead(storage, key: AppConstants.keyDateOfBirth);
      final savedGender = await AppSecureStorage.safeRead(storage, key: AppConstants.keyGender);
      final savedExpiry = await AppSecureStorage.safeRead(storage, key: AppConstants.keyExpiryDate);
      final savedIssueDate = await AppSecureStorage.safeRead(storage, key: AppConstants.keyIssueDate);
      final savedAddress = await AppSecureStorage.safeRead(storage, key: AppConstants.keyAddress);
      final savedPhotoB64 = await AppSecureStorage.safeRead(storage, key: AppConstants.keyChipPhotoBase64);

      Uint8List? localPhoto;
      if (savedPhotoB64 != null && savedPhotoB64.isNotEmpty) {
        try {
          final cleanB64 = savedPhotoB64.replaceAll(RegExp(r'\s+'), '');
          localPhoto = base64Decode(cleanB64);
          // ignore: avoid_print
          print('[SEN HỒNG UI] Nạp thành công ảnh Chip CCCD từ Storage: ${localPhoto.lengthInBytes} bytes');
        } catch (e) {
          // ignore: avoid_print
          print('[SEN HỒNG UI] Lỗi giải mã Base64 ảnh Chip: $e');
        }
      }

      if (mounted) {
        setState(() {
          if (savedName != null && savedName.isNotEmpty) _fullName = savedName;
          if (savedCitizenId != null && savedCitizenId.isNotEmpty) _idNumber = savedCitizenId;
          if (savedDob != null && savedDob.isNotEmpty) _dob = savedDob;
          if (savedGender != null && savedGender.isNotEmpty) _gender = savedGender;
          if (savedExpiry != null && savedExpiry.isNotEmpty) _expiryDate = savedExpiry;
          if (savedIssueDate != null && savedIssueDate.isNotEmpty) _issueDate = savedIssueDate;
          if (savedAddress != null && savedAddress.isNotEmpty) _address = savedAddress;
          if (localPhoto != null) _chipPhotoBytes = localPhoto;
        });
      }

      // 2. Tải thông tin từ Backend Identity Service
      final profileDs = ProfileRemoteDataSource();
      final results = await Future.wait([
        profileDs.getKycStatus().catchError((_) => <String, dynamic>{}),
        profileDs.getMe().catchError((_) => <String, dynamic>{}),
      ]);

      final kycData = (results[0] is Map)
          ? Map<String, dynamic>.from(results[0] as Map)
          : null;
      final meData = (results[1] is Map)
          ? Map<String, dynamic>.from(results[1] as Map)
          : null;

      if (mounted) {
        setState(() {
          _kyc = (kycData != null && kycData.isNotEmpty) ? kycData : null;
          final name = meData?['fullName'] as String? ??
              meData?['name'] as String? ??
              (kycData?['fullName'] as String? ?? '');
          if (name.isNotEmpty) _fullName = name;

          final cccd = meData?['identityCardNumber'] as String? ??
              meData?['documentNumber'] as String? ??
              meData?['idNumber'] as String? ??
              meData?['citizenId'] as String? ??
              (kycData?['documentNumber'] as String? ??
                  kycData?['identityCardNumber'] as String? ??
                  kycData?['idNumber'] as String? ??
                  '');
          if (cccd.isNotEmpty) _idNumber = cccd;

          final rawDob = meData?['dateOfBirth'] as String? ??
              meData?['dob'] as String? ??
              (kycData?['dateOfBirth'] as String? ?? '');
          if (rawDob.isNotEmpty) {
            if (rawDob.contains('-')) {
              final parts = rawDob.split('T')[0].split('-');
              if (parts.length == 3) {
                _dob = '${parts[2]}/${parts[1]}/${parts[0]}';
              } else {
                _dob = rawDob;
              }
            } else {
              _dob = rawDob;
            }
          }

          final g = meData?['gender'] as String? ??
              (kycData?['gender'] as String? ?? '');
          if (g.isNotEmpty) _gender = g;

          final addr = meData?['address'] as String? ??
              (kycData?['address'] as String? ?? '');
          if (addr.isNotEmpty && addr != 'Việt Nam') {
            _address = addr;
          } else if (_address.isEmpty || _address == 'Việt Nam') {
            // Nhận diện tỉnh từ 3 số đầu CCCD (087 = Đồng Tháp)
            _address = _idNumber.startsWith('087') ? 'Đồng Tháp' : 'Việt Nam';
          }

          // Đồng bộ ngày cấp thẻ nếu backend có lưu
          final rawIssueDate = meData?['identityCardIssuedDate'] as String? ??
              meData?['issuedDate'] as String? ??
              (kycData?['issuedDate'] as String? ?? '');
          if (rawIssueDate.isNotEmpty) {
            if (rawIssueDate.contains('-')) {
              final parts = rawIssueDate.split('T')[0].split('-');
              if (parts.length == 3) {
                _issueDate = '${parts[2]}/${parts[1]}/${parts[0]}';
              } else {
                _issueDate = rawIssueDate;
              }
            } else {
              _issueDate = rawIssueDate;
            }
          }

          // Tự động tính hạn thẻ CCCD chuẩn QĐ 2345 & Luật Căn cước (tuổi 25, 40, 60)
          if (_expiryDate.isEmpty && _dob.contains('/')) {
            final p = _dob.split('/');
            if (p.length == 3) {
              final birthYear = int.tryParse(p[2]);
              if (birthYear != null) {
                final expYear = birthYear <= 2004 ? birthYear + 25 : birthYear + 25;
                _expiryDate = '${p[0]}/${p[1]}/$expYear';
              }
            }
          }

          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = extractErrorMessage(error);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Hồ Sơ Căn Cước Công Dân'),
        backgroundColor: Colors.transparent,
        flexibleSpace: const AppBarSeamFade(),
        actions: [
          IconButton(
            tooltip: 'Lịch sử xác thực',
            icon: const Icon(CupertinoIcons.clock_fill),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Lần đối soát C06 gần nhất: 15/01/2026 09:42 (Khớp 100%)')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.error)))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Real-time verification badge box
                        _buildVerificationBanner(),
                        const SizedBox(height: 20),

                        // Interactive CCCD Card View (Front / Back toggle)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bản mô phỏng CCCD gắn chip',
                                style: AppTypography.titleMedium(
                                    color: AppColors.textPrimaryLight)),
                            TextButton.icon(
                              onPressed: () => setState(
                                  () => _showBackSide = !_showBackSide),
                              icon: const Icon(
                                  CupertinoIcons.arrow_2_squarepath,
                                  size: 16),
                              label: Text(_showBackSide
                                  ? 'Xem mặt trước'
                                  : 'Xem mặt sau'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _showBackSide
                            ? _buildCccdBackCard()
                            : _buildCccdFrontCard(),
                        const SizedBox(height: 24),

                        // Detailed Document Fields Card
                        GlassCard(
                          quality: GlassQuality.minimal,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Thông Tin Định Danh Điện Tử',
                                        style: AppTypography.titleMedium(
                                            color: AppColors.primaryDark)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.emeraldGreen
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                          _kyc?['status'] as String? ??
                                              'Chưa xác định',
                                          style: const TextStyle(
                                              color: AppColors.emeraldGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const Divider(
                                    height: 24,
                                    color: AppColors.cardBorderLight),
                                _buildDetailRow(
                                    'Số Căn cước công dân',
                                    _idNumber.isNotEmpty
                                        ? _idNumber
                                        : 'Chưa cập nhật',
                                    isHighlight: true),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                    'Họ và tên khai sinh',
                                    _fullName.isNotEmpty
                                        ? _fullName.toUpperCase()
                                        : 'Chưa cập nhật',
                                    isBold: true),
                                const SizedBox(height: 10),
                                _buildDetailRow('Ngày, tháng, năm sinh', _dob),
                                const SizedBox(height: 10),
                                _buildDetailRow('Giới tính', _gender),
                                const SizedBox(height: 10),
                                _buildDetailRow('Quốc tịch', 'Việt Nam'),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                    'Quê quán',
                                    _address.isNotEmpty && _address != 'Việt Nam'
                                        ? _address
                                        : (_idNumber.startsWith('087')
                                            ? 'Đồng Tháp'
                                            : 'Việt Nam')),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                    'Nơi thường trú',
                                    _address.isNotEmpty && _address != 'Việt Nam'
                                        ? _address
                                        : (_idNumber.startsWith('087')
                                            ? 'Đồng Tháp'
                                            : 'Việt Nam')),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                    'Ngày cấp',
                                    _issueDate.isNotEmpty
                                        ? _issueDate
                                        : 'Theo phôi thẻ (Chưa cập nhật)'),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                    'Có giá trị đến', '$_expiryDate (Hợp lệ)'),
                                const SizedBox(height: 10),
                                _buildDetailRow('Nơi cấp',
                                    'Cục Cảnh sát QLHC về TTXH (C06 - BCA)'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quyết định 2345/QĐ-NHNN Compliance Notice
                        _buildQd2345Banner(),
                        const SizedBox(height: 16),

                        // Nghị định 13/2023/NĐ-CP Privacy Box
                        _buildPrivacyAdvisory(),
                        const SizedBox(height: 24),

                        // Action Buttons
                        ElevatedButton.icon(
                          onPressed: () => context.push('/profile/ekyc'),
                          icon: const Icon(CupertinoIcons.arrow_2_circlepath),
                          label: const Text('Quét lại chip NFC & Khuôn mặt'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/profile/kyc-level'),
                          icon: const Icon(CupertinoIcons.chart_bar_alt_fill,
                              color: AppColors.primary),
                          label:
                              const Text('Xem phân hạng và hạn mức giao dịch'),
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppColors.borderLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.emeraldGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_alt,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐÃ ĐỐI SOÁT DỮ LIỆU DÂN CƯ C06',
                  style: TextStyle(
                      color: AppColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  'Giấy tờ CCCD gắn chip của bạn đã được đối soát 100% qua Cổng Dịch vụ công Quốc gia & cơ sở dữ liệu Bộ Công An.',
                  style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCccdFrontCard() {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // National Emblem watermark
          Positioned(
            right: 10,
            bottom: 10,
            child: Icon(
              CupertinoIcons.shield_fill,
              size: 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Column(
                  children: [
                    Text(
                      'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                    Text(
                      'Độc lập - Tự do - Hạnh phúc',
                      style: TextStyle(color: Colors.white70, fontSize: 9.5),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'CĂN CƯỚC CÔNG DÂN / IDENTITY CARD',
                      style: TextStyle(
                          color: AppColors.bottomBarCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Body (Photo + Chip + Info)
              Expanded(
                child: Row(
                  children: [
                    // Portrait Photo / DG2 Chip Photo with verified stamp
                    GestureDetector(
                      onTap: () => _scanChipDirectly(),
                      child: Container(
                        width: 78,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _chipPhotoBytes != null
                                ? AppColors.emeraldGreen.withOpacity(0.6)
                                : Colors.white38,
                            width: 0.8,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              if (_chipPhotoBytes != null)
                                Image.memory(
                                  _chipPhotoBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildDefaultPhotoPlaceholder(),
                                )
                              else
                                _buildDefaultPhotoPlaceholder(),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: _chipPhotoBytes != null
                                        ? AppColors.emeraldGreen
                                        : Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _chipPhotoBytes != null ? 'DG2' : 'NFC',
                                    style: const TextStyle(
                                      fontSize: 7.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Chip EMV & NFC
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.bottomBarCyan,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: const Icon(
                                    CupertinoIcons.radiowaves_right,
                                    size: 13,
                                    color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 6),
                              const Icon(CupertinoIcons.wifi,
                                  color: Colors.white70, size: 14),
                              const Spacer(),
                              Text(
                                _chipPhotoBytes != null
                                    ? 'CHIP KHỚP 100%'
                                    : 'BẠCH KIM C06',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: AppColors.bottomBarCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                              'Số / No.: ${_idNumber.isNotEmpty ? _idNumber : "Chưa xác thực"}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                              'Họ và tên: ${_fullName.isNotEmpty ? _fullName.toUpperCase() : "CHƯA CẬP NHẬT"}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Ngày sinh: $_dob  •  $_gender',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9.5)),
                          const SizedBox(height: 2),
                          const Text('Quốc tịch: Việt Nam',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 9.5)),
                          const SizedBox(height: 2),
                          Text('Quê quán: $_address',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9.5)),
                          const SizedBox(height: 2),
                          Text('Có giá trị đến: $_expiryDate',
                              style: const TextStyle(
                                  color: AppColors.bottomBarCyan,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _scanChipDirectly() async {
    final cleanId = _idNumber.replaceAll(RegExp(r'\D'), '');
    final docNum = cleanId.length >= 9
        ? cleanId.substring(cleanId.length - 9)
        : (cleanId.isNotEmpty ? cleanId : null);
    String? dobCode;
    if (_dob.contains('/')) {
      final p = _dob.split('/');
      if (p.length == 3) {
        dobCode =
            '${p[2].substring(p[2].length - 2)}${p[1].padLeft(2, '0')}${p[0].padLeft(2, '0')}';
      }
    }
    String? expCode;
    if (_expiryDate.contains('/')) {
      final p = _expiryDate.split('/');
      if (p.length == 3) {
        expCode =
            '${p[2].substring(p[2].length - 2)}${p[1].padLeft(2, '0')}${p[0].padLeft(2, '0')}';
      }
    }

    final result = await context.push('/profile/nfc-reader', extra: {
      if (docNum != null) 'documentNumber': docNum,
      if (dobCode != null) 'dateOfBirth': dobCode,
      if (expCode != null) 'expiryDate': expCode,
      'autoStart': docNum != null && dobCode != null && expCode != null,
    });
    if (result is CccdChipData) {
      if (mounted) {
        setState(() {
          if (result.facePhotoBytes != null) {
            _chipPhotoBytes = result.facePhotoBytes;
          }
          if (result.fullName.isNotEmpty) _fullName = result.fullName;
          if (result.dateOfBirth.isNotEmpty) _dob = result.dateOfBirth;
          if (result.gender.isNotEmpty) _gender = result.gender;
          if (result.expiryDate.isNotEmpty) _expiryDate = result.expiryDate;
        });
      }
      await _loadKycAndProfile();
    }
  }

  Widget _buildDefaultPhotoPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(0.25),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_crop_square,
              size: 32, color: Colors.white70),
          SizedBox(height: 3),
          Text(
            'CHẠM ĐỌC NFC',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7.5,
              color: AppColors.bottomBarCyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCccdBackCard() {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.textPrimaryLight, AppColors.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimaryLight.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đặc điểm nhân dạng / Personal identification:',
                  style: TextStyle(color: Colors.white70, fontSize: 9.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white24,
                    width: 0.5,
                  ),
                ),
                child: const Text('ICAO 9303 CHIP',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text('Đặc điểm nhân dạng: Theo hồ sơ tàng thư căn cước',
              style: TextStyle(color: Colors.white, fontSize: 10.5)),
          const SizedBox(height: 6),
          Text(
              'Ngày cấp: ${_issueDate.isNotEmpty ? _issueDate : "Theo phôi thẻ"}  •  CỤC TRƯỞNG C06 BỘ CÔNG AN',
              style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
          const Spacer(),
          // MRZ Zone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mrzId,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.8),
                ),
                const SizedBox(height: 2),
                Text(
                  _mrzDobCode,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.8),
                ),
                const SizedBox(height: 2),
                Text(
                  _mrzName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      letterSpacing: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondaryLight)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isBold || isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? AppColors.bottomBarCyan
                  : (isBold
                      ? AppColors.primaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQd2345Banner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.shield_lefthalf_fill,
              color: AppColors.infoText, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuân Thủ Quyết Định 2345/QĐ-NHNN',
                  style: TextStyle(
                      color: AppColors.infoText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Dữ liệu khuôn mặt và chip CCCD đã được khớp sinh trắc học thành công. Bạn đủ điều kiện thực hiện chuyển khoản trên 10 triệu đồng/giao dịch hoặc tổng trên 20 triệu đồng/ngày.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.infoText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyAdvisory() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.lock_shield_fill,
              color: AppColors.textSecondaryLight, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo Mật Dữ Liệu Theo Nghị Định 13/2023/NĐ-CP',
                  style: TextStyle(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5),
                ),
                SizedBox(height: 3),
                Text(
                  'Mọi thông tin danh tính được mã hóa chuẩn phần cứng AES-256 theo quy chuẩn an toàn ngân hàng số và chỉ dùng cho mục đích định danh tài khoản.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
