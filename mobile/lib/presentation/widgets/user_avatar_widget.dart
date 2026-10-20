import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/app_secure_storage.dart';
import '../../core/theme/app_colors.dart';

/// Global notifier to keep user avatar in sync across all screens
class UserAvatarNotifier {
  static final ValueNotifier<String?> avatarNotifier = ValueNotifier<String?>(null);
  static const _storage = AppSecureStorage.instance;

  static void update(String? url) {
    avatarNotifier.value = url;
    if (url != null && url.isNotEmpty) {
      AppSecureStorage.safeWrite(_storage, key: AppConstants.keyAvatarUrl, value: url);
    }
  }

  static Future<void> init() async {
    try {
      final cached = await AppSecureStorage.safeRead(_storage, key: AppConstants.keyAvatarUrl);
      if (cached != null && cached.isNotEmpty) {
        avatarNotifier.value = cached;
      }
    } catch (_) {}
  }
}

/// Unified, high-fidelity avatar widget for SenBank
class UserAvatarWidget extends StatelessWidget {
  final double radius;
  final String? avatarUrl;
  final File? localFile;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final bool showCameraBadge;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onCameraTap;
  final Color? backgroundColor;

  const UserAvatarWidget({
    super.key,
    this.radius = 24,
    this.avatarUrl,
    this.localFile,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showCameraBadge = false,
    this.isLoading = false,
    this.onTap,
    this.onCameraTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: UserAvatarNotifier.avatarNotifier,
      builder: (context, globalAvatar, _) {
        final effectiveUrl = avatarUrl ?? globalAvatar;

        final avatarBox = Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(
                    color: borderColor ?? AppColors.primaryLight.withOpacity(0.8),
                    width: borderWidth,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.bottomBarGlow.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: backgroundColor ?? Colors.white,
              child: _buildAvatarImage(effectiveUrl),
            ),
          ),
        );

        Widget content;
        if (showCameraBadge || isLoading) {
          content = Stack(
            clipBehavior: Clip.none,
            children: [
              avatarBox,
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                    ),
                    child: const Center(
                      child: CupertinoActivityIndicator(color: Colors.white),
                    ),
                  ),
                ),
              if (showCameraBadge)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onCameraTap ?? onTap,
                    child: Container(
                      padding: EdgeInsets.all(radius > 36 ? 8 : 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.camera_fill,
                        size: radius > 36 ? 16 : 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          content = avatarBox;
        }

        if (onTap != null) {
          return GestureDetector(
            onTap: onTap,
            child: content,
          );
        }

        return content;
      },
    );
  }

  Widget _buildAvatarImage(String? url) {
    if (localFile != null) {
      return Image.file(
        localFile!,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          final base64Data = url.contains(',') ? url.split(',').last : url;
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            errorBuilder: (_, __, ___) => _buildFallback(),
          );
        } catch (_) {
          return _buildFallback();
        }
      }

      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.dividerLight,
              child: const Center(
                child: CupertinoActivityIndicator(radius: 10),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      }

      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      }
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.bottomBarCyan.withOpacity(0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.person_crop_circle_fill,
          size: radius * 1.1,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
