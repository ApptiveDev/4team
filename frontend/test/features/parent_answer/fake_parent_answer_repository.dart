import 'dart:async';

import 'package:life_record/features/parent_answer/domain/parent_answer.dart';
import 'package:life_record/features/parent_answer/domain/parent_answer_repository.dart';

class FakeParentAnswerRepository implements ParentAnswerRepository {
  ParentAnswer today = const ParentAnswer(
    questionText: '질문',
    revealStatus: 'REVEALED',
    canView: true,
    answerId: 'ans_1',
    text: '자녀의 답변',
  );
  AnswerAudio audio = const AnswerAudio(
    status: AnswerTtsStatus.ready,
    url: 'https://example.test/audio.mp3',
  );
  Object? todayError;
  Object? audioError;
  int audioCalls = 0;
  int todayCalls = 0;
  Completer<AnswerAudio>? audioGate;

  @override
  Future<ParentAnswer> getToday() async {
    todayCalls++;
    if (todayError != null) throw todayError!;
    return today;
  }

  @override
  Future<AnswerAudio> getAudio(String answerId) async {
    audioCalls++;
    if (audioError != null) throw audioError!;
    if (audioGate != null) return audioGate!.future;
    return audio;
  }
}
