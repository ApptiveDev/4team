import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/recording/domain/recording.dart';
import 'package:life_record/features/recording/presentation/recording_args.dart';
import 'package:life_record/features/recording/presentation/recording_controller.dart';

import 'fakes.dart';

void main() {
  late FakeRecorder recorder;
  late FakeRecordingRepository repository;
  late RecordingController controller;
  late DateTime now;
  var serial = 0;

  setUp(() {
    recorder = FakeRecorder();
    repository = FakeRecordingRepository();
    now = DateTime(2026, 9, 25);
    controller = RecordingController(
      args: const RecordingArgs(assignmentId: 'asg_1', questionText: '질문'),
      repository: repository,
      recorder: recorder,
      now: () => now,
      createKey: () => 'key_${serial++}',
    );
  });
  tearDown(() => controller.dispose());

  testWidgets('권한 거부 시 녹음을 시작하지 않는다', (tester) async {
    recorder.permission = false;
    await controller.start();
    expect(recorder.starts, 0);
    expect(controller.phase, RecordingPhase.error);
    expect(controller.message, contains('마이크 권한'));
  });

  testWidgets('1초 미만 파일은 업로드하지 않는다', (tester) async {
    recorder.clip = const RecordedClip(
      path: '/tiny.m4a',
      duration: Duration(milliseconds: 500),
      bytes: 10,
    );
    await controller.start();
    await controller.stop();
    expect(repository.keys, isEmpty);
    expect(controller.hasDraft, isFalse);
  });

  testWidgets('업로드 재시도는 같은 키, 재녹음은 새 키를 쓴다', (tester) async {
    repository.uploadError = ApiException();
    await controller.start();
    await controller.stop();
    final first = repository.keys.single;
    expect(controller.hasDraft, isTrue);
    await controller.retryUpload();
    expect(repository.keys, [first, first]);
    await controller.start();
    repository.uploadError = null;
    await controller.stop();
    await tester.pump();
    expect(repository.keys.last, isNot(first));
    expect(controller.phase, RecordingPhase.ready);
  });

  testWidgets('업로드 중 중복 정지·재시도를 무시한다', (tester) async {
    repository.uploadGate = Completer<void>();
    await controller.start();
    final stopping = controller.stop();
    await tester.pump();
    await controller.stop();
    await controller.retryUpload();
    expect(repository.keys.length, 1);
    repository.uploadGate!.complete();
    await stopping;
  });

  testWidgets('60초가 되면 자동 정지하고 보낸다', (tester) async {
    await controller.start();
    now = now.add(const Duration(seconds: 60));
    await tester.pump(const Duration(milliseconds: 100));
    expect(recorder.stops, 1);
    expect(repository.keys.length, 1);
  });

  testWidgets('백그라운드에서 녹음을 멈추고 파일을 보관한다', (tester) async {
    await controller.start();
    controller.setForeground(false);
    await tester.pump();
    expect(recorder.stops, 1);
    expect(repository.keys, isEmpty);
    expect(controller.phase, RecordingPhase.draft);
    controller.setForeground(true);
    await controller.retryUpload();
    expect(repository.keys.length, 1);
  });

  testWidgets('마이크가 다른 앱에 중단되어도 자동 전송하지 않는다', (tester) async {
    await controller.start();
    recorder.interruptionController.add(null);
    // 스트림 구독이 FakeAsync 밖(setUp)에서 만들어져 실제 이벤트 루프를 한 번 돌린다
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(controller.phase, RecordingPhase.draft);
    expect(repository.keys, isEmpty);
  });

  testWidgets('AI 실패는 제출 성공과 녹음 ID를 유지한다', (tester) async {
    repository.status = ProcessingStatus.failed;
    await controller.start();
    await controller.stop();
    await tester.pump();
    expect(controller.phase, RecordingPhase.processingFailed);
    expect(controller.recordingId, 'rec_1');
    expect(controller.hasDraft, isFalse);
  });

  testWidgets('폴링은 3초에서 5초로 바뀌고 총 60초에 끝난다', (tester) async {
    repository.status = ProcessingStatus.llmProcessing;
    await controller.start();
    await controller.stop();
    await tester.pump();
    expect(repository.polls, 1);
    for (var i = 0; i < 10; i++) {
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
    }
    expect(repository.polls, 11);
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(repository.polls, 11);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(repository.polls, 12);
    now = now.add(const Duration(seconds: 25));
    await tester.pump(const Duration(seconds: 25));
    expect(controller.phase, RecordingPhase.delayed);
    final count = repository.polls;
    await tester.pump(const Duration(seconds: 30));
    expect(repository.polls, count);
  });

  testWidgets('백그라운드 응답은 버리고 복귀하면 다시 조회한다', (tester) async {
    repository.pollGate = Completer<RecordingResult>();
    await controller.start();
    await controller.stop();
    controller.setForeground(false);
    repository.pollGate!.complete(
      const RecordingResult(
        recordingId: 'rec_1',
        assignmentId: 'asg_1',
        status: ProcessingStatus.failed,
      ),
    );
    await tester.pump();
    expect(controller.result, isNull);
    repository.pollGate = null;
    controller.setForeground(true);
    await tester.pump();
    expect(controller.phase, RecordingPhase.ready);
  });

  testWidgets('ANSWER_LOCKED 이후 재녹음과 재전송을 막는다', (tester) async {
    repository.uploadError = ApiException(
      statusCode: 409,
      errorCode: 'ANSWER_LOCKED',
    );
    await controller.start();
    await controller.stop();
    expect(controller.locked, isTrue);
    expect(controller.canStart, isFalse);
    expect(controller.canRetryUpload, isFalse);
  });

  test('파일 크기와 길이 경계를 검사한다', () {
    expect(
      const RecordedClip(
        path: '/a',
        duration: Duration(seconds: 60),
        bytes: 10 * 1024 * 1024,
      ).validationMessage,
      isNull,
    );
    expect(
      const RecordedClip(
        path: '/a',
        duration: Duration(seconds: 61),
        bytes: 1,
      ).validationMessage,
      isNotNull,
    );
    expect(
      const RecordedClip(
        path: '/a',
        duration: Duration(seconds: 1),
        bytes: 10 * 1024 * 1024 + 1,
      ).validationMessage,
      isNotNull,
    );
  });
}
