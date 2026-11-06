import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String walletId;
  final String userId;
  final double balance;
  final String currency;
  final String status;
  final double dailyLimit;
  final double dailySpent;
  /// Hạn mức thấu chi cấp cho ví (tính năng 4.1). 0 = không thấu chi.
  final double overdraftLimit;

  const WalletEntity({
    required this.walletId,
    required this.userId,
    required this.balance,
    this.currency = 'VND',
    this.status = 'ACTIVE',
    this.dailyLimit = 100000000,
    this.dailySpent = 0,
    this.overdraftLimit = 0,
  });

  /// Số dư khả dụng bao gồm hạn mức thấu chi: balance + overdraftLimit.
  double get availableBalance => balance + overdraftLimit;

  WalletEntity copyWith({
    String? walletId,
    String? userId,
    double? balance,
    String? currency,
    String? status,
    double? dailyLimit,
    double? dailySpent,
    double? overdraftLimit,
  }) {
    return WalletEntity(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      dailySpent: dailySpent ?? this.dailySpent,
      overdraftLimit: overdraftLimit ?? this.overdraftLimit,
    );
  }

  @override
  List<Object?> get props => [
        walletId,
        userId,
        balance,
        currency,
        status,
        dailyLimit,
        dailySpent,
        overdraftLimit,
      ];
}
