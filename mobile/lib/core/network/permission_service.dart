import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Quan ly xin quyen runtime Camera va Notifications cho Android 6+ va iOS.
/// - Camera: can cho QR scanning va eKYC
/// - Notifications: Android 13+ (API 33) bat buoc runtime request
/// - Photos: Cho phep chon anh QR tu thu vien
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Xin tat ca quyen can thiet ngay khi app khoi dong.
  Future<Map<Permission, PermissionStatus>> requestAllAppPermissions() async {
    final permsToRequest = <Permission>[];

    // CAMERA: can cho QR scanning va eKYC
    permsToRequest.add(Permission.camera);

    // NOTIFICATIONS: Android 13+ (API 33) bat buoc runtime request
    if (Platform.isAndroid) {
      permsToRequest.add(Permission.notification);
    }

    // READ_MEDIA_IMAGES (Android 13+) hoac READ_EXTERNAL_STORAGE (<=12)
    // permission_handler tu dong map sang dung permission tuong ung
    if (Platform.isAndroid) {
      permsToRequest.add(Permission.photos);
    }

    // iOS gallery access
    if (Platform.isIOS) {
      permsToRequest.add(Permission.photos);
    }

    final statuses = await permsToRequest.request();
    for (final perm in statuses.keys) {
      debugPrint('[Permission] $perm: ${statuses[perm]}');
    }
    return statuses;
  }

  /// Xin quyen Camera don le - goi ngay truoc khi mo ScanQRScreen.
  Future<bool> requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Quyen Camera bi tu choi',
          message:
              'Sen Hong can quyen Camera de quet ma QR va xac thuc eKYC. '
              'Vui long vao Cai dat > Sen Hong > Quyen > Camera va bat len.',
        );
      }
      return false;
    }

    return status.isGranted;
  }

  /// Xin quyen Notification don le - goi sau khi dang nhap thanh cong.
  Future<bool> requestNotificationPermission(BuildContext context) async {
    var status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Quyen Thong Bao bi tu choi',
          message:
              'Ban se khong nhan duoc thong bao bien dong so du va giao dich. '
              'Vui long vao Cai dat > Sen Hong > Thong bao va bat len.',
        );
      }
      return false;
    }

    debugPrint('[Permission] Notification: $status');
    return status.isGranted;
  }

  Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bo qua'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Mo Cai Dat'),
          ),
        ],
      ),
    );
  }
}
