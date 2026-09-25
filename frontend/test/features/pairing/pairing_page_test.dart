import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/onboarding/data/auth_providers.dart';
import 'package:life_record/features/onboarding/domain/app_user.dart';
import 'package:life_record/features/pairing/data/pairing_providers.dart';
import 'package:life_record/features/pairing/presentation/pairing_page.dart';

import 'fake_pairing_data_source.dart';

AppUser _user(UserRole role) => AppUser(
  id: 'usr_test',
  name: '테스트',
  role: role,
  pairingStatus: PairingStatus.unpaired,
);

Future<void> _pump(
  WidgetTester tester, {
  required AppUser? user,
  required FakePairingDataSource dataSource,
}) async {
  final router = GoRouter(
    initialLocation: '/pairing',
    routes: [
      GoRoute(path: '/pairing', builder: (_, _) => const PairingPage()),
      GoRoute(path: '/today', builder: (_, _) => const Text('오늘 화면')),
      GoRoute(path: '/onboarding', builder: (_, _) => const Text('가입 화면')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) async => user),
        pairingDataSourceProvider.overrideWithValue(dataSource),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
}

FilledButton _button(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('가입 정보가 없으면 가입 화면으로 보낸다', (tester) async {
    await _pump(tester, user: null, dataSource: FakePairingDataSource());
    await tester.pumpAndSettle();

    expect(find.text('가입 화면'), findsOneWidget);
  });

  group('자녀', () {
    testWidgets('초대 숫자를 세 자리씩 띄워 보여준다', (tester) async {
      await _pump(
        tester,
        user: _user(UserRole.child),
        dataSource: FakePairingDataSource(pairedAfterChecks: 99),
      );

      expect(find.text('482 913'), findsOneWidget);
      expect(find.text('부모님이 연결하면 자동으로 넘어가요.'), findsOneWidget);
    });

    testWidgets('부모님이 연결하면 오늘 화면으로 넘어간다', (tester) async {
      final dataSource = FakePairingDataSource(pairedAfterChecks: 2);
      await _pump(tester, user: _user(UserRole.child), dataSource: dataSource);

      await tester.pump(const Duration(seconds: 3)); // 첫 확인: 아직
      expect(find.text('오늘 화면'), findsNothing);

      await tester.pump(const Duration(seconds: 3)); // 두 번째 확인: 연결됨
      await tester.pumpAndSettle();
      expect(find.text('오늘 화면'), findsOneWidget);
    });

    testWidgets('이미 연결된 자녀는 바로 오늘 화면으로 넘어간다', (tester) async {
      await _pump(
        tester,
        user: _user(UserRole.child),
        dataSource: FakePairingDataSource(
          invitationError: ApiException(
            statusCode: 409,
            errorCode: 'ALREADY_PAIRED',
          ),
          pairedAfterChecks: 99,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 화면'), findsOneWidget);
    });
  });

  group('부모님', () {
    testWidgets('6자리를 다 넣어야 연결하기를 누를 수 있다', (tester) async {
      await _pump(
        tester,
        user: _user(UserRole.parent),
        dataSource: FakePairingDataSource(),
      );

      expect(_button(tester).onPressed, isNull);
      await tester.enterText(find.byType(TextField), '48291');
      await tester.pump();
      expect(_button(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '482913');
      await tester.pump();
      expect(_button(tester).onPressed, isNotNull);
    });

    testWidgets('연결에 성공하면 오늘 화면으로 넘어간다', (tester) async {
      final dataSource = FakePairingDataSource();
      await _pump(tester, user: _user(UserRole.parent), dataSource: dataSource);

      await tester.enterText(find.byType(TextField), '482913');
      await tester.pump();
      await tester.tap(find.text('연결하기'));
      await tester.pumpAndSettle();

      expect(dataSource.joinedCodes, ['482913']);
      expect(find.text('오늘 화면'), findsOneWidget);
    });

    testWidgets('이미 사용된 숫자면 새 숫자를 받으라고 안내한다', (tester) async {
      await _pump(
        tester,
        user: _user(UserRole.parent),
        dataSource: FakePairingDataSource(
          joinError: ApiException(
            statusCode: 409,
            errorCode: 'INVITE_CODE_USED',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '482913');
      await tester.pump();
      await tester.tap(find.text('연결하기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 사용된 숫자예요. 자녀에게 새 숫자를 받아 주세요.'), findsOneWidget);
      expect(find.text('오늘 화면'), findsNothing);

      // 다시 입력하면 안내가 사라진다
      await tester.enterText(find.byType(TextField), '111111');
      await tester.pump();
      expect(find.textContaining('이미 사용된'), findsNothing);
    });

    testWidgets('없는 숫자면 다시 확인하라고 안내한다', (tester) async {
      await _pump(
        tester,
        user: _user(UserRole.parent),
        dataSource: FakePairingDataSource(
          joinError: ApiException(
            statusCode: 404,
            errorCode: 'INVITE_CODE_NOT_FOUND',
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text('연결하기'));
      await tester.pumpAndSettle();

      expect(find.text('숫자를 다시 확인해 주세요.'), findsOneWidget);
    });
  });

  test('만료 시각을 오전·오후로 보여준다', () {
    expect(formatExpiry(DateTime(2026, 9, 26, 21, 10)), '9월 26일 오후 9:10');
    expect(formatExpiry(DateTime(2026, 9, 26, 0, 5)), '9월 26일 오전 12:05');
  });
}
