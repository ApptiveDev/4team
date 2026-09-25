import 'dart:async';

import 'package:life_record/features/child_answer/domain/child_answer.dart';
import 'package:life_record/features/child_answer/domain/child_answer_repository.dart';

class FakeChildAnswerRepository implements ChildAnswerRepository {
  FakeChildAnswerRepository({this.error, this.gate});

  /// 값이 있으면 submit에서 이 에러를 던진다.
  Object? error;

  /// 값이 있으면 complete될 때까지 응답을 멈춘다. (제출 중 상태 테스트용)
  Completer<void>? gate;

  int calls = 0;
  String? lastText;

  @override
  Future<ChildAnswer> submit({
    required String assignmentId,
    required String text,
  }) async {
    calls++;
    lastText = text;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return ChildAnswer(
      answerId: 'ans_test',
      assignmentId: assignmentId,
      text: text.trim(),
      submittedAt: DateTime(2026, 9, 25, 9),
      updatedAt: DateTime(2026, 9, 25, 9),
    );
  }
}
