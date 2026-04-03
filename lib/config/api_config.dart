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
  static const String creditPacksEndpoint = '/credit-packs/';
  static const String userCreditsMeEndpoint = '/user-credits/me/';
  static const String creditPurchasesVerifyEndpoint =
      '/credit-purchases/verify/';
  static const String creditPurchasesRestoreEndpoint =
      '/credit-purchases/restore/';
  static const String dailyChallengeStatusEndpoint = '/daily-challenge/status/';
  static const String dailyChallengeQuestionsEndpoint =
      '/daily-challenge/questions/';
  static const String dailyChallengeCompleteEndpoint =
      '/daily-challenge/complete/';
  static const String authRegisterEndpoint = '/auth/registration/';
  static const String authLoginEndpoint = '/auth/login/';
  static const String authLogoutEndpoint = '/auth/logout/';
  static const String authAccountDeletionEndpoint = '/auth/account-deletion/';
    static const String authPasswordResetEndpoint = '/auth/password/reset/';
  static const String authRefreshEndpoint = '/auth/refresh/';
  static const String authVerifyEmailEndpoint =
      '/auth/registration/verify-email/';
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
