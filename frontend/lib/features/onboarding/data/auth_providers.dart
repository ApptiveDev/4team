import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import 'auth_data_source.dart';
import 'auth_repository_impl.dart';
import 'device_id_storage.dart';
import 'user_storage.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  if (AppConfig.useMock) return MockAuthDataSource();
  return ApiAuthDataSource(ref.read(dioProvider));
});

final deviceIdStorageProvider = Provider<DeviceIdStorage>(
  (ref) => DeviceIdStorage(const FlutterSecureStorage()),
);

final userStorageProvider = Provider<UserStorage>(
  (ref) => UserStorage(const FlutterSecureStorage()),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    dataSource: ref.read(authDataSourceProvider),
    deviceIdStorage: ref.read(deviceIdStorageProvider),
    tokenStorage: ref.read(tokenStorageProvider),
    userStorage: ref.read(userStorageProvider),
  ),
);
