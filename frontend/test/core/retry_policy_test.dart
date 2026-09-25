import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/core/network/retry_policy.dart';

void main() {
  test('서버가 거절한 4xx는 재시도하지 않는다', () {
    expect(
      retryTransientOnly(0, ApiException(statusCode: 409, errorCode: 'X')),
      isNull,
    );
    expect(retryTransientOnly(0, ApiException(statusCode: 404)), isNull);
  });

  test('연결 끊김·429·5xx는 3번까지 재시도한다', () {
    expect(retryTransientOnly(0, ApiException()), isNotNull);
    expect(retryTransientOnly(0, ApiException(statusCode: 429)), isNotNull);
    expect(retryTransientOnly(2, ApiException(statusCode: 503)), isNotNull);
    expect(retryTransientOnly(3, ApiException(statusCode: 503)), isNull);
  });
}
