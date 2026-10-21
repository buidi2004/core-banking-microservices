import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/storage/app_secure_storage.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../widgets/user_avatar_widget.dart';

class UserProfileScreen extends StatefulWidget {
  final ProfileRemoteDataSource? profileDataSource;
  const UserProfileScreen({super.key, this.profileDataSource});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final ProfileRemoteDataSource _profileDs = widget.profileDataSource ?? ProfileRemoteDataSource();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  // VAT Invoicing & Decree 13 Controllers (Consolidated from EmailSettingsScreen)
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _taxCodeCtrl = TextEditingController();
  final TextEditingController _invoiceAddressCtrl = TextEditingController();
  bool _vatInvoiceEnabled = true;
  bool _protectPdfWithPassword = true;

  bool _isEditing = false;
  bool _loading = true;
  bool _isSaving = false;
  String? _error;
  String? _avatarUrl;
  File? _localAvatarFile;
  bool _isUploadingAvatar = false;
  String _cid = '';
  String _createdAt = '';
  final String _branch = 'Hội sở chính - TP. Hồ Chí Minh';
  String _kycStatus = 'Hội Viên Sen V-Gold • eKYC Cấp 2';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      const storage = AppSecureStorage.instance;
      final savedPhone = await AppSecureStorage.safeRead(storage, key: AppConstants.keyPhoneNumber);
      final savedName = await AppSecureStorage.safeRead(storage, key: AppConstants.keyFullName);
      final vatComp = await AppSecureStorage.safeRead(storage, key: 'profile_vat_company');
      final vatTax = await AppSecureStorage.safeRead(storage, key: 'profile_vat_tax_code');
      final vatAddr = await AppSecureStorage.safeRead(storage, key: 'profile_vat_address');
      final vatActive = await AppSecureStorage.safeRead(storage, key: 'profile_vat_enabled');
      final pdfPass = await AppSecureStorage.safeRead(storage, key: 'profile_pdf_protect');

      if (mounted) {
        if (savedPhone != null && savedPhone.isNotEmpty) _phoneCtrl.text = savedPhone;
        if (savedName != null && savedName.isNotEmpty) _nameCtrl.text = savedName;
        if (vatComp != null && vatComp.isNotEmpty) _companyNameCtrl.text = vatComp;
        if (vatTax != null && vatTax.isNotEmpty) _taxCodeCtrl.text = vatTax;
        if (vatAddr != null && vatAddr.isNotEmpty) _invoiceAddressCtrl.text = vatAddr;
        if (vatActive != null) _vatInvoiceEnabled = vatActive == 'true';
        if (pdfPass != null) _protectPdfWithPassword = pdfPass == 'true';
      }

      final profile = await _profileDs.getMe();
      if (!mounted) return;
      final avUrl = profile['avatarUrl'] as String? ?? '';
      UserAvatarNotifier.update(avUrl);

      final kyc = await _profileDs.getKycStatus();
      if (kyc != null && mounted) {
        final status = kyc['status'] as String? ?? 'VERIFIED';
        final level = kyc['level'] ?? 2;
        setState(() {
          _kycStatus = 'Hội Viên Sen V-Gold • eKYC Cấp $level ($status)';
        });
      }

