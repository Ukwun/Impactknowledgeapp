// Typed per-role dashboard response contracts.
//
// Each model provides a resilient [fromJson] factory that tries multiple nested
// key paths — the same fallback chains previously used by DashboardDataReader.
// Compile-time-safe property access replaces every runtime string-path pick.
//
// Models are intentionally immutable (all fields final). SSE delta payloads
// are merged into the raw [Map] inside LiveRoleDashboardData and [fromJson] is
// re-called on every rebuild — no mutable state lives in the models.

// ─── helpers ──────────────────────────────────────────────────────────────────

int _int(Map<String, dynamic> json, List<String> dotPaths, [int fallback = 0]) {
  for (final path in dotPaths) {
    dynamic current = json;
    for (final key in path.split('.')) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        current = null;
        break;
      }
    }
    if (current != null) {
      if (current is int) return current;
      if (current is num) return current.toInt();
      if (current is String) {
        final parsed = int.tryParse(current);
        if (parsed != null) return parsed;
      }
    }
  }
  return fallback;
}

String _str(
  Map<String, dynamic> json,
  List<String> dotPaths, [
  String fallback = '',
]) {
  for (final path in dotPaths) {
    dynamic current = json;
    for (final key in path.split('.')) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        current = null;
        break;
      }
    }
    if (current is String && current.isNotEmpty) return current;
    if (current != null) return current.toString();
  }
  return fallback;
}

// ─── Parent ───────────────────────────────────────────────────────────────────

class ParentDashboardData {
  final int childrenLinked;
  final int avgProgress;
  final int attendanceRate;
  final int unreadMessages;

  const ParentDashboardData({
    required this.childrenLinked,
    required this.avgProgress,
    required this.attendanceRate,
    required this.unreadMessages,
  });

  factory ParentDashboardData.fromJson(Map<String, dynamic> json) =>
      ParentDashboardData(
        childrenLinked: _int(json, [
          'summary.childrenLinked',
          'summary.childrenCount',
          'childrenLinked',
        ]),
        avgProgress: _int(json, [
          'summary.avgProgress',
          'summary.overallProgress',
          'avgProgress',
        ]),
        attendanceRate: _int(json, [
          'summary.attendanceRate',
          'summary.attendance',
          'attendanceRate',
        ]),
        unreadMessages: _int(json, [
          'summary.unreadMessages',
          'unreadMessages',
          'messages.unread',
        ]),
      );
}

// ─── Facilitator ──────────────────────────────────────────────────────────────

class FacilitatorDashboardData {
  final int activeClasses;
  final int pendingReviews;
  final int atRiskLearners;
  final int unreadMessages;

  const FacilitatorDashboardData({
    required this.activeClasses,
    required this.pendingReviews,
    required this.atRiskLearners,
    required this.unreadMessages,
  });

  factory FacilitatorDashboardData.fromJson(Map<String, dynamic> json) =>
      FacilitatorDashboardData(
        activeClasses: _int(json, [
          'summary.activeClasses',
          'metrics.activeClasses',
          'activeClasses',
        ]),
        pendingReviews: _int(json, [
          'summary.pendingReviews',
          'metrics.assignmentsPending',
          'pendingReviews',
        ]),
        atRiskLearners: _int(json, [
          'summary.atRiskLearners',
          'metrics.atRiskLearners',
          'atRiskLearners',
        ]),
        unreadMessages: _int(json, [
          'summary.unreadMessages',
          'messages.unread',
          'unreadMessages',
        ]),
      );
}

// ─── School Admin ─────────────────────────────────────────────────────────────

class SchoolAdminDashboardData {
  final int totalStudents;
  final int totalFacilitators;
  final int completionRate;
  final int openAlerts;

  const SchoolAdminDashboardData({
    required this.totalStudents,
    required this.totalFacilitators,
    required this.completionRate,
    required this.openAlerts,
  });

  factory SchoolAdminDashboardData.fromJson(Map<String, dynamic> json) =>
      SchoolAdminDashboardData(
        totalStudents: _int(json, [
          'summary.totalStudents',
          'metrics.totalStudents',
          'totalStudents',
        ]),
        totalFacilitators: _int(json, [
          'summary.totalFacilitators',
          'metrics.totalFacilitators',
          'totalFacilitators',
        ]),
        completionRate: _int(json, [
          'summary.completionRate',
          'metrics.completionRate',
          'completionRate',
        ]),
        openAlerts: _int(json, [
          'summary.openAlerts',
          'openAlerts',
          'alertsCount',
        ]),
      );
}

