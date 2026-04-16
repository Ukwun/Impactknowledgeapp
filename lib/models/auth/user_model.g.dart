// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      state: json['state'] as String?,
      institution: json['institution'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']),
      emailVerified: json['emailVerified'] as bool? ?? false,
      accountStatus: json['accountStatus'] as String?,
      countryOfResidence: json['countryOfResidence'] as String?,
      professionOrStudyArea: json['professionOrStudyArea'] as String?,
      reasonForJoining: json['reasonForJoining'] as String?,
      membershipTierId: json['membershipTierId'] as String?,
      referralCode: json['referralCode'] as String?,
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'fullName': instance.fullName,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phone': instance.phone,
      'state': instance.state,
      'institution': instance.institution,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'role': _$UserRoleEnumMap[instance.role],
      'emailVerified': instance.emailVerified,
      'accountStatus': instance.accountStatus,
      'countryOfResidence': instance.countryOfResidence,
      'professionOrStudyArea': instance.professionOrStudyArea,
      'reasonForJoining': instance.reasonForJoining,
      'membershipTierId': instance.membershipTierId,
      'referralCode': instance.referralCode,
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.parent: 'parent',
  UserRole.facilitator: 'facilitator',
  UserRole.instructor: 'instructor',
  UserRole.schoolAdmin: 'school_admin',
  UserRole.uniMember: 'uni_member',
  UserRole.circleMember: 'circle_member',
  UserRole.mentor: 'mentor',
  UserRole.admin: 'admin',
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

SignupRequest _$SignupRequestFromJson(Map<String, dynamic> json) =>
    SignupRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      state: json['state'] as String?,
      institution: json['institution'] as String?,
      countryOfResidence: json['countryOfResidence'] as String?,
      professionOrStudyArea: json['professionOrStudyArea'] as String?,
      reasonForJoining: json['reasonForJoining'] as String?,
    );

Map<String, dynamic> _$SignupRequestToJson(SignupRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phone': instance.phone,
      'role': instance.role,
      'state': instance.state,
      'institution': instance.institution,
      'countryOfResidence': instance.countryOfResidence,
      'professionOrStudyArea': instance.professionOrStudyArea,
      'reasonForJoining': instance.reasonForJoining,
    };
