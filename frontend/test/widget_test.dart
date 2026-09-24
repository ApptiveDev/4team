import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_record/app/app.dart';

void main() {
  testWidgets('앱 실행 시 가입 화면이 표시된다', (WidgetTester tester) async {
    // 앱 띄우기 (main.dart와 똑같이 ProviderScope로 감싸기)
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle(); // 화면 이동이 끝날 때까지 대기

    // 첫 화면(/onboarding)의 제목이 보이는지 확인
    expect(find.text('역할 선택·가입'), findsOneWidget);
  });
}