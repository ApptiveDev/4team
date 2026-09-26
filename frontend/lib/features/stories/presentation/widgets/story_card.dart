import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/audio_playback_card.dart';
import '../../domain/story.dart';
import '../stories_controller.dart';

class StoryCard extends ConsumerWidget {
  const StoryCard({super.key, required this.story});
  final Story story;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  /// 2026-09-24 → "9월 24일 목요일"
  static String formatDate(DateTime d) =>
      '${d.month}월 ${d.day}일 ${_weekdays[d.weekday - 1]}요일';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parent = story.parentAnswer;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDate(story.assignedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(story.questionText, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            if (parent.originalAudioUrl != null) ...[
              AudioPlaybackCard(
                source: PlaybackSource(
                  parent.originalAudioUrl!,
                  expiresAt: parent.originalAudioExpiresAt,
                ),
                label: '부모님 목소리 듣기',
                onRefresh: () async {
                  final fresh = await ref
                      .read(storiesControllerProvider.notifier)
                      .fetchLatestParentAnswer(story.storyId);
                  if (fresh.originalAudioUrl == null) {
                    throw StateError('음성을 다시 불러오지 못했어요');
                  }
                  return PlaybackSource(
                    fresh.originalAudioUrl!,
                    expiresAt: fresh.originalAudioExpiresAt,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            _AnswerSection(
              label: '부모님의 답',
              text: _parentText(story.parentAnswer),
            ),
            const SizedBox(height: 16),
            _AnswerSection(label: '자녀의 답', text: story.childAnswer.text),
          ],
        ),
      ),
    );
  }

  static String _parentText(StoryParentAnswer parent) {
    final text = parent.displayText; // 정리본 → 원문 → 실패 안내
    if (text != null) return text;
    if (parent.isProcessing) return '글로 정리하고 있어요.';
    return '목소리로 남긴 답이에요.';
  }
}

class _AnswerSection extends StatelessWidget {
  const _AnswerSection({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