// ─── Mentor ───────────────────────────────────────────────────────────────────

class MentorDashboardData {
  final int totalMentees;
  final int upcomingSessions;
  final int completedSessions;
  final int avgMenteeGrowth;

  const MentorDashboardData({
    required this.totalMentees,
    required this.upcomingSessions,
    required this.completedSessions,
    required this.avgMenteeGrowth,
  });

  factory MentorDashboardData.fromJson(Map<String, dynamic> json) =>
      MentorDashboardData(
        totalMentees: _int(json, [
          'summary.totalMentees',
          'stats.totalMentees',
          'totalMentees',
        ]),
        upcomingSessions: _int(json, [
          'summary.upcomingSessions',
          'stats.upcomingMeetings',
          'upcomingSessions',
        ]),
        completedSessions: _int(json, [
          'summary.completedSessions',
          'stats.completedSessions',
          'completedSessions',
        ]),
        avgMenteeGrowth: _int(json, [
          'summary.avgMenteeGrowth',
          'stats.avgMenteeProgress',
          'avgMenteeGrowth',
        ]),
      );
}

// ─── Circle Member ────────────────────────────────────────────────────────────

class CircleMemberDashboardData {
  final int connections;
  final int postsThisMonth;
  final int roundtables;
  final int profileReach;

  const CircleMemberDashboardData({
    required this.connections,
    required this.postsThisMonth,
    required this.roundtables,
    required this.profileReach,
  });

  factory CircleMemberDashboardData.fromJson(Map<String, dynamic> json) =>
      CircleMemberDashboardData(
        connections: _int(json, [
          'summary.connections',
          'profileStats.connections',
          'connections',
        ]),
        postsThisMonth: _int(json, [
          'summary.postsThisMonth',
          'profileStats.posts',
          'posts',
        ]),
        roundtables: _int(json, [
          'summary.roundtables',
          'stats.roundtables',
          'roundtables',
        ]),
        profileReach: _int(json, [
          'summary.profileReach',
          'profileStats.profileViews',
          'profileReach',
        ]),
      );
}

// ─── University Member ────────────────────────────────────────────────────────

class UniMemberDashboardData {
  final String ventureStage;
  final int teamMembers;
  final int mentorSessions;
  final int openOpportunities;

  const UniMemberDashboardData({
    required this.ventureStage,
    required this.teamMembers,
    required this.mentorSessions,
    required this.openOpportunities,
  });

  factory UniMemberDashboardData.fromJson(Map<String, dynamic> json) =>
      UniMemberDashboardData(
        ventureStage: _str(json, [
          'summary.ventureStage',
          'venture.stage',
          'ventureStage',
        ], 'Unknown'),
        teamMembers: _int(json, [
          'summary.teamMembers',
          'venture.teamSize',
          'teamMembers',
        ]),
        mentorSessions: _int(json, [
          'summary.mentorSessions',
          'venture.mentorSessions',
          'mentorSessions',
        ]),
        openOpportunities: _int(json, [
          'summary.openOpportunities',
          'opportunities.count',
          'openOpportunities',
        ]),
      );
}

// ─── Admin ────────────────────────────────────────────────────────────────────

class AdminDashboardData {
  final int totalUsers;
  final int activeCourses;
  final int completionRate;
  final int openAlerts;

  const AdminDashboardData({
    required this.totalUsers,
    required this.activeCourses,
    required this.completionRate,
    required this.openAlerts,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        totalUsers: _int(json, [
          'summary.totalUsers',
          'metrics.totalUsers',
          'totalUsers',
        ]),
        activeCourses: _int(json, [
          'summary.activeCourses',
          'metrics.activeCourses',
          'activeCourses',
        ]),
        completionRate: _int(json, [
          'summary.completionRate',
          'metrics.completionRate',
          'completionRate',
        ]),
        openAlerts: _int(json, [
          'summary.openAlerts',
          'alertsCount',
          'openAlerts',
        ]),
      );
}
