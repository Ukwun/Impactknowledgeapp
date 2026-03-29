import '../api/api_service.dart';
import '../../models/auth/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthService({required this.apiService});

  // Login - using direct HTTP instead of Dio (replaces problematic _postAuth)
  Future<AuthResponse> login(String email, String password) async {
    try {
      print('LOGIN: Starting login for $email');

      // Direct HTTP POST to backend - NO Dio complications
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('LOGIN: Response status ${response.statusCode}');
      print('LOGIN: Response body ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Login failed: HTTP ${response.statusCode} - ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Parse authentication response with proper type handling
      final authResponse = _parseAuthResponse(json);

      // Save tokens
      print(
        '💾 AUTH: Saving token: ${authResponse.accessToken.substring(0, 50)}...',
      );
      await apiService.saveToken(authResponse.accessToken);
      if (authResponse.refreshToken != null) {
        await _secureStorage.write(
          key: 'refresh_token',
          value: authResponse.refreshToken!,
        );
      }
      await saveUser(authResponse.user);

      print('LOGIN: Success for $email');
      return authResponse;
    } catch (e) {
      print('LOGIN ERROR: $e');
      rethrow;
    }
  }

  // Sign up - using direct HTTP instead of Dio
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      // Backend expects: email, password, full_name, role
      final payload = {
        'email': request.email,
        'password': request.password,
        'full_name': '${request.firstName} ${request.lastName}'.trim(),
        'role': request.role ?? 'student',
        'confirmPassword': request.password,
      };

      // Direct HTTP POST to backend - NO Dio complications
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      print('SIGNUP RESPONSE: $json');
      print('USER OBJECT: ${json['user']}');

      AuthResponse authResponse;
      try {
        authResponse = _parseAuthResponse(json);
      } catch (e) {
        print('PARSE ERROR: $e');
        print('ATTEMPTING TO PARSE USER: ${json['user']}');
        print('USER TYPE: ${json['user'].runtimeType}');
        if (json['user'] is Map) {
          final userMap = json['user'] as Map;
          for (var entry in userMap.entries) {
            print(
              'Field ${entry.key}: ${entry.value} (${entry.value.runtimeType})',
            );
          }
        }
        rethrow;
      }

      await apiService.saveToken(authResponse.accessToken);
      if (authResponse.refreshToken != null) {
        await _secureStorage.write(
          key: 'refresh_token',
          value: authResponse.refreshToken!,
        );
      }
      await saveUser(authResponse.user);

      return authResponse;
    } catch (e) {
      print('SIGNUP ERROR: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await apiService.post('auth/logout', data: {});
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
    final endpoints = ['auth/me', 'users/me', 'profile'];
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

    throw lastError ??
        Exception('Unable to fetch user profile from any endpoint');
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
        '/api/auth/refresh',
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
      await apiService.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await apiService.post(
        '/api/auth/reset-password',
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

  AuthResponse _parseAuthResponse(Map<String, dynamic> json) {
    // Legacy backend shape already matches AuthResponse.
    if (json.containsKey('accessToken') && json.containsKey('user')) {
      // Make a copy and normalize the user data BEFORE passing to fromJson
      final jsonCopy = Map<String, dynamic>.from(json);
      final userMap = jsonCopy['user'] is Map
          ? Map<String, dynamic>.from(jsonCopy['user'] as Map)
          : <String, dynamic>{};

      // Critical: Convert id to string if it's an int (database returns int)
      if (userMap['id'] is int) {
        userMap['id'] = userMap['id'].toString();
      }

      // Ensure all required datetime fields exist as ISO strings
      if (!userMap.containsKey('createdAt') || userMap['createdAt'] == null) {
        userMap['createdAt'] = DateTime.now().toIso8601String();
      }
      if (!userMap.containsKey('updatedAt') || userMap['updatedAt'] == null) {
        userMap['updatedAt'] = DateTime.now().toIso8601String();
      }
      if (!userMap.containsKey('emailVerified')) {
        userMap['emailVerified'] = false;
      }

      jsonCopy['user'] = userMap;
      return AuthResponse.fromJson(jsonCopy);
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

    // Convert id to string if it's an int
    if (rawUser['id'] is int) {
      rawUser['id'] = rawUser['id'].toString();
    }

    // Ensure required fields exist for UserProfile.fromJson.
    final createdAt = rawUser['createdAt'] ?? DateTime.now().toIso8601String();
    rawUser['createdAt'] = createdAt;
    rawUser['updatedAt'] =
        rawUser['updatedAt'] ?? rawUser['updated_at'] ?? createdAt;

    if (!rawUser.containsKey('emailVerified')) {
      rawUser['emailVerified'] = false;
    }

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
