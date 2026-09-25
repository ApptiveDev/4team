import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/features/onboarding/data/user_storage.dart';
import 'package:life_record/features/onboarding/domain/app_user.dart';
import 'package:life_record/features/pairing/data/pairing_repository_impl.dart';

import 'fake_pairing_data_source.dart';

const _child = AppUser(
  id: 'usr_child',
  name: '김민지',
  role: UserRole.child,
  pairingStatus: PairingStatus.unpaired,
);

void main() {
  late UserStorage userStorage;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    userStorage = UserStorage(const FlutterSecureStorage());
    await userStorage.save(_child);
  });

  test('초대 코드와 만료 시각을 읽는다', () async {
    final repo = PairingRepositoryImpl(FakePairingDataSource(), userStorage);

    final invitation = await repo.createInvitation();

    expect(invitation.inviteCode, '482913');
    expect(invitation.expiresAt, DateTime.parse('2026-09-26T21:10:00+09:00'));
  });

  test('연결에 성공하면 저장된 사용자를 PAIRED로 바꾼다', () async {
    final dataSource = FakePairingDataSource();
    final repo = PairingRepositoryImpl(dataSource, userStorage);

    await repo.join('482913');

    expect(dataSource.joinedCodes, ['482913']);
    expect((await userStorage.read())?.isPaired, isTrue);
  });

  test('아직 연결 전이면 저장된 사용자를 바꾸지 않는다', () async {
    final repo = PairingRepositoryImpl(
      FakePairingDataSource(pairedAfterChecks: 2),
      userStorage,
    );

    expect(await repo.isPaired(), isFalse);
    expect((await userStorage.read())?.isPaired, isFalse);

    expect(await repo.isPaired(), isTrue);
    expect((await userStorage.read())?.isPaired, isTrue);
  });
}
