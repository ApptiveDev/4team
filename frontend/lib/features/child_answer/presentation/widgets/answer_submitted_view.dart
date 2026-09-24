import 'package:flutter/material.dart';

/// 제출 완료 화면. 공개 여부는 여기서 판단하지 않고 홈(GET /today)에 맡긴다.
/// 상대를 재촉하는 문구는 쓰지 않는다.
class AnswerSubmittedView extends StatelessWidget {
  const AnswerSubmittedView({
    super.key,
    required this.answerText,
    required this.onEdit,
    required this.onHome,
  });

  final String answerText;
  final VoidCallback onEdit;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '답변을 보냈어요',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '홈에서 오늘의 이야기를 확인할 수 있어요.\n공개되기 전까지는 답변을 고칠 수 있어요.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(answerText, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onHome, child: const Text('홈으로')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('답변 수정하기'),
        ),
      ],
    );
  }
}
