import 'package:flutter/material.dart';
import '../../../config/role_dashboard_resolver.dart';
import '../../../models/auth/user_model.dart';
import 'admin_dashboard_screen.dart';
import 'circle_member_dashboard_screen.dart';
import 'facilitator_dashboard_screen.dart';
import 'mentor_dashboard_screen.dart';
import 'parent_dashboard_screen.dart';
import 'school_admin_dashboard_screen.dart';
import 'uni_member_dashboard_screen.dart';

class RoleDashboardSwitcher extends StatelessWidget {
  final UserRole role;
  final String firstName;

  const RoleDashboardSwitcher({
    super.key,
    required this.role,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    switch (RoleDashboardResolver.resolve(role)) {
      case DashboardExperience.parent:
        return ParentDashboardScreen(firstName: firstName);
      case DashboardExperience.facilitator:
        return FacilitatorDashboardScreen(firstName: firstName);
      case DashboardExperience.schoolAdmin:
        return SchoolAdminDashboardScreen(firstName: firstName);
      case DashboardExperience.mentor:
        return MentorDashboardScreen(firstName: firstName);
      case DashboardExperience.circleMember:
        return CircleMemberDashboardScreen(firstName: firstName);
      case DashboardExperience.uniMember:
        return UniMemberDashboardScreen(firstName: firstName);
      case DashboardExperience.admin:
        return AdminDashboardScreen(firstName: firstName);
      case DashboardExperience.learner:
        return const SizedBox.shrink();
    }
  }
}
