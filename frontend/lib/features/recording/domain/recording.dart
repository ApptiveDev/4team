enum ProcessingStatus {
  uploaded('UPLOADED'),
  sttProcessing('STT_PROCESSING'),
  sttDone('STT_DONE'),
  llmProcessing('LLM_PROCESSING'),
  ready('READY'),
  failed('FAILED');

  const ProcessingStatus(this.apiValue);
  final String apiValue;
  bool get isTerminal => this == ready || this == failed;

  static ProcessingStatus fromApi(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => throw const FormatException('알 수 없는 녹음 상태'),
  );
}

class RecordingSubmission {
  const RecordingSubmission({
    required this.recordingId,
    required this.assignmentId,
  });
  final String recordingId;
  final String assignmentId;
}

class RecordingResult {
  const RecordingResult({
    required this.recordingId,
    required this.assignmentId,
    required this.status,
    this.sttText,
    this.summaryText,
    this.processingNotice,
  });
  final String recordingId;
  final String assignmentId;
  final ProcessingStatus status;
  final String? sttText;
  final String? summaryText;
  final String? processingNotice;
}

/// 파일은 서버가 업로드를 확인할 때까지 보관한다.
class RecordedClip {
  const RecordedClip({
    required this.path,
    required this.duration,
    required this.bytes,
  });
  final String path;
  final Duration duration;
  final int bytes;

  String? get validationMessage {
    if (duration < const Duration(seconds: 1) ||
        duration > const Duration(seconds: 60)) {
      return '1초 이상 60초 이하로 다시 녹음해 주세요.';
    }
    if (bytes <= 0) return '녹음된 소리가 없어요. 다시 녹음해 주세요.';
    if (bytes > 10 * 1024 * 1024) return '녹음 파일이 너무 커요. 다시 녹음해 주세요.';
    return null;
  }
}
