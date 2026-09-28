import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// 디자인 기준 폰 화면(393×852)으로 맞춘다. 기본 테스트 화면(800×600)은
/// 폰보다 낮아서 아래쪽 버튼이 화면 밖으로 밀린다.
void usePhoneSize(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  addTearDown(tester.view.reset);
}
