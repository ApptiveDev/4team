import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/child_answer/data/child_answer_providers.dart';
import 'package:life_record/features/child_answer/presentation/child_answer_controller.dart';

import 'fake_child_answer_repository.dart';

void main() {
  late FakeChildAnswerRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeChildAnswerRepository();
    container = ProviderContainer(
      overrides: [childAnswerRepositoryProvider.overrideWithValue(repo)],
    );
    // autoDispose provider가 테스트 도중 사라지지 않게 구독을 걸어 둔다.
    container.listen(childAnswerControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  ChildAnswerController controller() =>
      container.read(childAnswerControllerProvider.notifier);
  ChildAnswerSubmitState state() =>
      container.read(childAnswerControllerProvider);

  test('처음 상태는 idle', () {
    expect(state().status, SubmitStatus.idle);
  });

  test('제출 성공하면 success와 결과를 가진다', () async {
    await controller().submit(assignmentId: 'asg_1', text: '숨바꼭질이요');

    expect(state().status, SubmitStatus.success);
    expect(state().result?.text, '숨바꼭질이요');
    expect(repo.calls, 1);
  });

  test('빈 답변은 요청을 보내지 않는다', () async {
    await controller().submit(assignmentId: 'asg_1', text: '   ');

    expect(repo.calls, 0);
    expect(state().status, SubmitStatus.idle);
  });

  test('제출 중에 다시 눌러도 요청은 한 번만 간다', () async {
    repo.gate = Completer<void>();

    final first = controller().submit(assignmentId: 'asg_1', text: '답변');
    expect(state().isSubmitting, isTrue);
    await controller().submit(assignmentId: 'asg_1', text: '답변');

    repo.gate!.complete();
    await first;
    expect(repo.calls, 1);
    expect(state().status, SubmitStatus.success);
  });

  test('ANSWER_LOCKED면 isLocked와 안내 문구', () async {
    repo.error = ApiException(statusCode: 409, errorCode: 'ANSWER_LOCKED');

    await controller().submit(assignmentId: 'asg_1', text: '답변');

    expect(state().status, SubmitStatus.failure);
    expect(state().isLocked, isTrue);
    expect(state().errorMessage, ChildAnswerController.lockedMessage);
  });

  test('VALIDATION_ERROR면 입력창용 문구', () async {
    repo.error = ApiException(statusCode: 400, errorCode: 'VALIDATION_ERROR');

    await controller().submit(assignmentId: 'asg_1', text: '답변');

    expect(state().fieldErrorMessage, ChildAnswerController.validationMessage);
    expect(state().errorMessage, isNull);
  });

  test('네트워크 오류면 연결 확인 문구', () async {
    repo.error = ApiException(); // statusCode 없음

    await controller().submit(assignmentId: 'asg_1', text: '답변');

    expect(state().status, SubmitStatus.failure);
    expect(state().errorMessage, '인터넷 연결을 확인해 주세요.');
  });

  test('수정 시작하면 idle로 돌아가고 이전 결과는 유지', () async {
    await controller().submit(assignmentId: 'asg_1', text: '첫 답변');
    controller().startEditing();

    expect(state().status, SubmitStatus.idle);
    expect(state().result?.text, '첫 답변');
  });
}
