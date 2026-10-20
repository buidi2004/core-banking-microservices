import 'package:equatable/equatable.dart';

enum TransactionType {
  transfer,
  deposit,
  withdraw,
  bill,
  topup,
}

enum TransactionStatus {
  success,
  pending,
  failed,
}

class TransactionEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? recipientName;
  final String? recipientPhone;
  final String? bankName;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    this.currency = 'VND',
    required this.type,
    required this.status,
    required this.timestamp,
    this.recipientName,
    this.recipientPhone,
    this.bankName,
  });

  bool get isPositive => type == TransactionType.deposit;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        amount,
        currency,
        type,
        status,
        timestamp,
        recipientName,
        recipientPhone,
        bankName,
      ];
}
