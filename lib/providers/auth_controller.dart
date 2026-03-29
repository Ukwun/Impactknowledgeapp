import 'package:get/get.dart';
import '../models/auth/user_model.dart';
import '../services/auth/auth_service.dart';
import '../config/service_locator.dart';
import '../config/app_config.dart';

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

  Future<void> signup(
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
    } catch (e) {
      errorMessage.value = _toUserFacingAuthError(e);
      isLoggedIn.value = false;
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

  String _toUserFacingAuthError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('connection timeout') ||
        text.contains('connection error') ||
        text.contains('socketexception') ||
        text.contains('failed host lookup')) {
      return 'Cannot reach the server right now.\n'
          'Endpoint: ${AppConfig.apiBaseUrl}\n'
          'If testing on emulator, use 10.0.2.2.\n'
          'If testing on a physical phone, use your computer LAN IP and ensure backend is running and reachable on the same Wi-Fi.';
    }

    if (text.contains('timeout')) {
      return 'The server is taking too long to respond. Please try again in a moment.';
    }

    return error.toString();
  }
}
