# Authentication Implementation Guide

## Overview

The QuizzBuilder mobile app now implements a complete authentication system with persistent login support. Users are shown a login/signup screen on first launch, and after successful login, the app remembers their session using secure token storage.

## Architecture

### Components

1. **AuthService** (`services/auth_service.dart`)
   - Handles all API communication for authentication
   - Manages token storage using `flutter_secure_storage` (encrypted)
   - Manages user data storage using `shared_preferences`
   - Implements token refresh logic

2. **AuthProvider** (`providers/auth_provider.dart`)
   - State management using Provider package
   - Exposes authentication state to widgets
   - Handles UI state (loading, error, login/logout)

3. **SplashScreen** (`ui/splash_screen.dart`)
   - Displays on app startup
   - Checks if user is already logged in
   - Routes to either Auth screen or Home screen based on login state

4. **AuthScreen** (`ui/auth_screen.dart`)
   - Unified login/registration interface
   - Toggle between login and register modes
   - Form validation with error handling
   - Email verification guidance

## Flow Diagram

```
┌─────────────────────────────────────┐
│   App Start (main.dart)             │
│   - Initialize AuthService          │
│   - Create AuthProvider             │
└────────────────┬────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │  SplashScreen      │
        │  Check login state │
        └────────┬───────────┘
                 │
        ┌────────┴──────────┐
        │                   │
        ▼                   ▼
   ┌─────────┐       ┌──────────┐
   │AuthScreen│      │HomeScreen│
   │(No token)│      │(Has token)│
   └────┬────┘      └─────┬────┘
        │                 │
    ┌───┴────────┐        │
    │            │        │
    ▼            ▼        │
  Login      Register     │
    │            │        │
    └─────┬──────┘        │
          │               │
          └───────┬───────┘
                  │
          Store tokens & user
                  │
                  ▼
          ┌──────────────────┐
          │  Session Valid   │
          └──────────────────┘
```

## Key Features

### 1. Persistent Login
- **Access Token**: Stored securely in `FlutterSecureStorage` (encrypted)
- **Refresh Token**: Stored securely for token renewal
- **User Data**: Stored in `SharedPreferences` for quick access
- **Auto-Check**: On app startup, checks if user is already logged in

### 2. Token Management
- **Access Token**: Short-lived JWT for API requests
- **Refresh Token**: Used to obtain new access tokens without re-login
- **Token Refresh**: Automatic when token expires
- **Auto-Logout**: If refresh token is invalid/expired, user is logged out

### 3. Form Validation
- **Email**: Validates email format
- **Password**: Minimum 8 characters
- **Username**: Minimum 3 characters (register only)
- **Password Match**: Confirms password and confirm password match

### 4. Error Handling
- Network errors
- Invalid credentials
- Server errors
- Validation errors with specific messages

## API Integration

The implementation uses the backend JWT authentication endpoints:

```
POST /api/v1/auth/login/
  Input: { email, password }
  Response: { access, refresh, user }

POST /api/v1/auth/registration/
  Input: { email, username, password1, password2 }
  Response: { user, message }

POST /api/v1/auth/refresh/
  Input: { refresh }
  Response: { access }
```

**Backend Support**: ✅ Yes
- Django REST Framework with SimpleJWT
- Email verification integration
- Token-based authentication with refresh mechanism
- See `backend/config/urls.py` and `backend/config/views.py` for details

## Usage

### In Widgets

```dart
// Access auth state
final authProvider = Provider.of<AuthProvider>(context);

// Get current user
final user = authProvider.user;

// Check login status
if (authProvider.isLoggedIn) {
  // User is logged in
}

// Get error message
if (authProvider.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(authProvider.error!)),
  );
}
```

### Making Authenticated Requests

```dart
// Get auth headers (automatically includes Bearer token)
final headers = await authService.getAuthHeaders();

// Use in HTTP requests
final response = await http.get(
  Uri.parse('$baseUrl/api/categories/'),
  headers: headers,
);
```

### Manual Logout

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.logout();
```

## File Structure

```
lib/
├── services/
│   └── auth_service.dart          # API & token management
├── providers/
│   └── auth_provider.dart         # State management
├── ui/
│   ├── splash_screen.dart         # Startup screen
│   └── auth_screen.dart           # Login/Register screen
├── models/
│   └── user.dart                  # User model (existing)
└── main.dart                      # Updated with auth flow
```

## Testing the Implementation

### Test 1: First Launch (No Token)
1. Clear app data
2. Launch app
3. Should show SplashScreen for 2 seconds
4. Should show AuthScreen

### Test 2: Register New User
1. On AuthScreen, click "Register"
2. Enter email, username, password
3. Submit
4. Should show success message
5. Should switch back to Login form
6. Should NOT automatically login (email verification required)

### Test 3: Login with Valid Credentials
1. Enter registered email and password
2. Click Login
3. Should show loading state
4. Should navigate to HomeScreen
5. Should show user's display name

### Test 4: Persistent Login
1. Login successfully
2. Kill app (force close)
3. Relaunch app
4. Should skip AuthScreen and go directly to HomeScreen
5. User should still be logged in

### Test 5: Logout
1. On HomeScreen, click logout button
2. Should navigate back to AuthScreen
3. Tokens should be cleared

### Test 6: Invalid Credentials
1. Enter wrong email/password
2. Should show error message
3. Should not navigate to HomeScreen

## Security Considerations

1. **Secure Token Storage**
   - Access token and refresh token stored in `FlutterSecureStorage` (encrypted)
   - Not stored in plain text or SharedPreferences

2. **HTTPS Only**
   - All API calls should use HTTPS in production
   - Set `baseUrl` to production HTTPS endpoint in production build

3. **Token Refresh**
   - Automatic token refresh before expiry
   - Invalid refresh token triggers logout

4. **Password Validation**
   - Backend enforces 12+ character password requirement (see backend documentation)
   - Frontend enforces 8+ character minimum
   - Passwords never logged or stored in plain text

5. **CORS & Headers**
   - Authorization header automatically included in all authenticated requests
   - Content-Type header properly set for all requests

## Troubleshooting

### "Authentication failed" error
- Check backend is running and accessible
- Verify credentials are correct
- Check network connectivity

### Tokens not persisting
- Ensure `FlutterSecureStorage` is properly initialized
- Check platform-specific permissions (iOS Keychain, Android EncryptedSharedPreferences)

### Email verification issues
- User must verify email before logging in with that account
- Check email for verification link from backend
- Verify email endpoint is accessible

### Blank screen on startup
- AuthProvider initialization might be taking too long
- Check SharedPreferences and FlutterSecureStorage initialization
- Add debug logging to `AuthProvider.initialize()`

## Next Steps

1. **Email Verification UI**: Show email verification status on profile
2. **Password Reset**: Implement forgot password flow
3. **Social Login**: Add Google/Facebook authentication
4. **Biometric Authentication**: Add fingerprint/face ID support
5. **2FA**: Implement two-factor authentication
6. **Session Management**: Add session timeout and re-authentication prompts

## References

- [Provider Package Documentation](https://pub.dev/packages/provider)
- [FlutterSecureStorage](https://pub.dev/packages/flutter_secure_storage)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Backend Authentication Setup](../../backend/README.md)
