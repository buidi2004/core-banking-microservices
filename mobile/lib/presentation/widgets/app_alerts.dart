import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

/// Các phân loại mức độ cảnh báo đạt chuẩn ngân hàng số
enum AlertType { warning, error, success, info }

/// Hệ thống thông báo & cảnh báo chuẩn UI/UX ngân hàng số cao cấp cho SenBank
class AppAlerts {
  /// Hiển thị Toast nổi (Floating Toast) bo góc 16px với màu sắc Tailwind/Apple HIG chuẩn
  static void showToast(
    BuildContext context, {
    required String message,
    String? title,
    AlertType type = AlertType.warning,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    // 1. Phản hồi xúc giác (Haptic) tương thích theo mức độ
    switch (type) {
      case AlertType.warning:
        HapticFeedback.vibrate();
        break;
      case AlertType.error:
        HapticFeedback.heavyImpact();
        break;
      case AlertType.success:
        HapticFeedback.lightImpact();
        break;
      case AlertType.info:
        HapticFeedback.selectionClick();
        break;
    }

    // 2. Phối màu chuẩn hệ thống
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;

    switch (type) {
      case AlertType.warning:
        bgColor = AppColors.warningBg;
        borderColor = AppColors.warningBorder;
        textColor = AppColors.warningText;
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      case AlertType.error:
        bgColor = AppColors.errorBg;
        borderColor = AppColors.errorBorder;
        textColor = AppColors.errorText;
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case AlertType.success:
        bgColor = AppColors.successBg;
        borderColor = AppColors.successBorder;
        textColor = AppColors.successText;
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case AlertType.info:
        bgColor = AppColors.infoBg;
        borderColor = AppColors.infoBorder;
        textColor = AppColors.infoText;
        icon = CupertinoIcons.info_circle_fill;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: textColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: textColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty) ...[
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textColor.withOpacity(0.95),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Cảnh báo chú ý (Warning Toast)
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showToast(
      context,
      message: message,
      title: title ?? 'Lưu ý',
      type: AlertType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Báo lỗi giao dịch (Error Toast)
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showToast(
      context,
      message: message,
      title: title ?? 'Đã xảy ra lỗi',
      type: AlertType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Thông báo thành công (Success Toast)
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showToast(
      context,
      message: message,
      title: title ?? 'Thành công',
      type: AlertType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Thông báo thông tin (Info Toast)
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showToast(
      context,
      message: message,
      title: title,
      type: AlertType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hộp thoại Cảnh Báo An Ninh / Xác Nhận Giao Dịch Chuẩn UI/UX Ngân Hàng
  static Future<bool> showSecurityConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? subMessage,
    String confirmText = 'Xác nhận',
    String cancelText = 'Đóng',
    bool isDanger = false,
    IconData icon = CupertinoIcons.lock_shield_fill,
  }) async {
    HapticFeedback.mediumImpact();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => PopScope(
        canPop: true,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDanger ? AppColors.errorBg : AppColors.warningBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDanger ? AppColors.errorBorder : AppColors.warningBorder),
                ),
                child: Icon(
                  icon,
                  color: isDanger ? AppColors.errorText : AppColors.warningText,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.45,
                ),
              ),
              if (subMessage != null && subMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDanger ? AppColors.errorBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDanger ? AppColors.errorBorder : AppColors.warningBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isDanger ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.shield_lefthalf_fill,
                        color: isDanger ? AppColors.errorText : AppColors.warningText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDanger ? AppColors.errorText : AppColors.warningText,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                if (cancelText.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (cancelText.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDanger ? AppColors.error : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}

/// Banner Cảnh Báo Trực Quan trong các biểu mẫu nhập liệu
class InlineWarningBanner extends StatelessWidget {
  final String message;
  final String? title;
  final AlertType type;
  final VoidCallback? onClose;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry margin;

  const InlineWarningBanner({
    super.key,
    required this.message,
    this.title,
    this.type = AlertType.warning,
    this.onClose,
    this.actionLabel,
    this.onAction,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;

    switch (type) {
      case AlertType.warning:
        bgColor = AppColors.warningBg;
        borderColor = AppColors.warningBorder;
        textColor = AppColors.warningText;
        icon = CupertinoIcons.lock_shield_fill;
        break;
      case AlertType.error:
        bgColor = AppColors.errorBg;
        borderColor = AppColors.errorBorder;
        textColor = AppColors.errorText;
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case AlertType.success:
        bgColor = AppColors.successBg;
        borderColor = AppColors.successBorder;
        textColor = AppColors.successText;
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case AlertType.info:
        bgColor = AppColors.infoBg;
        borderColor = AppColors.infoBorder;
        textColor = AppColors.infoText;
        icon = CupertinoIcons.info_circle_fill;
        break;
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textPrimaryLight,
                    height: 1.35,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppColors.textSecondaryLight,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
