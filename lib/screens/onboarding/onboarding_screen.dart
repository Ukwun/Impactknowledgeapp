import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final List<String> _selectedInterests = [];
  String _learningGoal = '';
  String _learningPace = '';
  String _skillLevel = '';

  static const _interests = [
    'Technology',
    'Business',
    'Design',
    'Science',
    'Health',
    'Finance',
    'Marketing',
    'Development',
    'Arts',
    'Language',
    'Leadership',
    'Research',
  ];

  static const _goals = [
    'Career Growth',
    'Personal Development',
    'Skill Enhancement',
    'Certification',
    'Learning for Fun',
  ];

  static const _paces = ['Self-paced', 'Scheduled', 'Intensive'];
  static const _skills = ['Beginner', 'Intermediate', 'Advanced'];

  static const _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.dark800,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
          child: Stack(
            children: [
              // Glow orbs
              Positioned(
                top: -100,
                right: -60,
                child: _Orb(280, AppTheme.primary500.withValues(alpha: 0.08)),
              ),
              Positioned(
                bottom: -80,
                left: -40,
                child: _Orb(220, AppTheme.secondary500.withValues(alpha: 0.07)),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // ── Top bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_step > 0)
                            IconButton(
                              onPressed: () => setState(() => _step--),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: AppTheme.textLight,
                                size: 18,
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                          // progress steps
                          Row(
                            children: List.generate(
                              _totalSteps,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: i == _step ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? AppTheme.primary500
                                      : AppTheme.dark400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Get.offAllNamed(AppRoutes.dashboard),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Step content ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: [
                            _buildWelcome(),
                            _buildInterests(),
                            _buildGoals(),
                            _buildPreferences(),
                          ][_step],
                        ),
                      ),
                    ),

                    // ── CTA button ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: _PrimaryButton(
                        label: _step == _totalSteps - 1
                            ? 'Get Started'
                            : 'Continue',
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  // ── Step 0: Welcome ────────────────────────────────────────────────────────
  Widget _buildWelcome() {
    final authController = Get.find<AuthController>();
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.rocket_launch_outlined,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => Text(
            'Welcome, ${authController.currentUser.value?.firstName ?? 'Learner'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Let\'s personalise your ImpactApp experience. It only takes a minute.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.darkCard(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'What you\'ll unlock:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 14),
              _BenefitRow('🎓', 'Personalised learning paths'),
              _BenefitRow('🏆', 'Earn badges & achievements'),
              _BenefitRow('📊', 'Track your progress'),
              _BenefitRow('👥', 'Join the community'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1: Interests ──────────────────────────────────────────────────────
  Widget _buildInterests() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'What are you interested in?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick at least 2 topics to personalise your dashboard.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _interests.map((interest) {
            final sel = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () => setState(() {
                sel
                    ? _selectedInterests.remove(interest)
                    : _selectedInterests.add(interest);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: sel ? AppTheme.primaryGradient : null,
                  color: sel ? null : AppTheme.dark600,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sel
                        ? AppTheme.primary500
                        : AppTheme.dark400.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: sel ? Colors.white : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Learning Goal ──────────────────────────────────────────────────
  Widget _buildGoals() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'What\'s your learning goal?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll recommend courses tailored for you.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ..._goals.map((goal) {
          final sel = _learningGoal == goal;
          return GestureDetector(
            onTap: () => setState(() => _learningGoal = goal),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: sel ? AppTheme.primaryGradient : null,
                color: sel ? null : AppTheme.dark600,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel
                      ? AppTheme.primary500
                      : AppTheme.dark400.withValues(alpha: 0.5),
                  width: sel ? 2 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      goal,
                      style: TextStyle(
                        color: sel ? Colors.white : AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (sel)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 3: Pace + Skill Level ─────────────────────────────────────────────
  Widget _buildPreferences() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'How do you like to learn?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help us set the right pace for you.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 28),
        _subheading('Learning Pace'),
        const SizedBox(height: 12),
        Row(
          children: _paces.map((p) {
            final sel = _learningPace == p;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _learningPace = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: sel ? AppTheme.primaryGradient : null,
                    color: sel ? null : AppTheme.dark600,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppTheme.primary500
                          : AppTheme.dark400.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    p,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _subheading('Skill Level'),
        const SizedBox(height: 12),
        Row(
          children: _skills.map((s) {
            final sel = _skillLevel == s;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _skillLevel = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: sel ? AppTheme.primaryGradient : null,
                    color: sel ? null : AppTheme.dark600,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppTheme.primary500
                          : AppTheme.dark400.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    s,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primary500.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primary500.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.primary400, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'re all set! Hit Get Started to see your personalised dashboard.',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subheading(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _BenefitRow extends StatelessWidget {
  final String emoji;
  final String label;
  const _BenefitRow(this.emoji, this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
        ),
      ],
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

