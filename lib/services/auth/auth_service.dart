import '../api/api_service.dart';
import '../../models/auth/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import '../../config/app_config.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthService({required this.apiService});

  // Login
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _postAuth(
        endpoints: ['/auth/login'],
        data: {'email': email, 'password': password},
      );

      // Save tokens
      await apiService.saveToken(response.accessToken);
      if (response.refreshToken != null) {
        await _secureStorage.write(
          key: 'refresh_token',
          value: response.refreshToken!,
        );
      }
      await saveUser(response.user);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      final payload = {
        ...request.toJson(),
        // Web backend requires confirmPassword field
        'confirmPassword': request.password,
        // Use the role chosen during signup, default to student
        'role': request.role ?? 'student',
      };

      final response = await _postAuth(
        // Support both baseUrl styles:
        // - http://host:3000/api  + /auth/register
        // - http://host:3000      + /api/auth/register
        // Keep /auth/signup fallback for legacy backends.
        endpoints: [
          '/auth/register',
          '/api/auth/register',
          '/auth/signup',
          '/api/auth/signup',
        ],
        data: payload,
      );

      await apiService.saveToken(response.accessToken);
      if (response.refreshToken != null) {
        await _secureStorage.write(
          key: 'refresh_token',
          value: response.refreshToken!,
        );
      }
      await saveUser(response.user);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await apiService.post('/auth/logout', data: {});
      await apiService.clearToken();
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: AppConfig.userKey);
    } catch (e) {
      // Clear locally even if API call fails
      await apiService.clearToken();
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: AppConfig.userKey);
    }
  }

  // Get current user with multi-endpoint fallback
  Future<UserProfile> getCurrentUser() async {
    final endpoints = ['/auth/me', '/users/me', '/profile'];
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        final response = await apiService.get<UserProfile>(
          endpoint,
          fromJson: (json) {
            // Normalize role before creating UserProfile to handle MENTOR -> mentor, etc.
            final data = json as Map<String, dynamic>;
            final roleRaw = data['role'];
            if (roleRaw is String && roleRaw.isNotEmpty) {
              data['role'] = _normalizeRole(roleRaw);
            }
            return UserProfile.fromJson(data);
          },
        );
        await saveUser(response);
        return response;
      } catch (e) {
        lastError = e;
        // Continue to next endpoint
      }
    }

    // If all endpoints fail, try to get from saved storage
    final saved = await getSavedUser();
    if (saved != null) {
      return saved;
    }

    throw lastError ?? Exception('Unable to fetch user profile from any endpoint');
  }

  Future<void> saveUser(UserProfile user) async {
    await _secureStorage.write(
      key: AppConfig.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<UserProfile?> getSavedUser() async {
    final raw = await _secureStorage.read(key: AppConfig.userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await apiService.post<AuthResponse>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        fromJson: (json) {
          return AuthResponse.fromJson(json as Map<String, dynamic>);
        },
      );

      await apiService.saveToken(response.accessToken);
    } catch (e) {
      rethrow;
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await apiService.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await apiService.post(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken != null) {
      return true;
    }

    // Demo-mode backend may return only an access token.
    final accessToken = await _secureStorage.read(key: 'auth_token');
    return accessToken != null;
  }

  // Decode token to get user info
  Map<String, dynamic>? decodeToken(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      return decodedToken;
    } catch (e) {
      return null;
    }
  }

  Future<AuthResponse> _postAuth({
    required List<String> endpoints,
    required Map<String, dynamic> data,
  }) async {
    Object? lastError;
    for (final endpoint in endpoints) {
      try {
        return await apiService.post<AuthResponse>(
          endpoint,
          data: data,
          fromJson: (json) {
            return _parseAuthResponse(json as Map<String, dynamic>);
          },
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? Exception('Authentication request failed');
  }

  AuthResponse _parseAuthResponse(Map<String, dynamic> json) {
    // Legacy backend shape already matches AuthResponse.
    if (json.containsKey('accessToken') && json.containsKey('user')) {
      return AuthResponse.fromJson(json);
    }

    // Next.js web backend shape: { success, data: { token, refreshToken?, user } }.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final token = (data['token'] ?? data['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw Exception('Auth token missing in server response');
    }

    final rawUser = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};

    // Ensure required fields exist for UserProfile.fromJson.
    final createdAt = rawUser['createdAt'] ?? DateTime.now().toIso8601String();
    rawUser['createdAt'] = createdAt;
    rawUser['updatedAt'] =
        rawUser['updatedAt'] ?? rawUser['updated_at'] ?? createdAt;

    // Normalize role values from backend enum style (e.g. STUDENT).
    final roleRaw = rawUser['role'];
    if (roleRaw is String && roleRaw.isNotEmpty) {
      rawUser['role'] = _normalizeRole(roleRaw);
    }

    return AuthResponse(
      accessToken: token,
      refreshToken: data['refreshToken']?.toString(),
      user: UserProfile.fromJson(rawUser),
    );
  }

  String _normalizeRole(String raw) {
    final lower = raw.trim().toLowerCase();
    switch (lower) {
      case 'schooladmin':
      case 'school_admin':
        return 'school_admin';
      case 'unimember':
      case 'uni_member':
      case 'university_member':
        return 'uni_member';
      case 'circlemember':
      case 'circle_member':
        return 'circle_member';
      case 'platform_admin':
        return 'admin';
      default:
        return lower;
    }
  }
}
