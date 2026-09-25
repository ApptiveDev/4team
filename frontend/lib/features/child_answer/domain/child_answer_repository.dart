import 'child_answer.dart';

abstract class ChildAnswerRepository {
  /// 신규 제출과 공개 전 수정 모두 같은 PUT으로 처리한다.
  Future<ChildAnswer> submit({
    required String assignmentId,
    required String text,
  });
}
