import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/services/api_exception.dart';

void main() {
  test('reads the code and message of the error envelope', () {
    final e = ApiException.fromResponse(
      410,
      '{"error": {"code": "invitation_expired", "message": "Expired", "status_code": 410}}',
    );
    expect(e.code, 'invitation_expired');
    expect(e.message, 'Expired');
    expect(e.statusCode, 410);
  });

  test('a body without envelope keeps no code and the detail message', () {
    final e = ApiException.fromResponse(400, '{"detail": "Bad"}');
    expect(e.code, isNull);
    expect(e.message, 'Bad');
  });

  test('a non-JSON body does not throw and uses the fallback', () {
    final e = ApiException.fromResponse(502, '<html>bad gateway</html>');
    expect(e.code, isNull);
    expect(e.statusCode, 502);
    expect(e.message, 'Request failed');
  });

  test('existing call style still works (message + statusCode)', () {
    const e = ApiException('Too many', statusCode: 429);
    expect(e.isRateLimited, isTrue);
    expect(e.code, isNull);
    expect(e.isNetworkError, isFalse);
    expect(e.toString(), 'Too many');
  });

  test('network failures carry the network code', () {
    expect(const ApiException.network().isNetworkError, isTrue);
  });
}
