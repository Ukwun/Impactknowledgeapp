import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum UserRole {
  @JsonValue('student')
  student,
  @JsonValue('parent')
  parent,
  @JsonValue('facilitator')
  facilitator,
  @JsonValue('instructor')
  instructor,
  @JsonValue('school_admin')
  schoolAdmin,
  @JsonValue('uni_member')
  uniMember,
  @JsonValue('circle_member')
  circleMember,
  @JsonValue('mentor')
  mentor,
  @JsonValue('admin')
  admin,
}

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? state;
  final String? institution;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserRole? role;
  final bool emailVerified;
  final String? accountStatus; // 'active', 'suspended', 'deleted'
  final String? countryOfResidence;
  final String? professionOrStudyArea;
  final String? reasonForJoining;
  final String? membershipTierId;
  final String? referralCode;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.phone,
    this.state,
    this.institution,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.role,
    this.emailVerified = false,
    this.accountStatus,
    this.countryOfResidence,
    this.professionOrStudyArea,
    this.reasonForJoining,
    this.membershipTierId,
    this.referralCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, fullName: $fullName, role: $role)';
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserProfile user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class SignupRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? role;
  final String? state;
  final String? institution;
  final String? countryOfResidence;
  final String? professionOrStudyArea;
  final String? reasonForJoining;

  const SignupRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.role,
    this.state,
    this.institution,
    this.countryOfResidence,
    this.professionOrStudyArea,
    this.reasonForJoining,
  });

  factory SignupRequest.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SignupRequestToJson(this);
}
