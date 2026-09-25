import '../domain/recording.dart';

RecordingSubmission submissionFromJson(Map<String, dynamic> json) =>
    RecordingSubmission(
      recordingId: json['recordingId'] as String,
      assignmentId: json['assignmentId'] as String,
    );

RecordingResult recordingFromJson(Map<String, dynamic> json) => RecordingResult(
  recordingId: json['recordingId'] as String,
  assignmentId: json['assignmentId'] as String,
  status: ProcessingStatus.fromApi(json['processingStatus'] as String),
  sttText: json['sttText'] as String?,
  summaryText: json['summaryText'] as String?,
  processingNotice: json['processingNotice'] as String?,
);
