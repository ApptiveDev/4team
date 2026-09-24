import 'package:life_record/features/onboarding/data/auth_data_source.dart';

/// 서버 대신 응답을 돌려주고, 받은 요청을 기록한다.
class FakeAuthDataSource implements AuthDataSource {
  FakeAuthDataSource({this.pairingStatus = 'UNPAIRED', this.error});

  final String pairingStatus;
  final Object? error;
  final requests = <Map<String, String>>[];

  @override
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String role,
    required String deviceId,
  }) async {
    requests.add({'name': name, 'role': role, 'deviceId': deviceId});
    final e = error;
    if (e != null) throw e;
    return {
      'user': {
        'id': 'usr_test',
        'name': name,
        'role': role,
        'pairingStatus': pairingStatus,
      },
      'accessToken': 'token_for_$name',
      'tokenType': 'Bearer',
      'expiresAt': '2026-10-24T09:00:00+09:00',
    };
  }
}
