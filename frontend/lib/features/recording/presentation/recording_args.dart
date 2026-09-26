/// A의 오늘 화면에서 GoRouter extra로 전달한다.
/// 예: await context.push('/recording', extra: RecordingArgs(...));
/// 복귀하면 오늘 상태를 다시 조회한다. 실제 API 모드에서는 인자가 필수다.
class RecordingArgs {
  const RecordingArgs({
    required this.assignmentId,
    required this.questionText,
    this.questionAudioUrl,
    this.recordingId,
    this.canRecord = true,
  });
  final String assignmentId;
  final String questionText;

  /// 질문 음성이 없으면 재생 버튼을 숨긴다.
  final String? questionAudioUrl;

  /// 기존 녹음이 있으면 진입 시 처리 상태를 다시 조회한다.
  final String? recordingId;

  /// 서버의 revealStatus가 REVEALED이면 false를 전달한다.
  final bool canRecord;

  /// Mock 재생은 실제 질문 대신 1초 테스트 소리를 사용한다.
  static const demo = RecordingArgs(
    assignmentId: 'asg_01J8M90G3M9BT7PRD6X4CN9C0E',
    questionText: '어릴 때 가장 좋아했던 놀이는 무엇이었나요?',
    questionAudioUrl: 'asset:///assets/audio/demo_tone.wav',
  );
}
