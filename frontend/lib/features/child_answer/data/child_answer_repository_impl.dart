import '../domain/answer_validator.dart';
import '../domain/child_answer.dart';
import '../domain/child_answer_repository.dart';
import 'child_answer_data_source.dart';
import 'child_answer_dto.dart';

class ChildAnswerRepositoryImpl implements ChildAnswerRepository {
  ChildAnswerRepositoryImpl(this._dataSource);
  final ChildAnswerDataSource _dataSource;

  @override
  Future<ChildAnswer> submit({
    required String assignmentId,
    required String text,
  }) async {
    final json = await _dataSource.putChildAnswer(
      assignmentId: assignmentId,
      text: AnswerValidator.normalize(text), // 앞뒤 공백 제거 후 전송
    );
    return ChildAnswerResponseDto.fromJson(json).toDomain();
  }
}
