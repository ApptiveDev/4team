import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/app/app.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/pairing/data/pairing_providers.dart';
import 'package:life_record/features/today/data/today_providers.dart';

import '../pairing/fake_pairing_data_source.dart';
import '../today/today_fixtures.dart';

Map<String, String> _stored({
  String? token = 'token',
  String role = 'CHILD',
  String pairingStatus = 'PAIRED',
}) => {
  'access_token': ?token,
  'current_user': jsonEncode({
    'id': 'usr_test',
    'name': '김민지',
    'role': role,
    'pairingStatus': pairingStatus,
  }),
};

Future<FakeTodayDataSource> _launch(
  WidgetTester tester, {
  required Map<String, String> stored,
  FakeTodayDataSource? today,
}) async {
  FlutterSecureStorage.setMockInitialValues(stored);
  final todaySource =
      today ?? FakeTodayDataSource(json: todayFixture('waiting_for_both'));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todayDataSourceProvider.overrideWithValue(todaySource),
        pairingDataSourceProvider.overrideWithValue(
          FakePairingDataSource(pairedAfterChecks: 99),
        ),
      ],
      child: const App(),
    ),
  );
  // 페어링 화면은 대기 표시가 계속 돌아서 pumpAndSettle 대신 시간을 넘긴다
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  return todaySource;
}

void main() {
  group('앱을 켰을 때', () {
    testWidgets('가입 정보가 없으면 역할 선택부터 시작한다', (tester) async {
      await _launch(tester, stored: {});

      expect(find.text('누가 사용하시나요?'), findsOneWidget);
    });

    testWidgets('연결된 사용자는 바로 오늘 질문으로 간다', (tester) async {
      await _launch(tester, stored: _stored());

      expect(find.text('어릴 때 가장 좋아했던 놀이는 무엇이었나요?'), findsOneWidget);
      expect(find.text('누가 사용하시나요?'), findsNothing);
    });

    testWidgets('연결 전 자녀는 페어링으로 간다', (tester) async {
      await _launch(tester, stored: _stored(pairingStatus: 'UNPAIRED'));

      expect(find.text('부모님을 초대해 주세요'), findsOneWidget);
    });

    testWidgets('토큰이 없으면 사용자 정보가 있어도 가입부터 한다', (tester) async {
      await _launch(tester, stored: _stored(token: null));

      expect(find.text('누가 사용하시나요?'), findsOneWidget);
    });
  });

  testWidgets('로그인이 만료되면(401) 정보를 지우고 가입 화면으로 보낸다', (tester) async {
    await _launch(
      tester,
      stored: _stored(),
      today: FakeTodayDataSource(
        error: ApiException(statusCode: 401, errorCode: 'TOKEN_EXPIRED'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('누가 사용하시나요?'), findsOneWidget);
    expect(find.textContaining('같은 역할을 고르면 이야기가 그대로 이어져요.'), findsOneWidget);

    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'access_token'), isNull);
    expect(await storage.read(key: 'current_user'), isNull);
  });
}
