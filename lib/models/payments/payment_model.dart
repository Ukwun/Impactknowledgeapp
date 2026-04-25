import 'package:json_annotation/json_annotation.dart';

part 'payment_model.g.dart';

enum PaymentStatus { pending, completed, failed, cancelled }

enum MembershipTier { free, starter, pro, premium }

@JsonSerializable()
class MembershipTierModel {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;
  final int? maxCoursesPerMonth;
  final bool hasAdvancedAnalytics;
  final bool hasPrioritySupport;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  MembershipTierModel({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
    this.maxCoursesPerMonth,
    this.hasAdvancedAnalytics = false,
    this.hasPrioritySupport = false,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MembershipTierModel.fromJson(Map<String, dynamic> json) =>
      _$MembershipTierModelFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipTierModelToJson(this);
}

@JsonSerializable()
class Payment {
  final String id;
  final String userId;
  final String? courseId;
  final String? membershipTierId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String
  paymentMethod; // 'stripe', 'bank_transfer', or other backend-defined method
  final String? transactionId;
  final String? reference;
  final String? receiptUrl;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.userId,
    this.courseId,
    this.membershipTierId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.reference,
    this.receiptUrl,
    required this.createdAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

@JsonSerializable()
class PaymentInitiation {
  final String userId;
  final String? courseId;
  final String? membershipTierId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String? email;
  final String? phoneNumber;

  PaymentInitiation({
    required this.userId,
    this.courseId,
    this.membershipTierId,
    required this.amount,
    this.currency = 'USD',
    required this.paymentMethod,
    this.email,
    this.phoneNumber,
  });

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) =>
      _$PaymentInitiationFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentInitiationToJson(this);
}

@JsonSerializable()
class FlutterwaveInitResponse {
  final bool status;
  final String message;
  final String? link;
  final String? accessCode;

  FlutterwaveInitResponse({
    required this.status,
    required this.message,
    this.link,
    this.accessCode,
  });

  factory FlutterwaveInitResponse.fromJson(Map<String, dynamic> json) =>
      _$FlutterwaveInitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FlutterwaveInitResponseToJson(this);
}

@JsonSerializable()
class UserMembership {
  final String id;
  final String userId;
  final String membershipTierId;
  final String membershipTierName; // Alias for tier name
  final String status; // 'active', 'cancelled', 'expired'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime expiryDate; // Alias for endDate
  final DateTime createdAt;
  final DateTime updatedAt;
  final String billingCycle; // 'monthly', 'annual'

  UserMembership({
    required this.id,
    required this.userId,
    required this.membershipTierId,
    String? membershipTierName,
    required this.status,
    required this.startDate,
    required this.endDate,
    DateTime? expiryDate,
    required this.createdAt,
    required this.updatedAt,
    required this.billingCycle,
  }) : membershipTierName = membershipTierName ?? '',
       expiryDate = expiryDate ?? endDate;

  factory UserMembership.fromJson(Map<String, dynamic> json) =>
      _$UserMembershipFromJson(json);

  Map<String, dynamic> toJson() => _$UserMembershipToJson(this);
}
