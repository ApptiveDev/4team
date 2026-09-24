import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/child_answer_repository.dart';
import 'child_answer_data_source.dart';
import 'child_answer_repository_impl.dart';

final childAnswerDataSourceProvider = Provider<ChildAnswerDataSource>((ref) {
  if (AppConfig.useMock) return MockChildAnswerDataSource();
  return ApiChildAnswerDataSource(ref.read(dioProvider));
});

final childAnswerRepositoryProvider = Provider<ChildAnswerRepository>((ref) {
  return ChildAnswerRepositoryImpl(ref.read(childAnswerDataSourceProvider));
});
