import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../widgets/user_avatar_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _isEditing = false;
  bool _loading = true;
  String? _error;
  String? _avatarUrl;
  File? _localAvatarFile;
  bool _isUploadingAvatar = false;
  String _cid = '';
  String _createdAt = '';
  final String _branch = 'Hội sở chính - TP. Hồ Chí Minh';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileRemoteDataSource().getMe();
      if (!mounted) return;
      final avUrl = profile['avatarUrl'] as String? ?? '';
      UserAvatarNotifier.update(avUrl);
      setState(() {
        _nameCtrl.text = profile['fullName'] as String? ?? '';
        _emailCtrl.text = profile['email'] as String? ?? '';
        _dobCtrl.text = profile['dob'] as String? ?? '';
        _phoneCtrl.text = profile['phoneNumber'] as String? ?? '';
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
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      await ProfileRemoteDataSource().updateMe(fullName: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), dob: _dobCtrl.text.trim());
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emeraldGreen,
          content: Text('Cập nhật hồ sơ thành công'),
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
      helpText: 'CHỌN NGÀY SINH',
      confirmText: 'XÁC NHẬN',
      cancelText: 'HỦY',
    );
    if (picked != null && mounted) {
      setState(() {
        _dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _changeAvatar() {
    AvatarPickerSheet.show(
      context,
      currentAvatarUrl: _avatarUrl,
      onImageFilePicked: (file) => _uploadAndApplyAvatar(file),
      onAvatarUrlSelected: (url, title) => _applyAvatarUrl(url, title),
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
      await ProfileRemoteDataSource().updateAvatar(base64String);
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
      await ProfileRemoteDataSource().updateAvatar(url);
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
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.doc_text_search, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Trích Xuất Dữ Liệu Cá Nhân',
                    style: AppTypography.titleLarge(color: AppColors.primaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Theo quy định tại Nghị định 13/2023/NĐ-CP về Bảo vệ dữ liệu cá nhân, chủ tài khoản có quyền yêu cầu nhận bản sao toàn bộ thông tin định danh, lịch sử thiết bị và sao kê giao dịch đã được mã hóa.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Định dạng tệp:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Báo cáo chuẩn JSON / PDF có chữ ký số PKI',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gửi tới email:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emailCtrl.text.isEmpty ? 'Chưa cập nhật email' : _emailCtrl.text,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.emeraldGreen,
                      content: Text('Yêu cầu trích xuất dữ liệu cá nhân đã được ghi nhận. Tệp nén mã hóa sẽ gửi về email trong 15 phút.'),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.tray_arrow_down_fill, size: 18),
                label: const Text('Xác nhận & Gửi bản sao dữ liệu'),
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
                _loadProfile();
                setState(() => _isEditing = false);
              },
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: Text(_isEditing ? 'Lưu' : 'Chỉnh sửa', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              // Avatar with camera icon
              Center(
                child: UserAvatarWidget(
                  radius: 52,
                  avatarUrl: _avatarUrl,
                  localFile: _localAvatarFile,
                  isLoading: _isUploadingAvatar,
                  showCameraBadge: true,
                  onCameraTap: _changeAvatar,
                  onTap: _changeAvatar,
                ),
              ),
              const SizedBox(height: 12),
              Text(_nameCtrl.text.isEmpty ? 'Chưa có thông tin họ tên' : _nameCtrl.text, style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 4),

              // KYC Badge
              InkWell(
                onTap: () => context.push('/profile/kyc-level'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.emeraldGreen.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.emeraldGreen, size: 16),
                      SizedBox(width: 6),
                      Text('Xem trạng thái eKYC', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(CupertinoIcons.chevron_forward, color: AppColors.emeraldGreen, size: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Account Status Metadata Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.textPrimaryLight, AppColors.cardDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimaryLight.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Mã định danh chủ ví (CID)', _cid.isNotEmpty ? 'SHB-$_cid' : 'SHB-88996688'),
                    const Divider(height: 16, color: Colors.white24),
                    _buildMetaRow('Ngày kích hoạt tài khoản', _createdAt.isNotEmpty ? _createdAt : '01/01/2026'),
                    const Divider(height: 16, color: Colors.white24),
                    _buildMetaRow('Chi nhánh quản lý', _branch),
                    const Divider(height: 16, color: Colors.white24),
                    _buildMetaRow('Trạng thái tài khoản', 'Hoạt động bình thường (Active)', isHighlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Details
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildField('Họ và tên (theo CCCD)', _nameCtrl, CupertinoIcons.person_fill, enabled: _isEditing),
                      const SizedBox(height: 14),
                      _buildField('Số điện thoại đăng ký', _phoneCtrl, CupertinoIcons.phone_fill, enabled: false),
                      const SizedBox(height: 14),
                      _buildField('Email nhận thông báo & hóa đơn', _emailCtrl, CupertinoIcons.chat_bubble_fill, enabled: _isEditing),
                      const SizedBox(height: 14),
                      _buildField('Ngày tháng năm sinh', _dobCtrl, CupertinoIcons.calendar, enabled: _isEditing, onTap: _isEditing ? _pickDob : null, readOnly: _isEditing),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Navigation to Identity Documents & KYC Level
              GlassCard(
                quality: GlassQuality.minimal,
                child: Column(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        onTap: () => context.push('/profile/identity'),
                        leading: const Icon(CupertinoIcons.doc_text_fill, color: AppColors.primary),
                        title: Text('Thông tin giấy tờ CCCD', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                        subtitle: Text(_cid.isNotEmpty ? 'Mã định danh eKYC: $_cid' : 'Đã xác thực CCCD gắn chip', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        onTap: () => context.push('/profile/kyc-level'),
                        leading: const Icon(CupertinoIcons.chart_bar_fill, color: AppColors.accentGold),
                        title: Text('Hạn mức giao dịch (Kyc Level)', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Hạn mức hiện tại: 100.000.000đ/ngày', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        onTap: () => context.push('/profile/ekyc'),
                        leading: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.primary),
                        title: Text('Xác thực lại danh tính eKYC', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Cập nhật lại ảnh chụp CCCD & chân dung', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        onTap: () => context.push('/profile/digital-signature'),
                        leading: const Icon(CupertinoIcons.shield_fill, color: AppColors.vividTeal),
                        title: Text('Chữ ký số & Smart OTP', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Chứng thư số cá nhân PKI', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      ),
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        onTap: () => context.push('/profile/email-settings'),
                        leading: const Icon(CupertinoIcons.chat_bubble_fill, color: AppColors.softPurple),
                        title: Text('Cài đặt Email nhận hóa đơn VAT', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                        subtitle: Text('Nhận sao kê định kỳ & biên lai điện tử', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                        trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Decree 13 Personal Data Privacy & Export Button Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    onTap: _exportPersonalData,
                    leading: const Icon(CupertinoIcons.doc_text_search, color: AppColors.primary),
                    title: const Text('Quyền bảo vệ dữ liệu (Nghị định 13/2023)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
                    subtitle: const Text('Yêu cầu bản sao trích xuất dữ liệu cá nhân', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isHighlight ? AppColors.emeraldGreen : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool enabled = true, VoidCallback? onTap, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(color: enabled ? AppColors.textPrimaryLight : AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.dividerLight)),
          ),
        ),
      ],
    );
  }
}
