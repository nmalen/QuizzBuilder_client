import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  
  // Common fields
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  // Register-only fields
  late TextEditingController _usernameController;
  late TextEditingController _password2Controller;

  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameController = TextEditingController();
    _password2Controller = TextEditingController();
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
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await authProvider.login(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password1: _passwordController.text,
        password2: _password2Controller.text,
      );

      if (mounted) {
        String message;
        if (success) {
          message = AppLocalizations.of(context)?.registrationSuccessful ??
            'Registration successful! Please check your email and click the link to validate your registration.';
        } else {
          // Show error from provider or fallback
          message = context.read<AuthProvider>().error ?? 'Registration failed. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 6),
          ),
        );

        if (success) {
          // Wait for SnackBar to show, then navigate
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => AuthScreen()),
              (route) => false,
            );
          }
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
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Title
                      Icon(
                        Icons.quiz,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.appTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? AppLocalizations.of(context)!.welcomeBack : AppLocalizations.of(context)!.createAccount,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Error Message
                      if (authProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
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
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateIdentifier,
                              enabled: !authProvider.isLoading,
                              decoration: InputDecoration(
                                hintText: '${AppLocalizations.of(context)!.email} ${AppLocalizations.of(context)!.username}',
                                hintStyle: TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.email, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 16),

                            // Username Field (Register only)
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _usernameController,
                                validator: _validateUsername,
                                enabled: !authProvider.isLoading,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.username,
                                  hintStyle: TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
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
                                hintText: AppLocalizations.of(context)!.password,
                                hintStyle: TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
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
                                  hintText: AppLocalizations.of(context)!.confirmPassword,
                                  hintStyle: TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword2 ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword2 = !_obscurePassword2);
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.red),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                                        _isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.register,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
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
                                ? AppLocalizations.of(context)!.switchToRegister
                                : AppLocalizations.of(context)!.switchToLogin,
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
                                    // Clear error
                                    authProvider.error == null
                                        ? null
                                        : context.read<AuthProvider>();
                                  },
                            child: Text(
                              _isLogin ? AppLocalizations.of(context)!.register : AppLocalizations.of(context)!.login,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
