import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/features/child_answer/domain/answer_validator.dart';

void main() {
  group('AnswerValidator', () {
    test('빈 문자열은 empty', () {
      expect(AnswerValidator.validate(''), AnswerValidation.empty);
    });

    test('공백·줄바꿈만 있으면 empty', () {
      expect(AnswerValidator.validate('   \n  '), AnswerValidation.empty);
    });

    test('1자는 valid', () {
      expect(AnswerValidator.validate('네'), AnswerValidation.valid);
    });

    test('정확히 1000자는 valid', () {
      expect(AnswerValidator.validate('가' * 1000), AnswerValidation.valid);
    });

    test('1001자는 tooLong', () {
      expect(AnswerValidator.validate('가' * 1001), AnswerValidation.tooLong);
    });

    test('앞뒤 공백은 글자 수에서 빠진다', () {
      final text = '  ${'가' * 1000}  ';
      expect(AnswerValidator.length(text), 1000);
      expect(AnswerValidator.validate(text), AnswerValidation.valid);
    });
  });
}
