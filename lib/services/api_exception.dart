import 'dart:convert';

/// Thrown by services on a non-2xx API response, carrying the HTTP status
/// code so callers (providers/UI) can react to specific cases — e.g. 429
/// (rate limited) — without parsing exception message text.
///
/// When the API answers with its standard error envelope
/// (`{"error": {"code", "message", "status_code"}}`), the stable machine
/// readable [code] is carried too, so the UI can show a translated message
/// instead of the server text.
class ApiException implements Exception {
  /// Code used by [ApiException.network] when no HTTP answer was received.
  static const String networkErrorCode = 'network_error';

  final int? statusCode;
  final String message;

  /// Stable error code from the API envelope, or null when the response did
  /// not carry one (legacy endpoints, non-JSON body, network failure).
  final String? code;

  /// The envelope's `details` object when it carries one (e.g. the existing
  /// duel in a `duel_already_open` answer), else null.
  final Map<String, dynamic>? details;

  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.details,
  });

  /// Builds an exception from a non-2xx response, reading the `error`
  /// envelope when present. Never throws on a malformed body.
  factory ApiException.fromResponse(
    int statusCode,
    String body, {
    String fallbackMessage = 'Request failed',
  }) {
    String? code;
    String? message;
    Map<String, dynamic>? details;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          code = error['code']?.toString();
          message = error['message']?.toString();
          final rawDetails = error['details'];
          if (rawDetails is Map<String, dynamic>) details = rawDetails;
        }
        message ??= decoded['detail']?.toString();
      }
    } catch (_) {
      // Non-JSON body: keep the fallback message and no code.
    }
    return ApiException(
      message == null || message.isEmpty ? fallbackMessage : message,
      statusCode: statusCode,
      code: code,
      details: details,
    );
  }

  /// No HTTP answer: offline, timeout, TLS failure.
  const ApiException.network([String message = 'Network error'])
    : this(message, code: networkErrorCode);

  bool get isRateLimited => statusCode == 429;

  bool get isNetworkError => code == networkErrorCode;

  @override
  String toString() => message;
}
