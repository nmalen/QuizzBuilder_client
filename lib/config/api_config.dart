/// API Configuration for QuizzBuilder
class ApiConfig {
  // Production API (used for all environments)
  static const String baseUrl = 'https://booksnotify.com/quizzbuilder/api/v1';
  
  // Endpoints
  static const String categoriesEndpoint = '/categories/';
  static const String themesEndpoint = '/themes/';
  static const String questionsEndpoint = '/questions/';
  static const String purchasesEndpoint = '/purchases/';
  static const String entitlementsEndpoint = '/entitlements/';
  static const String authRegisterEndpoint = '/auth/registration/';
  static const String authLoginEndpoint = '/auth/login/';
  static const String authLogoutEndpoint = '/auth/logout/';
  static const String authRefreshEndpoint = '/auth/refresh/';
  static const String authVerifyEmailEndpoint = '/auth/registration/verify-email/';
  static const String statisticsEndpoint = '/statistics/';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
