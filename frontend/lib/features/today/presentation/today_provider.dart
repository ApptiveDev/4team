import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/retry_policy.dart';
import '../data/today_providers.dart';
import '../domain/today.dart';

/// 오늘 질문과 제출·공개 상태 (`GET /today`).
///
/// 다른 화면에서 답을 제출한 뒤 홈을 갱신하려면:
/// `ref.invalidate(todayProvider);`
final todayProvider = FutureProvider.autoDispose<Today>((ref) async {
  final json = await ref.read(todayDataSourceProvider).fetchToday();
  return Today.fromJson(json);
}, retry: retryTransientOnly);
