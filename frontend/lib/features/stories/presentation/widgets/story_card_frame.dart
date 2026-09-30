import 'package:flutter/material.dart';

import '../../domain/story.dart';

/// 부모·자녀 카드가 같이 쓰는 틀: 날짜 + 질문 + 역할별 내용
class StoryCardFrame extends StatelessWidget {
  const StoryCardFrame({
    super.key,
    required this.story,
    required this.children,
  });
  final Story story;
  final List<Widget> children;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  /// 2026-09-24 → "9월 24일 목요일"
  static String formatDate(DateTime d) =>
      '${d.month}월 ${d.day}일 ${_weekdays[d.weekday - 1]}요일';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            ...children,
          ],
        ),
      ),
    );
  }
}

class AnswerSection extends StatelessWidget {
  const AnswerSection({super.key, required this.label, required this.text});
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

/// 부모 답을 화면에 보여줄 글로 바꾼다: 정리본 → 원문 → 안내 문구
String parentAnswerText(StoryParentAnswer parent) {
  final text = parent.displayText;
  if (text != null) return text;
  if (parent.isProcessing) return '글로 정리하고 있어요.';
  return '목소리로 남긴 답이에요.';
}
