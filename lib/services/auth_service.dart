import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if user is already logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Get stored user data
  Future<User?> getStoredUser() async {
    final userData = _prefs.getString(_userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
  }) async {
    try {
      debugPrint('[REGISTER] Request:');
      debugPrint('URL: $baseUrl${ApiConfig.authRegisterEndpoint}');
      debugPrint('Headers: \\n${ApiConfig.defaultHeaders}');
      debugPrint('Body: {email: $email, username: $username, password1: $password1, password2: $password2}');

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.authRegisterEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'username': username,
          'password1': password1,
          'password2': password2,
        }),
      ).timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw Exception('Connection timeout'),
      );

      debugPrint('[REGISTER] Response status: \\n${response.statusCode}');
      debugPrint('[REGISTER] Response body: \\n${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint('[REGISTER] Registration success: $responseData');
        // Use backend message if available
        String backendMsg = '';
        if (responseData is Map && responseData.containsKey('detail')) {
          backendMsg = responseData['detail'].toString();
        }
        return {
          'success': true,
          'message': backendMsg.isNotEmpty ? backendMsg : 'Registration successful. Please verify your email.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('[REGISTER] Registration failed: $errorData');
        String message = 'Registration failed';
        // Try to extract a specific error message for email already used
        if (errorData is Map && errorData.containsKey('error')) {
          final err = errorData['error'];
          if (err is Map && err.containsKey('details')) {
            final details = err['details'];
            if (details is Map && details.containsKey('email')) {
              final emailErrors = details['email'];
              if (emailErrors is List && emailErrors.any((e) => e.toString().toLowerCase().contains('already registered'))) {
                message = 'An account with this email already exists.';
              } else {
                message = emailErrors.join(' ');
              }
            } else if (details is Map && details.containsKey('username')) {
              final usernameErrors = details['username'];
              if (usernameErrors is List && usernameErrors.any((e) => e.toString().toLowerCase().contains('already exists'))) {
                message = 'This username is already taken.';
              } else {
                message = usernameErrors.join(' ');
              }
            } else if (err.containsKey('message')) {
              message = err['message'].toString();
            }
          } else if (err.containsKey('message')) {
            message = err['message'].toString();
          }
        } else if (errorData.containsKey('detail')) {
          message = errorData['detail'].toString();
        }
        return {
          'success': false,
          'message': message,
          'errors': errorData,
        };
      }
    } catch (e) {
      debugPrint('[REGISTER] Exception: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Login user and store tokens
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      debugPrint('[LOGIN] Attempting login to: $baseUrl${ApiConfig.authLoginEndpoint}');
      debugPrint('[LOGIN] Identifier: $identifier');
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.authLoginEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        // Send both keys so the backend can match either email or username
        body: jsonEncode({
          'email': identifier,
          'username': identifier,
          'password': password,
        }),
      ).timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () {
          debugPrint('[LOGIN] Connection timeout after ${ApiConfig.connectionTimeout.inSeconds}s');
          throw TimeoutException('Connection timeout - server not responding');
        },
      );

      debugPrint('[LOGIN] Response status: ${response.statusCode}');
      debugPrint('[LOGIN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['access'];
        final refreshToken = responseData['refresh'];
        final userData = responseData['user'];

        // Store tokens securely
        await _secureStorage.write(key: _accessTokenKey, value: accessToken);
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

        User? user;
        if (userData is Map<String, dynamic>) {
          user = User.fromJson(userData);
          await _prefs.setString(_userKey, jsonEncode(userData));
        }

        debugPrint('[LOGIN] Login successful for user: ${user?.email}');
        return {
          'success': true,
          'message': 'Login successful',
          'user': user,
          'access_token': accessToken,
        };
      } else if (response.statusCode == 401) {
        debugPrint('[LOGIN] Authentication failed - invalid credentials');
        return {
          'success': false,
          'message': 'Invalid email or password',
        };
      } else {
        debugPrint('[LOGIN] Login failed with status ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail']?.toString() ?? errorData.toString(),
          'raw': errorData,
        };
      }
    } on TimeoutException catch (e) {
      debugPrint('[LOGIN] Timeout error: $e');
      return {
        'success': false,
        'message': 'Connection timeout. Please check your internet connection and try again.',
      };
    } on SocketException catch (e) {
      debugPrint('[LOGIN] Network error: $e');
      return {
        'success': false,
        'message': 'Cannot reach server. Please check your internet connection.',
      };
    } on HandshakeException catch (e) {
      debugPrint('[LOGIN] SSL/TLS error: $e');
      return {
        'success': false,
        'message': 'Security certificate error. Please check your connection.',
      };
    } on FormatException catch (e) {
      debugPrint('[LOGIN] JSON parsing error: $e');
      return {
        'success': false,
        'message': 'Invalid response from server.',
      };
    } catch (e) {
      debugPrint('[LOGIN] Unexpected error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.authRefreshEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'refresh': refreshToken}),
      ).timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw Exception('Connection timeout'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newAccessToken = responseData['access'];

        // Store new access token
        await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);

        return true;
      } else {
        // Refresh token expired or invalid, clear storage
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Logout user and clear tokens
  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _prefs.remove(_userKey);
  }

  /// Get authorization header
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      ...ApiConfig.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
