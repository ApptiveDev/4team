class ChildAnswer {
  const ChildAnswer({
    required this.answerId,
    required this.assignmentId,
    required this.text,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String answerId;
  final String assignmentId;
  final String text;
  final DateTime submittedAt;
  final DateTime updatedAt;
}