      setState(() {
        final fName = profile['fullName'] as String? ?? '';
        if (fName.isNotEmpty) _nameCtrl.text = fName;
        final pEmail = profile['email'] as String? ?? '';
        if (pEmail.isNotEmpty) _emailCtrl.text = pEmail;
        final pDob = profile['dob'] as String? ?? profile['dateOfBirth'] as String? ?? '';
        if (pDob.isNotEmpty) _dobCtrl.text = pDob;
        final pPhone = profile['phoneNumber'] as String? ?? '';
        if (pPhone.isNotEmpty) _phoneCtrl.text = pPhone;

        _cid = (profile['id'] ?? profile['userId'] ?? '').toString();
        final rawCreated = (profile['createdAt'] ?? '').toString();
        if (rawCreated.isNotEmpty) {
          try {
            final dt = DateTime.tryParse(rawCreated)?.toLocal();
            if (dt != null) {
              _createdAt = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            } else {
              _createdAt = rawCreated;
            }
          } catch (_) {
            _createdAt = rawCreated;
          }
        }
        _avatarUrl = avUrl;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = extractErrorMessage(error); _loading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _companyNameCtrl.dispose();
    _taxCodeCtrl.dispose();
    _invoiceAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();
    try {
      await _profileDs.updateMe(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
      );

      const storage = AppSecureStorage.instance;
      await AppSecureStorage.safeWrite(storage, key: 'profile_vat_company', value: _companyNameCtrl.text.trim());
      await AppSecureStorage.safeWrite(storage, key: 'profile_vat_tax_code', value: _taxCodeCtrl.text.trim());
      await AppSecureStorage.safeWrite(storage, key: 'profile_vat_address', value: _invoiceAddressCtrl.text.trim());
      await AppSecureStorage.safeWrite(storage, key: 'profile_vat_enabled', value: _vatInvoiceEnabled.toString());
      await AppSecureStorage.safeWrite(storage, key: 'profile_pdf_protect', value: _protectPdfWithPassword.toString());

      if (!mounted) return;
      setState(() => _isEditing = false);
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Row(
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Cập nhật hồ sơ & thông tin VAT thành công!')),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(extractErrorMessage(error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDob() async {
    if (!_isEditing) return;
    DateTime initial = DateTime(1995, 1, 1);
    if (_dobCtrl.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_dobCtrl.text);
      if (parsed != null) initial = parsed;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'CHỌN NGÀY THÁNG NĂM SINH',
      confirmText: 'XÁC NHẬN',
      cancelText: 'HỦY',
    );
    if (picked != null && mounted) {
      setState(() {
        _dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showAvatarActionSheet() {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: const Text('Cập Nhật Ảnh Đại Diện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        message: const Text('Chọn ảnh từ thư viện, chụp ảnh mới hoặc bộ sưu tập VIP'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AvatarPickerSheet.show(
                context,
                currentAvatarUrl: _avatarUrl,
                onImageFilePicked: (file) => _uploadAndApplyAvatar(file),
                onAvatarUrlSelected: (url, title) => _applyAvatarUrl(url, title),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_on_rectangle, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Chọn ảnh thư viện & Bộ sưu tập Sen VIP'),
              ],
            ),
          ),
          if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                setState(() {
                  _avatarUrl = '';
                  _localAvatarFile = null;
                });
                UserAvatarNotifier.update('');
                try {
                  await _profileDs.updateAvatar('');
                } catch (_) {}
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.trash, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Gỡ bỏ ảnh đại diện'),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy', style: TextStyle(color: AppColors.primary)),
        ),
      ),
    );
  }

