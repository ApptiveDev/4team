import 'package:life_record/features/pairing/data/pairing_data_source.dart';

class FakePairingDataSource implements PairingDataSource {
  FakePairingDataSource({
    this.inviteCode = '482913',
    this.expiresAt = '2099-09-26T21:10:00+09:00',
    this.nextInvitations = const [],
    this.invitationError,
    this.joinError,
    this.pairedAfterChecks = 1,
  });

  final String inviteCode;
  final String expiresAt;

  /// 두 번째 발급부터 돌려줄 (숫자, 만료 시각). 다 쓰면 마지막 것을 계속 준다.
  final List<(String, String)> nextInvitations;
  int invitationCalls = 0;
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
    final n = invitationCalls++;
    final (code, expires) = n == 0 || nextInvitations.isEmpty
        ? (inviteCode, expiresAt)
        : nextInvitations[(n - 1).clamp(0, nextInvitations.length - 1)];
    return {
      'invitationId': 'inv_test_$n',
      'inviteCode': code,
      'expiresAt': expires,
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
