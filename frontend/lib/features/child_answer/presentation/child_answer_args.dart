/// `/child-answer`로 이동할 때 오늘 홈(A)이 GoRouter extra로 넘기는 값.
/// 예: context.push('/child-answer', extra: ChildAnswerArgs(...))
class ChildAnswerArgs {
  const ChildAnswerArgs({
    required this.assignmentId,
    required this.questionText,
    this.initialText,
  });

  final String assignmentId;
  final String questionText;

  /// 이미 제출한 답변. 값이 있으면 수정 모드로 연다.
  final String? initialText;

  bool get isEditing => initialText != null;

  /// Mock 모드에서 홈 없이 /child-answer를 바로 열 때 쓰는 값.
  /// assets/mocks/today_*.json의 assignment와 같다.
  static const demo = ChildAnswerArgs(
    assignmentId: 'asg_01J8M90G3M9BT7PRD6X4CN9C0E',
    questionText: '어릴 때 가장 좋아했던 놀이는 무엇이었나요?',
  );
}
