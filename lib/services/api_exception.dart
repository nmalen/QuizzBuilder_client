/// Thrown by services on a non-2xx API response, carrying the HTTP status
/// code so callers (providers/UI) can react to specific cases — e.g. 429
/// (rate limited) — without parsing exception message text.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => message;
}
