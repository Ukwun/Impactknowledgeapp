import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';
import '../../config/routes.dart';
import '../../config/app_theme.dart';

// Mirrors website register/page.tsx role list exactly
const _roles = [
  ('student', 'Student (ImpactSchools)'),
  ('parent', 'Parent / Guardian'),
  ('facilitator', 'Facilitator'),
  ('school_admin', 'School Administrator'),
  ('uni_member', 'University Member (ImpactUni)'),
  ('circle_member', 'Professional (ImpactCircle)'),
  ('mentor', 'Mentor'),
  ('admin', 'Platform Admin'),
];

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ── step tracking ─────────────────────────────────────────────
  int _step = 1; // 1 | 2 | 3

  // ── form controllers ──────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _selectedRole;
  bool _agreeToTerms = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  Worker? _authStateWorker;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    _authStateWorker = ever(authController.isLoggedIn, (loggedIn) {
      if (loggedIn && authController.currentUser.value != null) {
        Get.offAllNamed(AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _authStateWorker?.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _stateCtrl.dispose();
    _institutionCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── validation ────────────────────────────────────────────────
  bool _validateStep() {
    setState(() => _error = null);
    if (_step == 1) {
      if (!(_formKey1.currentState?.validate() ?? false)) return false;
    } else if (_step == 2) {
      if (!(_formKey2.currentState?.validate() ?? false)) return false;
      if (_selectedRole == null) {
        setState(() => _error = 'Please select your role');
        return false;
      }
    } else {
      if (!(_formKey3.currentState?.validate() ?? false)) return false;
      if (!_agreeToTerms) {
        setState(() => _error = 'You must agree to the terms and conditions');
        return false;
      }
    }
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() {
        _step--;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final authController = Get.find<AuthController>();
    final created = await authController.signup(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      role: _selectedRole,
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      institution: _institutionCtrl.text.trim().isEmpty
          ? null
          : _institutionCtrl.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (created && authController.currentUser.value != null) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    if (authController.errorMessage.value.isEmpty) {
      setState(() {
        _error = 'Unable to create account right now. Please try again.';
      });
    }
  }

  // ── helpers ───────────────────────────────────────────────────
  Widget _darkInput({
    required TextEditingController ctrl,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    bool toggleObscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: AppTheme.darkInput(
        hint: hint,
        prefix: prefix,
        suffix: toggleObscure
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppTheme.textLight,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _field(String label, Widget input) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_label(label), input, const SizedBox(height: 16)],
  );

  // ── step indicator ────────────────────────────────────────────
  Widget _stepIndicator() => Column(
    children: [
      Row(
        children: List.generate(3, (i) {
          final done = i + 1 < _step;
          final current = i + 1 == _step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                color: (done || current)
                    ? AppTheme.primary500
                    : AppTheme.dark400.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 6),
      Text(
        'Step $_step of 3',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
    ],
  );

  static const _stepTitles = [
    'Personal Details',
    'Role & Location',
    'Secure Account',
  ];
  static const _stepIcons = [
    Icons.person_outline,
    Icons.location_on_outlined,
    Icons.lock_outline,
  ];

  Widget _stepHeader() => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_stepIcons[_step - 1], color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Text(
        _stepTitles[_step - 1],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  // ── step 1: personal ─────────────────────────────────────────
  Widget _step1() => Form(
    key: _formKey1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                'First Name',
                _darkInput(
                  ctrl: _firstNameCtrl,
                  hint: 'John',
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                'Last Name',
                _darkInput(
                  ctrl: _lastNameCtrl,
                  hint: 'Doe',
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
              ),
            ),
          ],
        ),
        _field(
          'Email Address',
          _darkInput(
            ctrl: _emailCtrl,
            hint: 'you@example.com',
            keyboard: TextInputType.emailAddress,
            prefix: const Icon(
              Icons.mail_outline,
              color: AppTheme.textMuted,
              size: 18,
            ),
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
        ),
        _field(
          'Phone Number',
          _darkInput(
            ctrl: _phoneCtrl,
            hint: '+234 0XX XXX XXXX',
            keyboard: TextInputType.phone,
            prefix: const Icon(
              Icons.phone_outlined,
              color: AppTheme.textMuted,
              size: 18,
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Phone number is required' : null,
          ),
        ),
      ],
    ),
  );

  // ── step 2: role + location ───────────────────────────────────
  Widget _step2() => Form(
    key: _formKey2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Select Your Role'),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.dark600,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedRole == null && _error != null
                  ? AppTheme.danger500
                  : AppTheme.dark400.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Choose your role...',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textMuted,
                ),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.dark600,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _roles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.$1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(r.$2),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedRole = v;
                _error = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _field(
          'State of Residence',
          _darkInput(
            ctrl: _stateCtrl,
            hint: 'e.g., Lagos',
            prefix: const Icon(
              Icons.location_on_outlined,
              color: AppTheme.textMuted,
              size: 18,
            ),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'State is required' : null,
          ),
        ),
        _field(
          'School / Institution (Optional)',
          _darkInput(
            ctrl: _institutionCtrl,
            hint: 'Your school or organization',
            prefix: const Icon(
              Icons.business_outlined,
              color: AppTheme.textMuted,
              size: 18,
            ),
          ),
        ),
      ],
    ),
  );

  // ── step 3: password + terms ──────────────────────────────────
  Widget _step3() => Form(
    key: _formKey3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          'Password',
          _darkInput(
            ctrl: _passwordCtrl,
            hint: '••••••••',
            obscure: _obscurePass,
            toggleObscure: true,
            onToggle: () => setState(() => _obscurePass = !_obscurePass),
            prefix: const Icon(
              Icons.lock_outline,
              color: AppTheme.textMuted,
              size: 18,
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Password is required';
              if ((v?.length ?? 0) < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            '✓ At least 8 characters with uppercase and numbers',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        _field(
          'Confirm Password',
          _darkInput(
            ctrl: _confirmCtrl,
            hint: '••••••••',
            obscure: _obscureConfirm,
            toggleObscure: true,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            prefix: const Icon(
              Icons.lock_outline,
              color: AppTheme.textMuted,
              size: 18,
            ),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Please confirm password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
        ),
        // Terms checkbox (mirrors website)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary500.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primary500.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() {
                    _agreeToTerms = v ?? false;
                    _error = null;
                  }),
                  activeColor: AppTheme.primary500,
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Use',
                        style: const TextStyle(
                          color: AppTheme.primary400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppTheme.primary400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: Stack(
          children: [
            // Background glow orbs (mirror website)
            Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(
                size: 280,
                color: AppTheme.primary500.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _GlowOrb(
                size: 260,
                color: AppTheme.secondary500.withValues(alpha: 0.08),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // ── top bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _step == 1
                              ? () => Get.toNamed(AppRoutes.login)
                              : _back,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.login),
                          child: const Text(
                            'Sign in instead',
                            style: TextStyle(
                              color: AppTheme.primary400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // heading
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(
                                  Rect.fromLTWH(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                ),
                            child: const Text(
                              'Join ImpactApp',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create your account in 3 simple steps',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _stepIndicator(),
                          const SizedBox(height: 20),
                          _stepHeader(),
                          const SizedBox(height: 20),

                          // ── error banner ──
                          Obx(() {
                            final err =
                                authController.errorMessage.value.isNotEmpty
                                ? authController.errorMessage.value
                                : _error;
                            if (err == null || err.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.danger500.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.danger500.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppTheme.danger500,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      err,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // ── step content ──
                          if (_step == 1) _step1(),
                          if (_step == 2) _step2(),
                          if (_step == 3) _step3(),

                          const SizedBox(height: 8),

                          // ── nav buttons ──
                          Obx(
                            () => _GradientButton(
                              label: _step < 3 ? 'Continue' : 'Create Account',
                              isLoading: authController.isLoading.value,
                              onPressed: _next,
                              trailing: _step < 3
                                  ? const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),

                          if (_step > 1) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _back,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.dark400,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // ── already have account ──
                          if (_step == 1) ...[
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Get.toNamed(AppRoutes.login),
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      color: AppTheme.primary400,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget? trailing;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppTheme.primaryGradient,
          color: isLoading ? AppTheme.dark400 : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
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
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
