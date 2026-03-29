// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MembershipTierModel _$MembershipTierModelFromJson(Map<String, dynamic> json) =>
    MembershipTierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      annualPrice: (json['annualPrice'] as num).toDouble(),
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
      maxCoursesPerMonth: (json['maxCoursesPerMonth'] as num?)?.toInt(),
      hasAdvancedAnalytics: json['hasAdvancedAnalytics'] as bool? ?? false,
      hasPrioritySupport: json['hasPrioritySupport'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MembershipTierModelToJson(
        MembershipTierModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'monthlyPrice': instance.monthlyPrice,
      'annualPrice': instance.annualPrice,
      'features': instance.features,
      'maxCoursesPerMonth': instance.maxCoursesPerMonth,
      'hasAdvancedAnalytics': instance.hasAdvancedAnalytics,
      'hasPrioritySupport': instance.hasPrioritySupport,
      'isFeatured': instance.isFeatured,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String?,
      membershipTierId: json['membershipTierId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      paymentMethod: json['paymentMethod'] as String,
      transactionId: json['transactionId'] as String?,
      reference: json['reference'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'courseId': instance.courseId,
      'membershipTierId': instance.membershipTierId,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': _$PaymentStatusEnumMap[instance.status]!,
      'paymentMethod': instance.paymentMethod,
      'transactionId': instance.transactionId,
      'reference': instance.reference,
      'receiptUrl': instance.receiptUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.cancelled: 'cancelled',
};

PaymentInitiation _$PaymentInitiationFromJson(Map<String, dynamic> json) =>
    PaymentInitiation(
      userId: json['userId'] as String,
      courseId: json['courseId'] as String?,
      membershipTierId: json['membershipTierId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['paymentMethod'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );

Map<String, dynamic> _$PaymentInitiationToJson(PaymentInitiation instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'courseId': instance.courseId,
      'membershipTierId': instance.membershipTierId,
      'amount': instance.amount,
      'currency': instance.currency,
      'paymentMethod': instance.paymentMethod,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
    };

FlutterwaveInitResponse _$FlutterwaveInitResponseFromJson(
        Map<String, dynamic> json) =>
    FlutterwaveInitResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      link: json['link'] as String?,
      accessCode: json['accessCode'] as String?,
    );

Map<String, dynamic> _$FlutterwaveInitResponseToJson(
        FlutterwaveInitResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'link': instance.link,
      'accessCode': instance.accessCode,
    };

UserMembership _$UserMembershipFromJson(Map<String, dynamic> json) =>
    UserMembership(
      id: json['id'] as String,
      userId: json['userId'] as String,
      membershipTierId: json['membershipTierId'] as String,
      membershipTierName: json['membershipTierName'] as String?,
      status: json['status'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      billingCycle: json['billingCycle'] as String,
    );

Map<String, dynamic> _$UserMembershipToJson(UserMembership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'membershipTierId': instance.membershipTierId,
      'membershipTierName': instance.membershipTierName,
      'status': instance.status,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'expiryDate': instance.expiryDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'billingCycle': instance.billingCycle,
    };
