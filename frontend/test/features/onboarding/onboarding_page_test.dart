import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/app/app.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/onboarding/data/auth_providers.dart';
import 'package:life_record/features/pairing/data/pairing_providers.dart';

import '../pairing/fake_pairing_data_source.dart';
import 'fake_auth_data_source.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  FakeAuthDataSource dataSource,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authDataSourceProvider.overrideWithValue(dataSource),
        pairingDataSourceProvider.overrideWithValue(
          FakePairingDataSource(pairedAfterChecks: 99),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

FilledButton _startButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('역할을 고르면 이름 입력으로 넘어가고, 뒤로 가면 다시 고를 수 있다', (tester) async {
    await _pumpApp(tester, FakeAuthDataSource());

    await tester.tap(find.text('부모님'));
    await tester.pumpAndSettle();
    expect(find.text('성함을 알려주세요'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('누가 사용하시나요?'), findsOneWidget);
  });

  testWidgets('이름이 비어 있거나 공백뿐이면 시작하기를 누를 수 없다', (tester) async {
    await _pumpApp(tester, FakeAuthDataSource());
    await tester.tap(find.text('자녀'));
    await tester.pumpAndSettle();

    expect(_startButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(_startButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '김민지');
    await tester.pump();
    expect(_startButton(tester).onPressed, isNotNull);
  });

  testWidgets('가입하면 페어링 화면으로 이동한다', (tester) async {
    final dataSource = FakeAuthDataSource();
    await _pumpApp(tester, dataSource);

    await tester.tap(find.text('자녀'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '김민지');
    await tester.pump();
    await tester.tap(find.text('시작하기'));
    // 페어링 화면은 연결 대기 표시가 계속 돌아서 pumpAndSettle 대신 시간을 넘긴다
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(dataSource.requests.single['role'], 'CHILD');
    expect(find.text('부모님을 초대해 주세요'), findsOneWidget);
  });

  testWidgets('이미 연결된 사용자는 오늘 질문으로 이동한다', (tester) async {
    await _pumpApp(tester, FakeAuthDataSource(pairingStatus: 'PAIRED'));

    await tester.tap(find.text('부모님'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '김영희');
    await tester.pump();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 질문'), findsOneWidget);
  });

  testWidgets('서버가 400을 주면 안내하고 입력한 이름을 유지한다', (tester) async {
    await _pumpApp(
      tester,
      FakeAuthDataSource(error: ApiException(statusCode: 400)),
    );

    await tester.tap(find.text('자녀'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '김민지');
    await tester.pump();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('이름을 다시 확인해 주세요.'), findsOneWidget);
    expect(find.text('김민지'), findsOneWidget);
    expect(_startButton(tester).onPressed, isNotNull); // 다시 시도 가능
  });

  testWidgets('네트워크가 끊기면 연결 확인 안내를 보여준다', (tester) async {
    await _pumpApp(tester, FakeAuthDataSource(error: ApiException()));

    await tester.tap(find.text('부모님'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '김영희');
    await tester.pump();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('인터넷 연결을 확인해 주세요.'), findsOneWidget);
  });
}
