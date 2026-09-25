import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../onboarding/data/auth_providers.dart';
import '../domain/pairing_repository.dart';
import 'pairing_data_source.dart';
import 'pairing_repository_impl.dart';

final pairingDataSourceProvider = Provider<PairingDataSource>((ref) {
  if (AppConfig.useMock) return MockPairingDataSource();
  return ApiPairingDataSource(ref.read(dioProvider));
});

final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => PairingRepositoryImpl(
    ref.read(pairingDataSourceProvider),
    ref.read(userStorageProvider),
  ),
);
