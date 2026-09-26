import 'recording.dart';

abstract class RecordingRepository {
  Future<RecordingSubmission> upload({
    required String assignmentId,
    required RecordedClip clip,
    required String idempotencyKey,
    required void Function(double progress) onProgress,
  });
  Future<RecordingResult> getStatus(String recordingId);
}

/// 플러그인 없이 권한·녹음 실패를 테스트할 수 있는 경계.
abstract class RecorderService {
  Stream<void> get interruptions;
  Future<bool> hasPermission();
  Future<void> start();
  Future<RecordedClip> stop();
  Future<void> discard();
  Future<void> dispose();
}
