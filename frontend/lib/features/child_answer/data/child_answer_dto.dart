import '../domain/child_answer.dart';

class ChildAnswerResponseDto {
  const ChildAnswerResponseDto({
    required this.answerId,
    required this.assignmentId,
    required this.text,
    required this.submissionStatus,
    required this.ttsStatus,
    required this.submittedAt,
    required this.updatedAt,
  });

  factory ChildAnswerResponseDto.fromJson(Map<String, dynamic> json) {
    return ChildAnswerResponseDto(
      answerId: json['answerId'] as String,
      assignmentId: json['assignmentId'] as String,
      text: json['text'] as String,
      submissionStatus: json['submissionStatus'] as String,
      ttsStatus: json['ttsStatus'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String answerId;
  final String assignmentId;
  final String text;
  final String submissionStatus;
  final String ttsStatus;
  final DateTime submittedAt;
  final DateTime updatedAt;

  ChildAnswer toDomain() => ChildAnswer(
    answerId: answerId,
    assignmentId: assignmentId,
    text: text,
    submittedAt: submittedAt,
    updatedAt: updatedAt,
  );
}
