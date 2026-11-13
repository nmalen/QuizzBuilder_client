import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _errorCode;
  String? _lastMessage;
  String? _successMessage;
  bool _registerThrottled = false;
  int? _registerRetryAfterSeconds;

  AuthProvider({required AuthService authService}) : _authService = authService;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  /// True once [initialize] has finished (stored session read, token
  /// refresh attempted). Deep links wait for it before deciding what to do.
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get lastMessage => _lastMessage;
  String? get successMessage => _successMessage;

  /// The last registration was refused by the rate limit (HTTP 429).
  bool get registerThrottled => _registerThrottled;

  /// Seconds the API says to wait after that 429, or null if it did not say.
  int? get registerRetryAfterSeconds => _registerRetryAfterSeconds;
  AuthService get authService => _authService;

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  /// Initialize auth state from stored data
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      await _authService.initialize();

      if (await _authService.isLoggedIn()) {
        _user = await _authService.getStoredUser();
        // Trust the cached session immediately so an offline user keeps
        // access to their already-downloaded quizzes without re-logging in.
        _isLoggedIn = true;

        // Refresh the access token in the background to avoid stale tokens.
        // refreshAccessToken() only clears the session when the server
        // explicitly rejects the refresh token; a network failure leaves
        // the cached session untouched.
        final refreshed = await _authService.refreshAccessToken();
        if (!refreshed) {
          final stillHasSession = await _authService.isLoggedIn();
          _isLoggedIn = stillHasSession;
          if (!stillHasSession) {
            _user = null;
          }
        }
      }
    } catch (e) {
      _error = 'Initialization error: ${e.toString()}';
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
    String? invitationCode,
  }) async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      username: username,
      password1: password1,
      password2: password2,
      invitationCode: invitationCode,
    );

    _isLoading = false;

    if (result['success']) {
      _error = null;
      _lastMessage = result['message'];
      _successMessage = result['message'];
      _registerThrottled = false;
      _registerRetryAfterSeconds = null;
    } else {
      _error = result['message'];
      _lastMessage = null;
      _successMessage = null;
      _registerThrottled = result['status_code'] == 429;
      _registerRetryAfterSeconds = _registerThrottled
          ? result['retry_after_seconds'] as int?
          : null;
    }

    notifyListeners();
    return result['success'];
  }

  /// Login user
  Future<bool> login({required String identifier, required String password}) async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    final result = await _authService.login(identifier: identifier, password: password);

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      _isLoggedIn = true;
      _error = null;
      _errorCode = null;
    } else {
      _error = result['message'];
      _errorCode = result['error_code']?.toString();
      _isLoggedIn = false;
    }

    notifyListeners();
    return result['success'];
  }

  /// Request a password reset email.
  Future<bool> requestPasswordReset({required String email}) async {
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    final result = await _authService.requestPasswordReset(email: email);

    _isLoading = false;

    if (result['success']) {
      _error = null;
      _lastMessage = result['message'];
    } else {
      _error = result['message'];
    }

    notifyListeners();
    return result['success'];
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _user = null;
    _isLoggedIn = false;
    _error = null;
    _errorCode = null;

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh access token.
  ///
  /// Returns false both when the refresh failed due to a network issue
  /// (session kept intact) and when the server explicitly invalidated the
  /// session (session cleared). Callers that redirect to the login screen
  /// on failure should check [isLoggedIn] afterwards to tell the two apart.
  Future<bool> refreshToken() async {
    final success = await _authService.refreshAccessToken();
    if (!success) {
      final stillHasSession = await _authService.isLoggedIn();
      if (!stillHasSession) {
        _isLoggedIn = false;
        _user = null;
      }
    }
    notifyListeners();
    return success;
  }
}
