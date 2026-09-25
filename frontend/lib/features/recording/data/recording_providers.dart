import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/recording_repository.dart';
import 'recording_data_source.dart';
import 'recording_repository_impl.dart';

final recordingDataSourceProvider = Provider<RecordingDataSource>(
  (ref) => AppConfig.useMock
      ? MockRecordingDataSource()
      : ApiRecordingDataSource(ref.read(dioProvider)),
);

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepositoryImpl(ref.read(recordingDataSourceProvider)),
);
