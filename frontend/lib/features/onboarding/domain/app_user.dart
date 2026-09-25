enum UserRole {
  parent('PARENT'),
  child('CHILD');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole fromApi(String value) => UserRole.values.firstWhere(
    (role) => role.apiValue == value,
    orElse: () => throw FormatException('알 수 없는 role: $value'),
  );
}

enum PairingStatus {
  paired('PAIRED'),
  unpaired('UNPAIRED');

  const PairingStatus(this.apiValue);
  final String apiValue;

  static PairingStatus fromApi(String value) => PairingStatus.values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => throw FormatException('알 수 없는 pairingStatus: $value'),
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.pairingStatus,
  });

  final String id;
  final String name;
  final UserRole role;
  final PairingStatus pairingStatus;

  bool get isPaired => pairingStatus == PairingStatus.paired;

  // API 계약 5.1 `user` 객체와 같은 모양. 기기 저장에도 그대로 쓴다.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    role: UserRole.fromApi(json['role'] as String),
    pairingStatus: PairingStatus.fromApi(json['pairingStatus'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.apiValue,
    'pairingStatus': pairingStatus.apiValue,
  };
}
