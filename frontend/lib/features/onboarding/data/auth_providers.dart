import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import 'auth_data_source.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  if (AppConfig.useMock) return MockAuthDataSource();
  return ApiAuthDataSource(ref.read(dioProvider));
});