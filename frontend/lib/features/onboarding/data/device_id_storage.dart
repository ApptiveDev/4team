import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 가입에 쓰는 기기 식별자. 한 번 만들면 앱을 지우기 전까지 유지한다.
class DeviceIdStorage {
  DeviceIdStorage(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  final FlutterSecureStorage _storage;
  final Random _random;
  static const _key = 'device_id';

  Future<String> getOrCreate() async {
    final saved = await _storage.read(key: _key);
    if (saved != null && saved.isNotEmpty) return saved;

    final created = generateUuidV4(_random);
    await _storage.write(key: _key, value: created);
    return created;
  }
}

/// RFC 4122 버전 4 UUID. 패키지를 추가하지 않으려고 직접 만든다.
String generateUuidV4(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
