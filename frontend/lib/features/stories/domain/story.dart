/// 공개가 끝난 하루치 이야기 (질문 + 부모 답 + 자녀 답)
class Story {
  const Story({
    required this.storyId,
    required this.assignmentId,
    required this.assignedDate,
    required this.questionText,
    required this.questionCategory,
    required this.parentAnswer,
    required this.childAnswer,
    required this.revealedAt,
  });

  final String storyId;
  final String assignmentId;
  final DateTime assignedDate;
  final String questionText;
  final String questionCategory;
  final StoryParentAnswer parentAnswer;
  final StoryChildAnswer childAnswer;
  final DateTime revealedAt;
}

class StoryParentAnswer {
  const StoryParentAnswer({
    required this.recordingId,
    required this.processingStatus,
    this.originalAudioUrl,
    this.originalAudioExpiresAt,
    this.sttText,
    this.summaryText,
    this.processingNotice,
  });

  final String recordingId;
  final String processingStatus;
  final String? originalAudioUrl;
  final DateTime? originalAudioExpiresAt;
  final String? sttText;
  final String? summaryText;
  final String? processingNotice;

  /// 음성을 글로 정리하는 중인지 (READY·FAILED가 아니면 처리 중)
  bool get isProcessing =>
      processingStatus != 'READY' && processingStatus != 'FAILED';

  /// 화면에 보여줄 글: 정리본 → 원문 → 안내 문구 순
  String? get displayText => summaryText ?? sttText ?? processingNotice;
}

class StoryChildAnswer {
  const StoryChildAnswer({
    required this.answerId,
    required this.text,
    required this.ttsStatus,
  });

  final String answerId;
  final String text;
  final String ttsStatus;
}

/// 한 번에 불러온 목록 한 페이지
class StoryPage {
  const StoryPage({
    required this.items,
    required this.nextCursor,
    required this.hasNext,
  });

  final List<Story> items;
  final String? nextCursor;
  final bool hasNext;
}
