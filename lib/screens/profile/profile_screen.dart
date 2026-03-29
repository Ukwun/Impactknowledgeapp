import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';
import '../../config/routes.dart';
import '../../config/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.dark700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: Obx(() {
          final user = authController.currentUser.value;
          if (user == null) {
            return const Center(
              child: Text(
                'Profile not available',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          final initials = _initials(user.firstName, user.lastName);
          final role = user.role?.name ?? 'student';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Avatar + name + role ──
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: AppTheme.darkCard(radius: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary500.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary500.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: const TextStyle(
                            color: AppTheme.primary400,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Contact info ──
                Container(
                  decoration: AppTheme.darkCard(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Contact Information'),
                      _infoRow(Icons.mail_outline, 'Email', user.email),
                      if (user.phone != null && user.phone!.isNotEmpty)
                        _infoRow(Icons.phone_outlined, 'Phone', user.phone!),
                      if (user.state != null && user.state!.isNotEmpty)
                        _infoRow(
                          Icons.location_on_outlined,
                          'State',
                          user.state!,
                        ),
                      if (user.institution != null &&
                          user.institution!.isNotEmpty)
                        _infoRow(
                          Icons.school_outlined,
                          'Institution',
                          user.institution!,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Account ──
                Container(
                  decoration: AppTheme.darkCard(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Account'),
                      _infoRow(
                        Icons.verified_user_outlined,
                        'Email Verified',
                        user.emailVerified ? 'Yes' : 'No',
                      ),
                      _infoRow(
                        Icons.calendar_today_outlined,
                        'Member Since',
                        _formatDate(user.createdAt),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Links ──
                Container(
                  decoration: AppTheme.darkCard(radius: 16),
                  child: Column(
                    children: [
                      _menuRow(
                        Icons.emoji_events_outlined,
                        'Achievements',
                        () => Get.toNamed(AppRoutes.achievements),
                      ),
                      _menuRow(
                        Icons.leaderboard,
                        'Leaderboard',
                        () => Get.toNamed(AppRoutes.leaderboard),
                      ),
                      _menuRow(
                        Icons.card_membership,
                        'Membership',
                        () => Get.toNamed(AppRoutes.membership),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Logout ──
                _dangerButton(
                  Icons.logout,
                  'Sign Out',
                  () async => await authController.logout(),
                  AppTheme.textMuted,
                ),

                const SizedBox(height: 12),

                // ── Delete Account ──
                _dangerButton(
                  Icons.delete_outline,
                  'Delete Account',
                  () => _confirmDelete(context, authController),
                  AppTheme.danger500,
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.primary400, size: 18),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _menuRow(IconData icon, String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ],
      ),
    ),
  );

  Widget _dangerButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  void _confirmDelete(BuildContext context, AuthController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dark700,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger500,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty ?? false) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty ?? false) ? last![0].toUpperCase() : '';
    return f + l;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _roleLabel(String role) {
    const labels = {
      'student': 'Student',
      'parent': 'Parent',
      'facilitator': 'Facilitator',
      'instructor': 'Instructor',
      'schoolAdmin': 'School Admin',
      'school_admin': 'School Admin',
      'uniMember': 'University Member',
      'uni_member': 'University Member',
      'circleMember': 'Circle Member',
      'circle_member': 'Circle Member',
      'mentor': 'Mentor',
      'admin': 'Admin',
    };
    return labels[role] ?? role;
  }
}
