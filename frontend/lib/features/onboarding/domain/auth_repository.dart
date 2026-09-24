import 'app_user.dart';

abstract class AuthRepository {
  /// 가입하고 access token과 사용자 정보를 기기에 저장한다.
  /// 같은 기기·역할로 다시 가입하면 서버가 기존 사용자를 돌려준다.
  Future<AppUser> signUp({required String name, required UserRole role});
}
