import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/parent_answer_repository.dart';
import 'parent_answer_data_source.dart';
import 'parent_answer_repository_impl.dart';

final parentAnswerRepositoryProvider = Provider<ParentAnswerRepository>(
  (ref) => ParentAnswerRepositoryImpl(
    AppConfig.useMock
        ? MockParentAnswerDataSource()
        : ApiParentAnswerDataSource(ref.read(dioProvider)),
  ),
);
