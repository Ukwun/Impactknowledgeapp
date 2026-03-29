import '../models/auth/user_model.dart';

enum DashboardExperience {
  learner,
  parent,
  facilitator,
  schoolAdmin,
  mentor,
  circleMember,
  uniMember,
  admin,
}

class RoleDashboardResolver {
  static DashboardExperience resolve(UserRole? role) {
    if (role == null) {
      return DashboardExperience.learner;
    }

    switch (role) {
      case UserRole.student:
      case UserRole.instructor:
        return DashboardExperience.learner;
      case UserRole.parent:
        return DashboardExperience.parent;
      case UserRole.facilitator:
        return DashboardExperience.facilitator;
      case UserRole.schoolAdmin:
        return DashboardExperience.schoolAdmin;
      case UserRole.mentor:
        return DashboardExperience.mentor;
      case UserRole.circleMember:
        return DashboardExperience.circleMember;
      case UserRole.uniMember:
        return DashboardExperience.uniMember;
      case UserRole.admin:
        return DashboardExperience.admin;
    }
  }

  static bool usesLearnerDashboard(UserRole? role) {
    return resolve(role) == DashboardExperience.learner;
  }

  static String toWebRoleKey(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
      case UserRole.facilitator:
      case UserRole.instructor:
        return 'facilitator';
      case UserRole.schoolAdmin:
        return 'school_admin';
      case UserRole.uniMember:
        return 'uni_member';
      case UserRole.circleMember:
        return 'circle_member';
      case UserRole.mentor:
        return 'mentor';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole? fromWebRoleKey(String? webRoleKey) {
    if (webRoleKey == null || webRoleKey.isEmpty) {
      return null;
    }

    switch (webRoleKey.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      case 'facilitator':
      case 'instructor':
        return UserRole.facilitator;
      case 'school_admin':
        return UserRole.schoolAdmin;
      case 'uni_member':
      case 'university_member':
        return UserRole.uniMember;
      case 'circle_member':
        return UserRole.circleMember;
      case 'mentor':
        return UserRole.mentor;
      case 'admin':
      case 'platform_admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}
