import 'package:tradex/models/kyc_model.dart';

class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String avatarUrl;
  final String country;
  final String referralCode;
  final int referralCount;
  final double referralEarnings;
  final KycStatus kycStatus;
  final String tier;
  final DateTime joinedAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool twoFactorEnabled;
  final bool biometricsEnabled;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    this.avatarUrl = '',
    this.country = 'Bangladesh',
    required this.referralCode,
    this.referralCount = 14,
    this.referralEarnings = 1450.00,
    this.kycStatus = KycStatus.verified,
    this.tier = 'VIP Gold',
    required this.joinedAt,
    this.isEmailVerified = true,
    this.isPhoneVerified = true,
    this.twoFactorEnabled = true,
    this.biometricsEnabled = true,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? avatarUrl,
    String? country,
    String? referralCode,
    int? referralCount,
    double? referralEarnings,
    KycStatus? kycStatus,
    String? tier,
    DateTime? joinedAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? twoFactorEnabled,
    bool? biometricsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      referralCode: referralCode ?? this.referralCode,
      referralCount: referralCount ?? this.referralCount,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      kycStatus: kycStatus ?? this.kycStatus,
      tier: tier ?? this.tier,
      joinedAt: joinedAt ?? this.joinedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    );
  }

  static UserModel sampleUser = UserModel(
    id: 'usr_948271',
    fullName: 'Shek Ahmmed',
    username: 'shek_vip',
    email: 'shekahmmed@email.com',
    phone: '+880 1712-345678',
    avatarUrl: '',
    country: 'Bangladesh',
    referralCode: 'TRADEX777',
    referralCount: 18,
    referralEarnings: 1850.00,
    kycStatus: KycStatus.verified,
    tier: 'VIP Platinum',
    joinedAt: DateTime(2026, 1, 15),
    isEmailVerified: true,
    isPhoneVerified: true,
    twoFactorEnabled: true,
    biometricsEnabled: true,
  );
}
