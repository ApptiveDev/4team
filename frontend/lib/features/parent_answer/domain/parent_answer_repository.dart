import 'parent_answer.dart';

abstract class ParentAnswerRepository {
  Future<ParentAnswer> getToday();
  Future<AnswerAudio> getAudio(String answerId);
}
