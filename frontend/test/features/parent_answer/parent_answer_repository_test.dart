import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/parent_answer/data/parent_answer_data_source.dart';
import 'package:life_record/features/parent_answer/data/parent_answer_repository_impl.dart';

class _Source implements ParentAnswerDataSource {
  Map<String, dynamic> json = {
    'viewerRole': 'PARENT',
    'assignment': {
      'question': {'text': '질문'},
    },
    'revealStatus': 'WAITING_FOR_CHILD',
    'canViewPartnerAnswer': false,
    'partnerAnswer': {'type': 'TEXT', 'answerId': 'ans_1', 'text': '비공개 답변'},
  };
  @override
  Future<Map<String, dynamic>> getToday() async => json;
  @override
  Future<Map<String, dynamic>> getAudio(String answerId) async => {
    'ttsStatus': 'READY',
    'audioUrl': 'https://example.test',
    'audioExpiresAt': '2026-09-25T12:00:00+09:00',
  };
}

void main() {
  test('서버가 비공개로 표시하면 포함된 답변도 노출하지 않는다', () async {
    final result = await ParentAnswerRepositoryImpl(_Source()).getToday();
    expect(result.canView, isFalse);
    expect(result.text, isNull);
    expect(result.answerId, isNull);
  });

  test('자녀 관점의 응답은 부모 화면에서 거절한다', () async {
    final source = _Source()..json['viewerRole'] = 'CHILD';
    await expectLater(
      ParentAnswerRepositoryImpl(source).getToday(),
      throwsA(isA<ApiException>()),
    );
  });

  test('음성 URL 만료 시각의 시간대를 보존한다', () async {
    final audio = await ParentAnswerRepositoryImpl(_Source()).getAudio('ans_1');
    expect(audio.expiresAt, DateTime.utc(2026, 9, 25, 3));
  });
}
