import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../auth_service.dart';
import 'push_log.dart';

/// What came of a registration call.
enum DeviceCallResult {
  /// The server has it (204).
  done,

  /// Network, 5xx, 429, timeout: nothing visible, try again later.
  retryLater,

  /// 400 or 401: not worth repeating now (a 401 is the session's business).
  notAccepted,
}

/// `POST` / `DELETE /api/v1/notifications/devices/`: tells the server which
/// Firebase Installation ID of this phone gets the player's notifications.
///
/// The body field is named `token` but carries the **FID**, never an FCM
/// registration token. The FID is **never logged**. At most 30 calls an hour
/// per account (POST and DELETE together); beyond that the server answers 429.
class DeviceRegistrationApi {
  DeviceRegistrationApi({required this.authService, http.Client? client})
    : _client = client ?? http.Client();

  final AuthService authService;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  /// `platform` is `ios` or `android`.
  Future<DeviceCallResult> register(String installationId, String platform) =>
      _send('POST', {'token': installationId, 'platform': platform});

  Future<DeviceCallResult> unregister(String installationId) =>
      _send('DELETE', {'token': installationId});

  Future<DeviceCallResult> _send(
    String method,
    Map<String, String> body,
  ) async {
    try {
      final headers = await authService.getAuthHeaders();
      // Signed out: nothing to send (and the server would answer 401).
      if (!headers.containsKey('Authorization')) {
        pushLog('$method devices skipped: no signed-in session');
        return DeviceCallResult.notAccepted;
      }
      pushLog('$method devices attempted');
      final request =
          http.Request(
              method,
              Uri.parse(
                '${ApiConfig.baseUrl}${ApiConfig.notificationDevicesEndpoint}',
              ),
            )
            ..headers.addAll(headers)
            ..body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(_timeout);
      final status = streamed.statusCode;
      await streamed.stream.drain<void>();
      pushLog('$method devices answered HTTP $status');
      if (status == 204) return DeviceCallResult.done;
      return status == 400 || status == 401
          ? DeviceCallResult.notAccepted
          : DeviceCallResult.retryLater;
    } catch (e) {
      pushLog('$method devices failed: ${e.runtimeType}');
      return DeviceCallResult.retryLater;
    }
  }
}
