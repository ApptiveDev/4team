import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/parent_answer/domain/parent_answer.dart';
import 'package:life_record/features/parent_answer/presentation/parent_answer_controller.dart';

import 'fake_parent_answer_repository.dart';

void main() {
  late FakeParentAnswerRepository repository;
  late ParentAnswerController controller;
  setUp(() {
    repository = FakeParentAnswerRepository();
    controller = ParentAnswerController(repository);
  });
  tearDown(() => controller.dispose());

  testWidgets('비공개 상태에서는 TTS를 조회하지 않는다', (tester) async {
    repository.today = const ParentAnswer(
      questionText: '질문',
      revealStatus: 'WAITING_FOR_CHILD',
      canView: false,
    );
    await controller.load();
    expect(repository.audioCalls, 0);
    expect(controller.answer!.canView, isFalse);
  });

  testWidgets('TTS 실패와 네트워크 오류에서도 글은 남는다', (tester) async {
    repository.audio = const AnswerAudio(status: AnswerTtsStatus.failed);
    await controller.load();
    await tester.pump();
    expect(controller.answer!.text, '자녀의 답변');
    expect(controller.audioMessage, contains('글로'));
    repository.audioError = ApiException();
    controller.retryAudio();
    await tester.pump();
    expect(controller.answer!.text, '자녀의 답변');
    expect(controller.audioMessage, isNotNull);
  });

  testWidgets('TTS는 60초 후 자동 조회를 멈춘다', (tester) async {
    repository.audio = const AnswerAudio(status: AnswerTtsStatus.processing);
    await controller.load();
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
    final count = repository.audioCalls;
    await tester.pump(const Duration(seconds: 30));
    expect(repository.audioCalls, count);
    expect(controller.audioLoading, isFalse);
    expect(controller.answer!.text, isNotNull);
  });

  testWidgets('백그라운드 요청 결과는 버리고 복귀 시 공개 상태부터 조회한다', (tester) async {
    repository.audioGate = Completer<AnswerAudio>();
    await controller.load();
    controller.setForeground(false);
    repository.audioGate!.complete(
      const AnswerAudio(status: AnswerTtsStatus.ready, url: 'https://old.test'),
    );
    await tester.pump();
    expect(controller.audio, isNull);
    repository.audioGate = null;
    repository.today = const ParentAnswer(
      questionText: '질문',
      revealStatus: 'WAITING_FOR_CHILD',
      canView: false,
    );
    controller.setForeground(true);
    await tester.pump();
    expect(repository.todayCalls, 2);
    expect(controller.answer!.canView, isFalse);
  });

  testWidgets('만료된 주소를 갱신할 때 새 URL을 반환한다', (tester) async {
    await controller.load();
    await tester.pump();
    repository.audio = const AnswerAudio(
      status: AnswerTtsStatus.ready,
      url: 'https://new.test',
    );
    expect((await controller.refreshAudioSource()).url, 'https://new.test');
  });

  testWidgets('403 응답이면 이전 글과 음성을 지운다', (tester) async {
    await controller.load();
    await tester.pump();
    repository.audioError = ApiException(statusCode: 403);
    controller.retryAudio();
    await tester.pump();
    expect(controller.answer, isNull);
    expect(controller.audio, isNull);
    expect(controller.errorStatus, 403);
  });

  testWidgets('오늘 질문이 없으면 빈 상태 안내를 표시한다', (tester) async {
    repository.todayError = ApiException(
      statusCode: 404,
      errorCode: 'TODAY_ASSIGNMENT_NOT_FOUND',
    );
    await controller.load();
    expect(controller.empty, isTrue);
    expect(controller.message, contains('아직'));
  });
}