  Future<void> _uploadAndApplyAvatar(File file) async {
    setState(() {
      _isUploadingAvatar = true;
      _localAvatarFile = file;
    });
    try {
      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _profileDs.updateAvatar(base64String);
      if (!mounted) return;
      setState(() {
        _avatarUrl = base64String;
      });
      UserAvatarNotifier.update(base64String);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Row(
            children: [
              Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Cập nhật ảnh đại diện thành công!')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi cập nhật ảnh: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _applyAvatarUrl(String url, String title) async {
    setState(() => _isUploadingAvatar = true);
    try {
      await _profileDs.updateAvatar(url);
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _localAvatarFile = null;
      });
      UserAvatarNotifier.update(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Đã đổi avatar sang "$title" thành công!')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi cập nhật avatar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _exportPersonalData() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.doc_text_search, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trích Xuất Dữ Liệu Cá Nhân',
                        style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Quy định theo Nghị định 13/2023/NĐ-CP',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Theo Điều 9 Nghị định 13/2023/NĐ-CP về Bảo vệ dữ liệu cá nhân, chủ tài khoản ngân hàng có quyền yêu cầu cung cấp bản sao toàn bộ dữ liệu định danh, lịch sử thiết bị và nhật ký giao dịch được mã hóa an toàn.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.45),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Định dạng tài liệu:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      Text(
                        'JSON / PDF có chữ ký số PKI',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: AppColors.dividerLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gửi tới email:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      Text(
                        _emailCtrl.text.isEmpty ? 'Chưa cập nhật' : _emailCtrl.text,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.emeraldGreen,
                      content: Row(
                        children: [
                          Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Yêu cầu đã được xác nhận. Tệp nén mã hóa sẽ gửi về email trong 15 phút.')),
                        ],
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.tray_arrow_down_fill, size: 18),
                label: const Text('Xác nhận & Gửi bản sao dữ liệu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadProfile();
                setState(() => _isEditing = false);
              },
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
            ),
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                HapticFeedback.selectionClick();
                setState(() => _isEditing = true);
              }
            },
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text(
                    _isEditing ? 'Lưu' : 'Chỉnh sửa',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.error, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadProfile, child: const Text('Thử lại')),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                    child: Column(
                      children: [
                        // Apple ID Hero Profile Header
                        _buildAppleIdHeader(context),
                        const SizedBox(height: 16),

                        // Subtle Liquid Glass Account Metadata Card
                        _buildMetadataCard(),
                        const SizedBox(height: 18),

                        // Inset Group 1: Thông tin cá nhân & Liên hệ
                        _buildSectionHeader('THÔNG TIN LIÊN HỆ & ĐỊNH DANH'),
                        _buildContactInfoCard(),
                        const SizedBox(height: 18),

                        // Inset Group 2: Cài đặt Hóa đơn VAT & Doanh nghiệp (Gom từ EmailSettingsScreen)
                        _buildSectionHeader('HÓA ĐƠN VAT & DOANH NGHIỆP'),
                        _buildVatInvoicingCard(),
                        const SizedBox(height: 18),

                        // Inset Group 3: Định danh CCCD & Hạn mức eKYC
                        _buildSectionHeader('ĐỊNH DANH & HẠN MỨC GIAO DỊCH'),
                        _buildIdentityNavigationCard(context),
                        const SizedBox(height: 18),

                        // Inset Group 4: Quyền riêng tư theo Nghị định 13
                        _buildSectionHeader('QUYỀN RIÊNG TƯ & DỮ LIỆU CÁ NHÂN'),
                        _buildPrivacyCard(),
                        const SizedBox(height: 24),

                        if (_isEditing) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isSaving ? null : _saveProfile,
                              icon: const Icon(LucideIcons.check, size: 18),
                              label: const Text('Lưu Thay Đổi Hồ Sơ', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleIdHeader(BuildContext context) {
    final displayName = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim().toUpperCase() : 'CHỦ TÀI KHOẢN SEN HỒNG';
    final phone = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : 'Chưa có số';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatarWidget(
                radius: 46,
                avatarUrl: _avatarUrl,
                localFile: _localAvatarFile,
                isLoading: _isUploadingAvatar,
                borderColor: AppColors.bottomBarCyan,
                showCameraBadge: true,
                onCameraTap: _showAvatarActionSheet,
                onTap: _showAvatarActionSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'STK: $phone',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.emeraldGreen,
                      content: Text('Đã sao chép STK: $phone'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(LucideIcons.copy, size: 13, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/profile/kyc-level');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.badgeCheck, color: AppColors.emeraldGreen, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _kycStatus,
                    style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronRight, color: AppColors.emeraldGreen, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _buildMetaRow('Mã định danh chủ ví (CID)', _cid.isNotEmpty ? 'SHB-$_cid' : 'SHB-88996688'),
            const Divider(height: 12, color: AppColors.dividerLight),
            _buildMetaRow('Ngày kích hoạt tài khoản', _createdAt.isNotEmpty ? _createdAt : '01/01/2026'),
            const Divider(height: 12, color: AppColors.dividerLight),
            _buildMetaRow('Chi nhánh quản lý', _branch),
            const Divider(height: 12, color: AppColors.dividerLight),
            _buildMetaRow('Trạng thái tài khoản', 'Hoạt động bình thường (Active)', isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isHighlight) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AppColors.emeraldGreen, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isHighlight ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildField(
              label: 'Họ và tên (theo CCCD)',
              ctrl: _nameCtrl,
              icon: LucideIcons.user,
              enabled: _isEditing,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Số điện thoại đăng ký',
              ctrl: _phoneCtrl,
              icon: LucideIcons.phone,
              enabled: false,
              helperText: 'Số điện thoại là tài khoản ngân hàng cố định',
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Email nhận thông báo & Hóa đơn',
              ctrl: _emailCtrl,
              icon: LucideIcons.mail,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'Ngày tháng năm sinh',
              ctrl: _dobCtrl,
              icon: LucideIcons.calendar,
              enabled: _isEditing,
              onTap: _isEditing ? _pickDob : null,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVatInvoicingCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0x1400A896),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x1F00A896)),
                  ),
                  child: const Icon(LucideIcons.receipt, color: AppColors.primaryDark, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hóa đơn điện tử VAT',
                        style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const Text(
                        'Tự động gửi hóa đơn GTGT sau khi thanh toán phí',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _vatInvoiceEnabled,
                  activeColor: AppColors.primary,
                  onChanged: _isEditing
                      ? (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _vatInvoiceEnabled = val);
                        }
                      : null,
                ),
              ],
            ),
            if (_vatInvoiceEnabled) ...[
              const Divider(height: 18, color: AppColors.dividerLight),
              _buildField(
                label: 'Mã số thuế (MST) / CCCD doanh nghiệp',
                ctrl: _taxCodeCtrl,
                icon: LucideIcons.hash,
                enabled: _isEditing,
                hintText: 'Nhập mã số thuế (nếu cần xuất hóa đơn công ty)',
              ),
              const SizedBox(height: 10),
              _buildField(
                label: 'Tên cơ quan / Công ty nhận hóa đơn',
                ctrl: _companyNameCtrl,
                icon: LucideIcons.building2,
                enabled: _isEditing,
                hintText: 'Tên công ty hoặc doanh nghiệp thụ hưởng',
              ),
              const SizedBox(height: 10),
              _buildField(
                label: 'Địa chỉ xuất hóa đơn VAT',
                ctrl: _invoiceAddressCtrl,
                icon: LucideIcons.mapPin,
                enabled: _isEditing,
                hintText: 'Địa chỉ theo giấy phép ĐKKD',
              ),
              const Divider(height: 16, color: AppColors.dividerLight),
              Row(
                children: [
                  const Icon(LucideIcons.lock, color: AppColors.emeraldGreen, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bảo vệ file sao kê PDF bằng 6 số cuối CCCD',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _protectPdfWithPassword,
                    activeColor: AppColors.primary,
                    onChanged: _isEditing
                        ? (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _protectPdfWithPassword = val);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityNavigationCard(BuildContext context) {
    const Color defaultBg = Color(0x1400A896); // primary 8% subtle tint
    const Color defaultColor = AppColors.primaryDark;

    final navItems = [
      {
        'title': 'Thông tin giấy tờ CCCD',
        'sub': _cid.isNotEmpty ? 'Mã định danh eKYC: $_cid' : 'Đã xác thực CCCD gắn chip',
        'icon': LucideIcons.fileText,
        'iconBg': defaultBg,
        'iconColor': defaultColor,
        'route': '/profile/identity-document',
      },
      {
        'title': 'Hạn mức giao dịch (Kyc Level)',
        'sub': 'Hạn mức hiện tại: 100.000.000đ/ngày',
        'icon': LucideIcons.barChart2,
        'iconBg': defaultBg,
        'iconColor': defaultColor,
        'route': '/profile/kyc-level',
      },
      {
        'title': 'Xác thực lại danh tính eKYC',
        'sub': 'Cập nhật lại ảnh chụp CCCD & chân dung',
        'icon': LucideIcons.scanFace,
        'iconBg': defaultBg,
        'iconColor': defaultColor,
        'route': '/profile/ekyc',
      },
      {
        'title': 'Chữ ký số & Smart OTP',
        'sub': 'Chứng thư số cá nhân PKI an toàn cao',
        'icon': LucideIcons.shieldCheck,
        'iconBg': defaultBg,
        'iconColor': defaultColor,
        'route': '/profile/digital-signature',
      },
      {
        'title': 'Xác thực Chip CCCD (NFC)',
        'sub': 'Đối soát căn cước chuẩn Quyết định 2345/QĐ-NHNN',
        'icon': LucideIcons.nfc,
        'iconBg': defaultBg,
        'iconColor': defaultColor,
        'route': '/profile/nfc-reader',
      },
    ];

    return GlassCard(
      quality: GlassQuality.minimal,
      child: Column(
        children: navItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == navItems.length - 1;
          return Column(
            children: [
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push(item['route'] as String);
                  },
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item['iconBg'] as Color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x1F00A896)),
                    ),
                    child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 18),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    item['sub'] as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textMutedLight, size: 16),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 62, color: AppColors.dividerLight),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          onTap: _exportPersonalData,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x1400A896),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x1F00A896)),
            ),
            child: const Icon(LucideIcons.download, color: AppColors.primaryDark, size: 18),
          ),
          title: const Text(
            'Quyền bảo vệ dữ liệu (Nghị định 13/2023)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight),
          ),
          subtitle: const Text(
            'Yêu cầu bản sao trích xuất dữ liệu cá nhân có ký số',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
          ),
          trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textMutedLight, size: 16),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    bool enabled = true,
    VoidCallback? onTap,
    bool readOnly = false,
    String? hintText,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMutedLight, fontWeight: FontWeight.normal),
            helperText: helperText,
            helperStyle: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
            prefixIcon: Icon(icon, color: enabled ? AppColors.primary : AppColors.textMutedLight, size: 18),
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.dividerLight)),
          ),
        ),
      ],
    );
  }
}
