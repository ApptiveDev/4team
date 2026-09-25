import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/features/onboarding/data/device_id_storage.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('UUID v4 형식으로 만든다', () {
    final random = Random(1);
    for (var i = 0; i < 100; i++) {
      expect(generateUuidV4(random), matches(_uuidV4));
    }
  });

  test('처음 만든 기기 ID를 계속 돌려준다', () async {
    final storage = DeviceIdStorage(const FlutterSecureStorage());

    final first = await storage.getOrCreate();
    final second = await storage.getOrCreate();

    expect(first, matches(_uuidV4));
    expect(second, first);
  });

  test('이미 저장된 기기 ID가 있으면 그대로 쓴다', () async {
    FlutterSecureStorage.setMockInitialValues({'device_id': 'saved-id'});
    final storage = DeviceIdStorage(const FlutterSecureStorage());

    expect(await storage.getOrCreate(), 'saved-id');
  });
}
