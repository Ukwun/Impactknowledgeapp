import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../models/auth/user_model.dart';
import '../services/auth/auth_service.dart';
import '../config/service_locator.dart';
import '../config/app_config.dart';

final Logger _logger = Logger();

class AuthController extends GetxController {
  final authService = getIt<AuthService>();

  final currentUser = Rx<UserProfile?>(null);
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final errorMessage = RxString('');

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      isLoggedIn.value = await authService.isLoggedIn();
      if (isLoggedIn.value) {
        final savedUser = await authService.getSavedUser();
        if (savedUser != null) {
          currentUser.value = savedUser;
        }
        await getCurrentUserProfile();
      }
    } catch (e) {
      errorMessage.value = 'Error checking login status';
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final response = await authService.login(email, password);
      currentUser.value = response.user;
      isLoggedIn.value = true;
    } catch (e) {
      errorMessage.value = _toUserFacingAuthError(e);
      isLoggedIn.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signup(
    String email,
    String password,
    String firstName,
    String lastName, {
    String? phone,
    String? role,
    String? state,
    String? institution,
    String? countryOfResidence,
    String? professionOrStudyArea,
    String? reasonForJoining,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final request = SignupRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: role,
        state: state,
        institution: institution,
        countryOfResidence: countryOfResidence,
        professionOrStudyArea: professionOrStudyArea,
        reasonForJoining: reasonForJoining,
      );
      final response = await authService.signup(request);
      currentUser.value = response.user;
      isLoggedIn.value = true;
      return true;
    } catch (e) {
      if (_isEmailAlreadyExistsError(e)) {
        try {
          // If account already exists for this email, proceed with sign-in
          // so the user can continue without getting stuck.
          final loginResponse = await authService.login(email, password);
          currentUser.value = loginResponse.user;
          isLoggedIn.value = true;
          errorMessage.value = '';
          return true;
        } catch (_) {
          // Fall through to user-facing duplicate-email message.
        }
      }

      errorMessage.value = _toUserFacingAuthError(e);
      isLoggedIn.value = false;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await authService.logout();
      currentUser.value = null;
      isLoggedIn.value = false;
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCurrentUserProfile() async {
    try {
      final user = await authService.getCurrentUser();
      currentUser.value = user;
    } catch (e) {
      if (currentUser.value == null) {
        final savedUser = await authService.getSavedUser();
        if (savedUser != null) {
          currentUser.value = savedUser;
          return;
        }
        errorMessage.value = 'Failed to load user profile';
      }
      // If we already have a user in memory/local storage, keep the session
      // without surfacing a blocking profile error for optional /auth/me backends.
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await authService.forgotPassword(email);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await authService.resetPassword(token, newPassword);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }

  bool _isEmailAlreadyExistsError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('already exists') ||
        text.contains('email already') ||
        text.contains('http 409');
  }

  String _toUserFacingAuthError(Object error) {
    final text = error.toString().toLowerCase();

    // Log the full error for debugging
    _logger.e('AUTH ERROR DETAILS');
    _logger.e('Error type: ${error.runtimeType}');
    _logger.e('Error message', error: error);

    if (text.contains('connection timeout') ||
        text.contains('connection error') ||
        text.contains('socketexception') ||
        text.contains('failed host lookup')) {
      return '❌ Cannot reach the server.\n\n'
          'Endpoint: ${AppConfig.apiBaseUrl}\n\n'
          '✅ Things to check:\n'
          '1. Is your device connected to internet? (Wi-Fi or mobile data)\n'
          '2. Can you open websites in your browser?\n'
          '3. If testing on EMULATOR: baseUrl should be 10.0.2.2:3000\n'
          '4. If testing on PHYSICAL PHONE: make sure backend is online\n\n'
          'Backend status check: Visit https://impactapp-backend.onrender.com/health in your browser';
    }

    if (text.contains('timeout')) {
      return '⏱ The server is taking too long to respond.\n\n'
          'The backend might be overloaded or starting up.\n'
          'Try again in a moment.';
    }

    if (text.contains('404')) {
      return '🚫 Endpoint not found (404).\n\n'
          'Server is reachable but the API endpoint doesn\'t exist.\n'
          'Error: $error';
    }

    if (_isEmailAlreadyExistsError(error)) {
      return 'This email is already registered. Please sign in instead.';
    }

    return '⚠️ Error: $error';
  }
}
