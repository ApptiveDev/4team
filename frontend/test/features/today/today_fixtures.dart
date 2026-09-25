import 'dart:convert';
import 'dart:io';

import 'package:life_record/features/today/data/today_data_source.dart';

/// assets/mocks/today_*.json을 그대로 읽는다 (계약 예시와 화면이 맞는지 확인용)
Map<String, dynamic> todayFixture(String name) =>
    jsonDecode(File('assets/mocks/today_$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// 부모가 보는 공개 상태 (계약 5.4 공개 예시를 부모 시점으로 바꾼 것)
Map<String, dynamic> parentRevealedFixture() {
  final json = todayFixture('revealed');
  final childAnswer = json['myAnswer'];
  json['viewerRole'] = 'PARENT';
  json['myAnswer'] = json['partnerAnswer'];
  json['partnerAnswer'] = childAnswer;
  return json;
}

class FakeTodayDataSource implements TodayDataSource {
  FakeTodayDataSource({this.json, this.error});

  /// 테스트 중 바꿔서 서버 상태 변화를 흉내 낸다
  Map<String, dynamic>? json;
  final Object? error;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchToday() async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return json!;
  }
}
