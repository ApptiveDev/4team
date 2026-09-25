import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'auth_data_source.dart';
import 'device_id_storage.dart';
import 'sign_up_response.dart';
import 'user_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._dataSource,
    required this._deviceIdStorage,
    required this._tokenStorage,
    required this._userStorage,
  });

  final AuthDataSource _dataSource;
  final DeviceIdStorage _deviceIdStorage;
  final TokenStorage _tokenStorage;
  final UserStorage _userStorage;

  @override
  Future<AppUser> signUp({required String name, required UserRole role}) async {
    final deviceId = await _deviceIdStorage.getOrCreate();
    final json = await _dataSource.signUp(
      name: name.trim(),
      role: role.apiValue,
      deviceId: deviceId,
    );
    final response = SignUpResponse.fromJson(json);

    await _tokenStorage.save(response.accessToken);
    await _userStorage.save(response.user);
    return response.user;
  }
}
