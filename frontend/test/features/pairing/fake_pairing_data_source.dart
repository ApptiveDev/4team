import 'package:life_record/features/pairing/data/pairing_data_source.dart';

class FakePairingDataSource implements PairingDataSource {
  FakePairingDataSource({
    this.inviteCode = '482913',
    this.invitationError,
    this.joinError,
    this.pairedAfterChecks = 1,
  });

  final String inviteCode;
  final Object? invitationError;
  final Object? joinError;

  /// isPaired가 몇 번째 호출부터 true를 돌려줄지
  final int pairedAfterChecks;

  int pairedChecks = 0;
  final joinedCodes = <String>[];

  @override
  Future<Map<String, dynamic>> createInvitation() async {
    final e = invitationError;
    if (e != null) throw e;
    return {
      'invitationId': 'inv_test',
      'inviteCode': inviteCode,
      'expiresAt': '2026-09-26T21:10:00+09:00',
    };
  }

  @override
  Future<Map<String, dynamic>> join(String code) async {
    joinedCodes.add(code);
    final e = joinError;
    if (e != null) throw e;
    return {
      'pair': {'id': 'pair_test'},
    };
  }

  @override
  Future<bool> isPaired() async => ++pairedChecks >= pairedAfterChecks;
}
