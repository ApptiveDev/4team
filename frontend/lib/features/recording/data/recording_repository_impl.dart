import '../domain/recording.dart';
import '../domain/recording_repository.dart';
import 'recording_data_source.dart';
import 'recording_dto.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  RecordingRepositoryImpl(this._source);
  final RecordingDataSource _source;

  @override
  Future<RecordingSubmission> upload({
    required String assignmentId,
    required RecordedClip clip,
    required String idempotencyKey,
    required void Function(double progress) onProgress,
  }) async => submissionFromJson(
    await _source.upload(
      assignmentId: assignmentId,
      filePath: clip.path,
      idempotencyKey: idempotencyKey,
      onProgress: onProgress,
    ),
  );

  @override
  Future<RecordingResult> getStatus(String recordingId) async =>
      recordingFromJson(await _source.getStatus(recordingId));
}
