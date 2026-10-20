import 'package:flutter/material.dart';
import 'confirm_transfer_screen.dart';

/// MOB-019: Hợp nhất luồng xác nhận chuyển tiền.
/// Màn hình này chuyển tiếp sang [ConfirmTransferScreen] duy nhất.
class TransferConfirmScreen extends StatelessWidget {
  final String recipient;
  final double amount;
  final String note;

  const TransferConfirmScreen({
    super.key,
    required this.recipient,
    required this.amount,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmTransferScreen(
      recipient: recipient,
      amount: amount,
      note: note,
    );
  }
}
