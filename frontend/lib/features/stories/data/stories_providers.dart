import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/stories_repository.dart';
import 'stories_data_source.dart';
import 'stories_repository_impl.dart';

final storiesDataSourceProvider = Provider<StoriesDataSource>((ref) {
  if (AppConfig.useMock) return MockStoriesDataSource();
  return ApiStoriesDataSource(ref.read(dioProvider));
});

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepositoryImpl(ref.read(storiesDataSourceProvider));
});
