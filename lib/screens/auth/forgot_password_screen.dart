import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../config/routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Don\'t worry, we\'ll help you reset it.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              if (_emailSent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Email Sent!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ve sent a password reset link to ${emailController.text}. Check your email and follow the instructions.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Form(
                  key: formKey,
                  child: CustomInputField(
                    label: 'Email Address',
                    controller: emailController,
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              // Error Message
              Obx(() {
                if (authController.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authController.errorMessage.value,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              }),

              // Action Button
              const SizedBox(height: 24),
              if (!_emailSent)
                Obx(
                  () => CustomButton(
                    label: 'Send Reset Link',
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        authController.forgotPassword(emailController.text);
                        setState(() => _emailSent = true);
                      }
                    },
                    isLoading: authController.isLoading.value,
                  ),
                )
              else
                Column(
                  children: [
                    CustomButton(
                      label: 'Back to Login',
                      onPressed: () => Get.offAllNamed(AppRoutes.login),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() => _emailSent = false);
                        authController.clearError();
                      },
                      child: const Text(
                        'Try another email',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
