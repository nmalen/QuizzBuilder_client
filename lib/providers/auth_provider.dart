import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required AuthService authService}) : _authService = authService;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize auth state from stored data
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.initialize();
      
      if (await _authService.isLoggedIn()) {
        _user = await _authService.getStoredUser();
        _isLoggedIn = true;
      }
    } catch (e) {
      _error = 'Initialization error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      username: username,
      password1: password1,
      password2: password2,
    );

    _isLoading = false;

    if (result['success']) {
      _error = null;
    } else {
      _error = result['message'];
    }

    notifyListeners();
    return result['success'];
  }

  /// Login user
  Future<bool> login({required String identifier, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(identifier: identifier, password: password);

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      _isLoggedIn = true;
      _error = null;
    } else {
      _error = result['message'];
      _isLoggedIn = false;
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

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    final success = await _authService.refreshAccessToken();
    if (!success) {
      _isLoggedIn = false;
      _user = null;
    }
    notifyListeners();
    return success;
  }
}
