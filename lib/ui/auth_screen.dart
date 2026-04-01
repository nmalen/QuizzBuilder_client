import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class AuthScreen extends StatefulWidget {
  final String? infoMessage;
  const AuthScreen({super.key, this.infoMessage});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _infoShown = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _usernameController;
  late TextEditingController _password2Controller;
  // ...existing code...
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    debugPrint('[AuthScreen] initState');
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameController = TextEditingController();
    _password2Controller = TextEditingController();

    // Check if there's a pending success message from registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final successMsg = authProvider.successMessage;
      if (successMsg != null && successMsg.isNotEmpty) {
        debugPrint('[AuthScreen] found successMessage in provider: $successMsg');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)?.appTitle ?? 'Success',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.registrationSuccessful ??
                        'Registration successful! An email will be sent to you to activate your account. Please check your inbox and click the link to validate your registration.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  authProvider.clearSuccessMessage();
                  Navigator.of(ctx).pop();
                },
                child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              ),
            ],
          ),
        );
      }
    });

    // Affiche le message d'information dès l'arrivée sur l'écran (après la première frame)
    if (!_infoShown &&
        widget.infoMessage != null &&
        widget.infoMessage!.isNotEmpty) {
      _infoShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _showSnack(widget.infoMessage!);
      });
    }
  }

  void _showSnack(String message) {
    debugPrint('[AuthScreen] _showSnack called with: $message');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('[AuthScreen] showing alert dialog');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    debugPrint('[AuthScreen] _handleSubmit invoked, _isLogin=$_isLogin');
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await authProvider.login(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          // Navigation handled automatically by _AppRouter when auth state changes
          debugPrint('[AuthScreen] Login successful, _AppRouter will navigate to HomeScreen');
        } else {
          // Show error message when login fails
          final error = context.read<AuthProvider>().error;
          final message = error ?? 'Login failed. Please try again.';
          debugPrint('[AuthScreen] login failed, showing error: "$message"');
          _showSnack(message);
        }
      }
    } else {
      debugPrint('[AuthScreen] calling authProvider.register');
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password1: _passwordController.text,
        password2: _password2Controller.text,
      );

      debugPrint('[AuthScreen] AFTER await: success=$success, mounted=$mounted');
      if (mounted) {
        debugPrint('[AuthScreen] mounted is true AFTER rebuild');
      } else {
        debugPrint(
          '[AuthScreen] *** mounted is FALSE after await - widget was disposed! ***',
        );
      }

      if (mounted) {
        String message;
        if (success) {
          debugPrint('[AuthScreen] success branch ENTERED');
          // Use lastMessage from provider if available, else fallback to localized string
          debugPrint('[AuthScreen] registration success, preparing message');
          final backendMsg = context.read<AuthProvider>().lastMessage;
          message = (backendMsg != null && backendMsg.isNotEmpty)
              ? backendMsg
              : (AppLocalizations.of(context)?.registrationSuccessful ??
                    'Registration successful! Please check your email and click the link to validate your registration.');
          // Switch to login mode and show snackbar without leaving the screen
          if (mounted) {
            debugPrint('[AuthScreen] toggling to login and resetting form');
            setState(() {
              _isLogin = true;
              _formKey.currentState?.reset();
              _passwordController.clear();
              _password2Controller.clear();
            });
            debugPrint(
              '[AuthScreen] calling _showSnack with success message: "$message"',
            );
            _showSnack(message);
          }
        } else {
          final error = context.read<AuthProvider>().error;
          if (error != null && error.toLowerCase().contains('email')) {
            message =
                AppLocalizations.of(context)?.emailAlreadyExists ??
                'An account with this email already exists.';
          } else {
            message = error ?? 'Registration failed. Please try again.';
          }
          debugPrint(
            '[AuthScreen] registration failed, calling _showSnack with error: "$message"',
          );
          _showSnack(message);
        }
      }
    }
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or username is required';
    }
    final isEmail = value.contains('@');
    if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePasswordMatch(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // ...existing code...
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          actions: [
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: DropdownButton<String>(
                    value: languageProvider.languageCode,
                    dropdownColor: Theme.of(context).primaryColor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: const SizedBox.shrink(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        languageProvider.setLanguage(newValue);
                      }
                    },
                    items: <String>['en', 'fr'].map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              languageProvider.languageCode == value
                                  ? Icons.check_circle
                                  : Icons.language,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(value.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final screenHeight = MediaQuery.of(context).size.height;

            return Stack(
              children: [
                // Background gradient
                Container(
                  height: screenHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // NDSH Logo anchored to absolute bottom - keyboard will cover it
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: Image.asset(
                      'assets/images/Logo_NDSH_white.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Main scrollable content on top
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo & Title
                            Icon(Icons.quiz, size: 64, color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.appTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin
                                  ? AppLocalizations.of(context)!.welcomeBack
                                  : AppLocalizations.of(context)!.createAccount,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 32),

                            // Error Message
                            if (authProvider.error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  authProvider.error!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            if (authProvider.error != null)
                              const SizedBox(height: 16),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email/Username Field (Login) or Email Field (Register)
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateIdentifier,
                                    enabled: !authProvider.isLoading,
                                    decoration: InputDecoration(
                                      hintText: _isLogin
                                          ? AppLocalizations.of(context)!
                                              .emailOrUsername
                                          : AppLocalizations.of(context)!.email,
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: Icon(
                                        _isLogin ? Icons.person : Icons.email,
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Username Field (Register only)
                                  if (!_isLogin) ...[
                                    TextFormField(
                                      controller: _usernameController,
                                      validator: _validateUsername,
                                      enabled: !authProvider.isLoading,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.username,
                                        hintStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: _validatePassword,
                                    enabled: !authProvider.isLoading,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(
                                        context,
                                      )!.password,
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock,
                                        color: Colors.white70,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          );
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm Password Field (Register only)
                                  if (!_isLogin) ...[
                                    TextFormField(
                                      controller: _password2Controller,
                                      obscureText: _obscurePassword2,
                                      validator: _validatePasswordMatch,
                                      enabled: !authProvider.isLoading,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!.confirmPassword,
                                        hintStyle: TextStyle(
                                          color: Colors.white70,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock,
                                          color: Colors.white70,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword2
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white70,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword2 =
                                                  !_obscurePassword2,
                                            );
                                          },
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        backgroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.white54,
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _isLogin
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.login
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.register,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Toggle Login/Register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? AppLocalizations.of(
                                          context,
                                        )!.switchToRegister
                                      : AppLocalizations.of(
                                          context,
                                        )!.switchToLogin,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                GestureDetector(
                                  onTap: authProvider.isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isLogin = !_isLogin;
                                            _formKey.currentState?.reset();
                                            _emailController.clear();
                                            _passwordController.clear();
                                            _usernameController.clear();
                                            _password2Controller.clear();
                                          });
                                        },
                                  child: Text(
                                    _isLogin
                                        ? AppLocalizations.of(context)!.register
                                        : AppLocalizations.of(context)!.login,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
