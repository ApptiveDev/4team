import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/features/recording/presentation/recording_args.dart';
import 'package:life_record/features/recording/presentation/recording_controller.dart';
import 'package:life_record/features/recording/presentation/recording_page.dart';

import 'fakes.dart';

void main() {
  const args = RecordingArgs(
    assignmentId: 'asg_1',
    questionText: '좋아했던 놀이는 무엇인가요?',
  );

  testWidgets('권한 거부 안내와 재시도 버튼을 표시한다', (tester) async {
    final recorder = FakeRecorder()..permission = false;
    final controller = RecordingController(
      args: args,
      repository: FakeRecordingRepository(),
      recorder: recorder,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RecordingPage(args: args, controller: controller),
        ),
      ),
    );
    expect(find.text(args.questionText), findsOneWidget);
    await tester.ensureVisible(find.text('말하기 시작'));
    await tester.tap(find.text('말하기 시작'));
    await tester.pumpAndSettle();
    expect(find.textContaining('마이크 권한이 필요해요'), findsOneWidget);
    expect(find.text('말하기 시작'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('녹음 상태를 아이콘뿐 아니라 글자로도 알린다', (tester) async {
    final controller = RecordingController(
      args: args,
      repository: FakeRecordingRepository(),
      recorder: FakeRecorder(),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RecordingPage(args: args, controller: controller),
        ),
      ),
    );
    await controller.start();
    await tester.pump();
    expect(find.textContaining('녹음 중'), findsOneWidget);
    expect(find.text('그만 말하고 보내기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
