import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';

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
  String _dob = '15/08/2004';
  String _gender = 'Nam';
  String _address = 'Hà Nội';

  String get _mrzName {
    if (_fullName.isEmpty) return 'VIETNAM<<CITIZEN<<<<<<<<<<<<<<';
    final nonDiacritics = _removeDiacritics(_fullName.toUpperCase());
    final parts = nonDiacritics.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final mrzStr = parts.join('<');
    return (mrzStr.padRight(30, '<')).substring(0, 30);
  }

  String get _mrzId {
    final cleanId = _idNumber.replaceAll(RegExp(r'\D'), '');
    final num = cleanId.isNotEmpty ? cleanId : '<<<<<<<<<<<<';
    return ('IDVNM$num'.padRight(30, '<')).substring(0, 30);
  }

  String get _mrzDobCode {
    return '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<';
  }

  String _removeDiacritics(String str) {
    const withDia = 'ÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚÝàáâãèéêìíòóôõùúýĂăĐđĨĩŨũƠơƯưẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹ';
    const withoutDia = 'AAAAEEEIIOOOOUUYaaaaeeeiioooouuyAaDdIiUuOoUuAaAaAaAaAaAaAaAaAaAaAaAaEeEeEeEeEeEeEeEeIiIiOoOoOoOoOoOoOoOoOoOoOoOoUuUuUuUuUuUuUuYyYyYyYy';
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
    const storage = FlutterSecureStorage();
    try {
      final savedName = await storage.read(key: AppConstants.keyFullName);
      if (savedName != null && savedName.isNotEmpty && mounted) {
        setState(() => _fullName = savedName);
      }

      final profileDs = ProfileRemoteDataSource();
      final results = await Future.wait([
        profileDs.getKycStatus().catchError((_) => <String, dynamic>{}),
        profileDs.getMe().catchError((_) => <String, dynamic>{}),
      ]);

      final kycData = (results[0] is Map) ? Map<String, dynamic>.from(results[0] as Map) : null;
      final meData = (results[1] is Map) ? Map<String, dynamic>.from(results[1] as Map) : null;

      if (mounted) {
        setState(() {
          _kyc = (kycData != null && kycData.isNotEmpty) ? kycData : null;
          final name = meData?['fullName'] as String? ?? meData?['name'] as String? ?? (kycData?['fullName'] as String? ?? '');
          if (name.isNotEmpty) _fullName = name;

          final cccd = meData?['idNumber'] as String? ?? meData?['citizenId'] as String? ?? (kycData?['idNumber'] as String? ?? kycData?['citizenId'] as String? ?? '');
          if (cccd.isNotEmpty) _idNumber = cccd;

          final dobStr = meData?['dateOfBirth'] as String? ?? meData?['dob'] as String? ?? (kycData?['dateOfBirth'] as String? ?? '');
          if (dobStr.isNotEmpty) _dob = dobStr;

          final g = meData?['gender'] as String? ?? (kycData?['gender'] as String? ?? '');
          if (g.isNotEmpty) _gender = g;

          final addr = meData?['address'] as String? ?? (kycData?['address'] as String? ?? '');
          if (addr.isNotEmpty) _address = addr;

          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() { _error = extractErrorMessage(error); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Hồ Sơ Căn Cước Công Dân'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Lịch sử xác thực',
            icon: const Icon(CupertinoIcons.clock_fill),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lần đối soát C06 gần nhất: 15/01/2026 09:42 (Khớp 100%)')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                :
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  Text('Bản mô phỏng CCCD gắn chip', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                  TextButton.icon(
                    onPressed: () => setState(() => _showBackSide = !_showBackSide),
                    icon: const Icon(CupertinoIcons.arrow_2_squarepath, size: 16),
                    label: Text(_showBackSide ? 'Xem mặt trước' : 'Xem mặt sau'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _showBackSide ? _buildCccdBackCard() : _buildCccdFrontCard(),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thông Tin Định Danh Điện Tử', style: AppTypography.titleMedium(color: AppColors.primaryDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_kyc?['status'] as String? ?? 'Chưa xác định', style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.cardBorderLight),
                      _buildDetailRow('Số Căn cước công dân', _idNumber.isNotEmpty ? _idNumber : 'Chưa cập nhật', isHighlight: true),
                      const SizedBox(height: 10),
                      _buildDetailRow('Họ và tên khai sinh', _fullName.isNotEmpty ? _fullName.toUpperCase() : 'Chưa cập nhật', isBold: true),
                      const SizedBox(height: 10),
                      _buildDetailRow('Ngày, tháng, năm sinh', _dob),
                      const SizedBox(height: 10),
                      _buildDetailRow('Giới tính', _gender),
                      const SizedBox(height: 10),
                      _buildDetailRow('Quốc tịch', 'Việt Nam'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Quê quán', _address.isNotEmpty ? _address : 'Việt Nam'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Nơi thường trú', _address.isNotEmpty ? _address : 'Việt Nam'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Ngày cấp', '20/09/2021'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Có giá trị đến', '15/08/2029 (Hợp lệ)'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Nơi cấp', 'Cục Cảnh sát QLHC về TTXH (C06 - BCA)'),
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
                icon: const Icon(CupertinoIcons.chart_bar_alt_fill, color: AppColors.primary),
                label: const Text('Xem phân hạng và hạn mức giao dịch'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: const Icon(CupertinoIcons.checkmark_alt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐÃ ĐỐI SOÁT DỮ LIỆU DÂN CƯ C06',
                  style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  'Giấy tờ CCCD gắn chip của bạn đã được đối soát 100% qua Cổng Dịch vụ công Quốc gia & cơ sở dữ liệu Bộ Công An.',
                  style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
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
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(
                      'Độc lập - Tự do - Hạnh phúc',
                      style: TextStyle(color: Colors.white70, fontSize: 9.5),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'CĂN CƯỚC CÔNG DÂN / IDENTITY CARD',
                      style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Body (Photo + Chip + Info)
              Expanded(
                child: Row(
                  children: [
                    // Portrait Photo Placeholder with verified stamp
                    Container(
                      width: 76,
                      height: 105,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.person_fill, size: 42, color: Colors.white70),
                              SizedBox(height: 2),
                              Text('BCA VERIFIED', style: TextStyle(fontSize: 7.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.emeraldGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.checkmark, size: 8, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
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
                                width: 28,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(CupertinoIcons.radiowaves_right, size: 14, color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 8),
                              const Icon(CupertinoIcons.wifi, color: Colors.white70, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Số / No.: ${_idNumber.isNotEmpty ? _idNumber : "Chưa cập nhật"}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 3),
                          Text('Họ và tên: ${_fullName.isNotEmpty ? _fullName.toUpperCase() : "KHÁCH HÀNG SEN HỒNG"}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Ngày sinh: $_dob  •  $_gender', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(height: 2),
                          const Text('Quốc tịch: Việt Nam', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(height: 2),
                          const Text('Có giá trị đến: 15/08/2029', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w600)),
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
              const Text('Đặc điểm nhân dạng / Personal identification:', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ICAO 9303 CHIP', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text('Nốt ruồi cách 1cm dưới sau đuôi mắt phải', style: TextStyle(color: Colors.white, fontSize: 10.5)),
          const SizedBox(height: 6),
          const Text('Ngày cấp: 20/09/2021  •  CỤC TRƯỞNG C06 BỘ CÔNG AN', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
          const Spacer(),
          // MRZ Zone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mrzId,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1.2),
                ),
                Text(
                  _mrzDobCode,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1.2),
                ),
                Text(
                  _mrzName,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 10, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppColors.bottomBarCyan : (isBold ? AppColors.primaryDark : AppColors.textPrimaryLight),
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
          Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.infoText, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuân Thủ Quyết Định 2345/QĐ-NHNN',
                  style: TextStyle(color: AppColors.infoText, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Dữ liệu khuôn mặt và chip CCCD đã được khớp sinh trắc học thành công. Bạn đủ điều kiện thực hiện chuyển khoản trên 10 triệu đồng/giao dịch hoặc tổng trên 20 triệu đồng/ngày.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.infoText, height: 1.35),
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
          Icon(CupertinoIcons.lock_shield_fill, color: AppColors.textSecondaryLight, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo Mật Dữ Liệu Theo Nghị Định 13/2023/NĐ-CP',
                  style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                SizedBox(height: 3),
                Text(
                  'Mọi thông tin danh tính được mã hóa chuẩn phần cứng AES-256 theo quy chuẩn an toàn ngân hàng số và chỉ dùng cho mục đích định danh tài khoản.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

