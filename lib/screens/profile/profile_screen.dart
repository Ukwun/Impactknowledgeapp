import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';
import '../../config/routes.dart';
import '../../config/app_theme.dart';
import '../../config/service_locator.dart';
import '../../services/api/api_service.dart';
import '../../models/auth/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ApiService _apiService = getIt<ApiService>();
  bool _saving = false;

  Future<void> _openEditProfile(UserProfile user) async {
    final fullNameController = TextEditingController(text: user.fullName ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    final locationController = TextEditingController(text: user.state ?? '');
    final bioController = TextEditingController(text: user.bio ?? '');
    final avatarController = TextEditingController(text: user.avatarUrl ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.dark700,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _field(fullNameController, 'Full Name'),
              _field(phoneController, 'Phone Number'),
              _field(locationController, 'Location / State'),
              _field(avatarController, 'Avatar URL'),
              _field(bioController, 'Bio', minLines: 3, maxLines: 5),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          await _saveProfile(
                            user,
                            fullName: fullNameController.text.trim(),
                            phone: phoneController.text.trim(),
                            location: locationController.text.trim(),
                            bio: bioController.text.trim(),
                            avatarUrl: avatarController.text.trim(),
                          );
                          if (mounted) Navigator.of(context).pop();
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textMuted),
          filled: true,
          fillColor: AppTheme.dark800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(
    UserProfile existing, {
    required String fullName,
    required String phone,
    required String location,
    required String bio,
    required String avatarUrl,
  }) async {
    setState(() => _saving = true);
    final response = await _apiService.updateMyProfile({
      'full_name': fullName,
      'phone_number': phone.isEmpty ? null : phone,
      'location': location.isEmpty ? null : location,
      'bio': bio.isEmpty ? null : bio,
      'profile_picture_url': avatarUrl.isEmpty ? null : avatarUrl,
    });

    setState(() => _saving = false);

    if (response['success'] == true) {
      final updated = UserProfile(
        id: existing.id,
        email: existing.email,
        fullName: fullName.isEmpty ? existing.fullName : fullName,
        firstName: existing.firstName,
        lastName: existing.lastName,
        phone: phone.isEmpty ? existing.phone : phone,
        state: location.isEmpty ? existing.state : location,
        institution: existing.institution,
        avatarUrl: avatarUrl.isEmpty ? existing.avatarUrl : avatarUrl,
        bio: bio.isEmpty ? existing.bio : bio,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        role: existing.role,
        emailVerified: existing.emailVerified,
        accountStatus: existing.accountStatus,
        countryOfResidence: existing.countryOfResidence,
        professionOrStudyArea: existing.professionOrStudyArea,
        reasonForJoining: existing.reasonForJoining,
        membershipTierId: existing.membershipTierId,
        referralCode: existing.referralCode,
      );
      _authController.currentUser.value = updated;
      Get.snackbar('Profile updated', 'Your changes were saved successfully');
    } else {
      Get.snackbar(
        'Update failed',
        response['error']?.toString() ?? 'Unable to update profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          final user = _authController.currentUser.value;
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
                        (user.fullName ??
                                '${user.firstName ?? ''} ${user.lastName ?? ''}')
                            .trim(),
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openEditProfile(user),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                      if (user.bio != null && user.bio!.isNotEmpty)
                        _infoRow(Icons.info_outline, 'Bio', user.bio!),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                      _menuRow(
                        Icons.forum_outlined,
                        'Community',
                        () => Get.toNamed(AppRoutes.community),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _dangerButton(
                  Icons.logout,
                  'Sign Out',
                  () async => await _authController.logout(),
                  AppTheme.textMuted,
                ),
                const SizedBox(height: 12),
                _dangerButton(
                  Icons.delete_outline,
                  'Delete Account',
                  () => _confirmDelete(context, _authController),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary400, size: 18),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
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
    return (f + l).isNotEmpty ? (f + l) : 'U';
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
