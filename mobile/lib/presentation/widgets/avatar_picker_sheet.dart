import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SenBankPresetAvatar {
  final String id;
  final String title;
  final String badge;
  final String url;

  const SenBankPresetAvatar({
    required this.id,
    required this.title,
    required this.badge,
    required this.url,
  });
}

class AvatarPickerSheet extends StatefulWidget {
  final Function(File file) onImageFilePicked;
  final Function(String url, String title) onAvatarUrlSelected;
  final String? currentAvatarUrl;

  const AvatarPickerSheet({
    super.key,
    required this.onImageFilePicked,
    required this.onAvatarUrlSelected,
    this.currentAvatarUrl,
  });

  static const List<SenBankPresetAvatar> presets = [
    SenBankPresetAvatar(
      id: 'vip_1',
      title: 'Doanh Nhân VIP',
      badge: 'DIAMOND',
      url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_2',
      title: 'Chuyên Gia Tài Chính',
      badge: 'PLATINUM',
      url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_3',
      title: 'Sen Vàng Tinh Hoa',
      badge: 'PREMIER',
      url: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_4',
      title: 'Lãnh Đạo Cấp Cao',
      badge: 'EXECUTIVE',
      url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_5',
      title: 'Khởi Nghiệp Đổi Mới',
      badge: 'INNOVATOR',
      url: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_6',
      title: 'Kỹ Sư Công Nghệ',
      badge: 'TECH ELITE',
      url: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_7',
      title: 'Đại Sứ Thương Hiệu',
      badge: 'AMBASSADOR',
      url: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&fit=crop&q=80',
    ),
    SenBankPresetAvatar(
      id: 'vip_8',
      title: 'Cố Vấn Đầu Tư',
      badge: 'WEALTH',
      url: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400&fit=crop&q=80',
    ),
  ];

  static Future<void> show(
    BuildContext context, {
    required Function(File file) onImageFilePicked,
    required Function(String url, String title) onAvatarUrlSelected,
    String? currentAvatarUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerSheet(
        onImageFilePicked: onImageFilePicked,
        onAvatarUrlSelected: onAvatarUrlSelected,
        currentAvatarUrl: currentAvatarUrl,
      ),
    );
  }

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  final TextEditingController _urlCtrl = TextEditingController();
  bool _showUrlInput = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isProcessing = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked != null) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onImageFilePicked(File(picked.path));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryDark,
          content: Text('Vui lòng khởi động lại ứng dụng nếu nạp plugin camera mới: ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Không thể chọn ảnh: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _submitCustomUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Vui lòng nhập liên kết hình ảnh hợp lệ (http/https)'),
        ),
      );
      return;
    }
    Navigator.pop(context);
    widget.onAvatarUrlSelected(url, 'Tùy chỉnh');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thay Đổi Ảnh Đại Diện',
                    style: AppTypography.titleMedium(color: AppColors.primaryDark).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Chọn ảnh từ máy hoặc bộ sưu tập SenBank VIP',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Primary Actions: Camera & Gallery
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: CupertinoIcons.camera_fill,
                  label: 'Chụp ảnh mới',
                  subtitle: 'Máy ảnh',
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.bottomBarCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: CupertinoIcons.photo_fill,
                  label: 'Chọn từ thư viện',
                  subtitle: 'Album ảnh',
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider with label
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.borderLight)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'HOẶC CHỌN AVATAR SENBANK VIP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.borderLight)),
            ],
          ),

          const SizedBox(height: 14),

          // Preset Avatars Horizontal/Grid View
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AvatarPickerSheet.presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (ctx, index) {
                final item = AvatarPickerSheet.presets[index];
                final isSelected = widget.currentAvatarUrl == item.url;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onAvatarUrlSelected(item.url, item.title);
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.emeraldGreen : AppColors.primaryLight,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                item.url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: AppColors.dividerLight,
                                    child: const Center(child: CupertinoActivityIndicator(radius: 8)),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Icon(
                                  CupertinoIcons.person_crop_circle_fill,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.emeraldGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(CupertinoIcons.checkmark, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.emeraldGreen : AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // URL Input Toggle
          InkWell(
            onTap: () => setState(() => _showUrlInput = !_showUrlInput),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _showUrlInput ? CupertinoIcons.arrow_up : CupertinoIcons.link,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showUrlInput ? 'Ẩn nhập liên kết URL' : 'Dán đường dẫn ảnh trực tiếp (URL)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showUrlInput) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/avatar.jpg',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitCustomUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Áp dụng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
