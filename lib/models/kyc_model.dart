import 'package:flutter/material.dart';

enum KycStatus {
  notSubmitted,
  pending,
  verified,
  rejected,
}

enum DocumentType {
  nid,
  passport,
  drivingLicense,
}

class KycModel {
  final KycStatus status;
  final DocumentType? documentType;
  final String? documentNumber;
  final String? fullName;
  final String? dateOfBirth;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? selfieImageUrl;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const KycModel({
    this.status = KycStatus.notSubmitted,
    this.documentType,
    this.documentNumber,
    this.fullName,
    this.dateOfBirth,
    this.frontImageUrl,
    this.backImageUrl,
    this.selfieImageUrl,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  bool get isVerified => status == KycStatus.verified;
  bool get isPending => status == KycStatus.pending;
  bool get isRejected => status == KycStatus.rejected;
  bool get isNotSubmitted => status == KycStatus.notSubmitted;

  String get statusLabel {
    switch (status) {
      case KycStatus.verified:
        return 'VERIFIED';
      case KycStatus.pending:
        return 'PENDING REVIEW';
      case KycStatus.rejected:
        return 'REJECTED';
      case KycStatus.notSubmitted:
        return 'NOT SUBMITTED';
    }
  }

  Color get statusColor {
    switch (status) {
      case KycStatus.verified:
        return const Color(0xFF10B981);
      case KycStatus.pending:
        return const Color(0xFFF59E0B);
      case KycStatus.rejected:
        return const Color(0xFFEF4444);
      case KycStatus.notSubmitted:
        return const Color(0xFF8E95A5);
    }
  }

  KycModel copyWith({
    KycStatus? status,
    DocumentType? documentType,
    String? documentNumber,
    String? fullName,
    String? dateOfBirth,
    String? frontImageUrl,
    String? backImageUrl,
    String? selfieImageUrl,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
  }) {
    return KycModel(
      status: status ?? this.status,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      frontImageUrl: frontImageUrl ?? this.frontImageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
