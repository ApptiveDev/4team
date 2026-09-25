import '../../onboarding/data/user_storage.dart';
import '../../onboarding/domain/app_user.dart';
import '../domain/pairing_repository.dart';
import 'pairing_data_source.dart';

class PairingRepositoryImpl implements PairingRepository {
  PairingRepositoryImpl(this._dataSource, this._userStorage);

  final PairingDataSource _dataSource;
  final UserStorage _userStorage;

  @override
  Future<Invitation> createInvitation() async =>
      Invitation.fromJson(await _dataSource.createInvitation());

  @override
  Future<void> join(String inviteCode) async {
    await _dataSource.join(inviteCode);
    await _markPaired();
  }

  @override
  Future<bool> isPaired() async {
    final paired = await _dataSource.isPaired();
    if (paired) await _markPaired();
    return paired;
  }

  // 앱을 다시 켰을 때 페어링 화면을 건너뛸 수 있게 저장해 둔다.
  Future<void> _markPaired() async {
    final user = await _userStorage.read();
    if (user == null || user.isPaired) return;
    await _userStorage.save(user.copyWith(pairingStatus: PairingStatus.paired));
  }
}
