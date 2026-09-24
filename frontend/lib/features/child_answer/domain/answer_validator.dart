enum AnswerValidation { valid, empty, tooLong }

class AnswerValidator {
  const AnswerValidator._();

  static const int maxLength = 1000;

  static String normalize(String raw) => raw.trim();

  static int length(String raw) => normalize(raw).length;

  static AnswerValidation validate(String raw) {
    final len = length(raw);
    if (len == 0) return AnswerValidation.empty;
    if (len > maxLength) return AnswerValidation.tooLong;
    return AnswerValidation.valid;
  }
}
