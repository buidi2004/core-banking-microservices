import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final int kycLevel;
  final bool hasPin;
  final bool biometricEnabled;

  const UserEntity({
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.kycLevel = 1,
    this.hasPin = false,
    this.biometricEnabled = false,
  });

  @override
  List<Object?> get props => [
        userId,
        phoneNumber,
        fullName,
        email,
        avatarUrl,
        kycLevel,
        hasPin,
        biometricEnabled,
      ];
}
