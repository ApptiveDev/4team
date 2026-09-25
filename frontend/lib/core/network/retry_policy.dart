import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';

/// Riverpod 3은 실패한 provider를 기본으로 최대 10번 재시도한다.
/// 서버가 확정적으로 거절한 4xx(PAIR_NOT_FOUND, ALREADY_PAIRED 등)는 다시 불러도
/// 결과가 같으므로 재시도하지 않고, 연결 끊김·429·5xx만 최대 3번 재시도한다.
///
/// 사용: `FutureProvider(..., retry: retryTransientOnly)`
Duration? retryTransientOnly(int retryCount, Object error) {
  if (error is ApiException) {
    final status = error.statusCode;
    final transient = status == null || status == 429 || status >= 500;
    if (!transient) return null;
  }
  if (retryCount >= 3) return null;
  return ProviderContainer.defaultRetry(retryCount, error);
}
