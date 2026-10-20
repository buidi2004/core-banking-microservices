import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

/// Hiển thị dialog chuẩn khi gọi endpoint BE chưa có sẵn.
/// Sử dụng chung cho toàn bộ mobile; Con 3 import từ file này.
Future<void> showFeatureUnavailable(
  BuildContext context, {
  required String feature,
  required String reason,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              CupertinoIcons.info_circle_fill,
              color: AppColors.warningText,
              size: 26,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tính năng chưa sẵn sàng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.warningText,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
            },
            child: const Text('Đã hiểu',
                style: TextStyle(color: AppColors.textPrimaryLight)),
          ),
        ],
      ),
    ),
  );
}