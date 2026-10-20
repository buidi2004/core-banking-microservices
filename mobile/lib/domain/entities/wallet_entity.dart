import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String walletId;
  final String userId;
  final double balance;
  final String currency;
  final String status;
  final double dailyLimit;
  final double dailySpent;

  const WalletEntity({
    required this.walletId,
    required this.userId,
    required this.balance,
    this.currency = 'VND',
    this.status = 'ACTIVE',
    this.dailyLimit = 100000000,
    this.dailySpent = 0,
  });

  WalletEntity copyWith({
    String? walletId,
    String? userId,
    double? balance,
    String? currency,
    String? status,
    double? dailyLimit,
    double? dailySpent,
  }) {
    return WalletEntity(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      dailySpent: dailySpent ?? this.dailySpent,
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
      ];
}
