class Invitation {
  const Invitation({required this.inviteCode, required this.expiresAt});

  final String inviteCode;
  final DateTime expiresAt;

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
    inviteCode: json['inviteCode'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

abstract class PairingRepository {
  /// 자녀: 초대 코드 발급. 쓰지 않은 코드가 있으면 서버가 그 코드를 돌려준다.
  Future<Invitation> createInvitation();

  /// 부모: 초대 코드로 연결.
  Future<void> join(String inviteCode);

  /// 연결됐는지. 연결 API가 없어서 `GET /today`의 응답으로 판단한다.
  Future<bool> isPaired();
}
