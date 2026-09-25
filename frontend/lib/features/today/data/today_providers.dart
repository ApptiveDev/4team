import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../onboarding/data/auth_providers.dart';
import 'today_data_source.dart';

final todayDataSourceProvider = Provider<TodayDataSource>((ref) {
  if (AppConfig.useMock) {
    return MockTodayDataSource(ref.read(userStorageProvider));
  }
  return ApiTodayDataSource(ref.read(dioProvider));
});
