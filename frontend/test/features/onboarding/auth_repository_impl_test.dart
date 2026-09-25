import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/storage/token_storage.dart';
import 'package:life_record/features/onboarding/data/auth_repository_impl.dart';
import 'package:life_record/features/onboarding/data/device_id_storage.dart';
import 'package:life_record/features/onboarding/data/user_storage.dart';
import 'package:life_record/features/onboarding/domain/app_user.dart';

import 'fake_auth_data_source.dart';

void main() {
  const secure = FlutterSecureStorage();
  late FakeAuthDataSource dataSource;
  late TokenStorage tokenStorage;
  late UserStorage userStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dataSource = FakeAuthDataSource();
    tokenStorage = TokenStorage(secure);
    userStorage = UserStorage(secure);
    repository = AuthRepositoryImpl(
      dataSource: dataSource,
      deviceIdStorage: DeviceIdStorage(secure),
      tokenStorage: tokenStorage,
      userStorage: userStorage,
    );
  });

  test('가입하면 토큰과 사용자 정보를 저장한다', () async {
    final user = await repository.signUp(name: '김민지', role: UserRole.child);

    expect(user.name, '김민지');
    expect(user.role, UserRole.child);
    expect(user.isPaired, isFalse);
    expect(await tokenStorage.read(), 'token_for_김민지');

    final saved = await userStorage.read();
    expect(saved?.id, 'usr_test');
    expect(saved?.role, UserRole.child);
  });

  test('이름 앞뒤 공백을 지우고 역할을 API 값으로 보낸다', () async {
    await repository.signUp(name: '  김영희 ', role: UserRole.parent);

    expect(dataSource.requests.single['name'], '김영희');
    expect(dataSource.requests.single['role'], 'PARENT');
  });

  test('다시 가입해도 같은 기기 ID를 보낸다', () async {
    await repository.signUp(name: '김영희', role: UserRole.parent);
    await repository.signUp(name: '김영희', role: UserRole.parent);

    final ids = dataSource.requests.map((r) => r['deviceId']).toSet();
    expect(ids, hasLength(1));
  });

  test('저장된 사용자 정보가 손상되면 비우고 null을 돌려준다', () async {
    FlutterSecureStorage.setMockInitialValues({'current_user': '{broken'});

    expect(await userStorage.read(), isNull);
    expect(await secure.read(key: 'current_user'), isNull);
  });
}
