import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../child_answer/presentation/child_answer_args.dart';
import '../../child_answer/presentation/widgets/question_card.dart';
import '../../onboarding/presentation/session.dart';
import '../../onboarding/domain/app_user.dart';
import '../../recording/presentation/recording_args.dart';
import '../domain/today.dart';
import 'today_provider.dart';
import '../../../core/widgets/audio_playback_card.dart';

/// 오늘 질문 홈. 서버가 계산한 제출·공개 상태에 따라 다음 행동 하나를 보여준다.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(todayProvider, (_, next) {
      final e = next.error;
      if (e is ApiException && e.errorCode == 'PAIR_NOT_FOUND') {
        context.go('/pairing');
      } else if (e != null) {
        handleSessionExpired(context, ref, e);
      }
    });

    final today = ref.watch(todayProvider);
    return Scaffold(
      body: SafeArea(
        child: today.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _TodayError(error: e),
          data: (today) => RefreshIndicator(
            onRefresh: () => ref.refresh(todayProvider.future),
            child: _TodayContent(today: today),
          ),
        ),
      ),
    );
  }
}

class _TodayError extends ConsumerWidget {
  const _TodayError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = error;
    if (e is ApiException &&
        (e.errorCode == 'PAIR_NOT_FOUND' || e.statusCode == 401)) {
      return const Center(child: CircularProgressIndicator()); // 다른 화면으로 이동 중
    }
    final message = e is ApiException
        ? (e.errorCode == 'TODAY_ASSIGNMENT_NOT_FOUND'
              ? '오늘 질문을 준비하고 있어요.\n잠시 후 다시 확인해 주세요.'
              : e.userMessage)
        : '문제가 생겼어요. 다시 시도해 주세요.';
    return ErrorRetryView(
      message: message,
      onRetry: () => ref.invalidate(todayProvider),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({required this.today});
  final Today today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(), // 당겨서 새로고침
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Text(
          formatAssignedDate(today.assignedDate),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        QuestionCard(questionText: today.question.text),
        const SizedBox(height: 24),
        if (today.viewerRole == UserRole.child)
          _ChildSection(today: today)
        else
          _ParentSection(today: today),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: () => context.push('/stories'),
            icon: const Icon(Icons.menu_book),
            label: const Text('지난 이야기 보기'),
          ),
        ),
      ],
    );
  }
}

/// 다른 화면에 다녀온 뒤 홈을 새로 불러온다.
Future<void> _openAndRefresh(
  BuildContext context,
  WidgetRef ref,
  String location, {
  Object? extra,
}) async {
  await context.push(location, extra: extra);
  ref.invalidate(todayProvider);
}

class _ChildSection extends ConsumerWidget {
  const _ChildSection({required this.today});
  final Today today;

  void _openAnswer(BuildContext context, WidgetRef ref, String? initialText) {
    _openAndRefresh(
      context,
      ref,
      '/child-answer',
      extra: ChildAnswerArgs(
        assignmentId: today.assignmentId,
        questionText: today.question.text,
        initialText: initialText, // 이미 답했으면 수정 모드
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myText = switch (today.myAnswer) {
      TextAnswer(:final text) => text,
      _ => null,
    };

    if (!today.iAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Message('부모님과 같은 질문에 답해요.\n둘 다 답하면 서로의 답을 볼 수 있어요.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => _openAnswer(context, ref, null),
            child: const Text('답하기'),
          ),
        ],
      );
    }

    if (!today.isRevealed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (myText != null) _AnswerCard(label: '내 답', text: myText),
          const SizedBox(height: 16),
          const _Message('부모님이 답하시면\n여기에서 들을 수 있어요.'),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => _openAnswer(context, ref, myText),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text('답 고치기'),
          ),
        ],
      );
    }

    final parent = today.partnerAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnswerCard(
          label: '부모님의 답',
          text: parent is VoiceAnswer
              ? parent.displayText ??
                    parent.processingNotice ??
                    '부모님이 목소리로 답하셨어요.'
              : '부모님이 목소리로 답하셨어요.',
          highlighted: true,
        ),
        if (parent is VoiceAnswer && parent.originalAudioUrl != null) ...[
          const SizedBox(height: 12),
          AudioPlaybackCard(
            source: PlaybackSource(
              parent.originalAudioUrl!,
              expiresAt: parent.originalAudioExpiresAt,
            ),
            label: '부모님 목소리 듣기',
            onRefresh: () async {
              final fresh = await ref.refresh(todayProvider.future);
              final p = fresh.partnerAnswer;
              if (p is! VoiceAnswer || p.originalAudioUrl == null) {
                throw StateError('음성을 다시 불러오지 못했어요');
              }
              return PlaybackSource(
                p.originalAudioUrl!,
                expiresAt: p.originalAudioExpiresAt,
              );
            },
          ),
        ],
        if (myText != null) ...[
          const SizedBox(height: 16),
          _AnswerCard(label: '내 답', text: myText),
        ],
      ],
    );
  }
}

class _ParentSection extends ConsumerWidget {
  const _ParentSection({required this.today});
  final Today today;

  void _openRecording(BuildContext context, WidgetRef ref) {
    final my = today.myAnswer;
    _openAndRefresh(
      context,
      ref,
      '/recording',
      extra: RecordingArgs(
        assignmentId: today.assignmentId,
        questionText: today.question.text,
        questionAudioUrl: today.question.audioUrl,
        recordingId: my is VoiceAnswer ? my.recordingId : null, // 처리 상태 재조회
        canRecord: !today.isRevealed,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!today.iAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Message('목소리로 편하게 답해 주세요.\n30초면 충분해요.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openRecording(context, ref),
            icon: const Icon(Icons.mic, size: 28),
            label: const Text('목소리로 답하기'),
          ),
        ],
      );
    }

    if (!today.isRevealed) {
      final my = today.myAnswer;
      final processing =
          my is VoiceAnswer &&
          my.processingStatus != 'READY' &&
          my.processingStatus != 'FAILED';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Message('목소리를 보냈어요.\n자녀가 답하면 여기에서 볼 수 있어요.'),
          if (processing) ...[
            const SizedBox(height: 8),
            const _Message('말씀하신 내용을 글로 정리하고 있어요.'),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _openRecording(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.mic),
            label: const Text('다시 녹음하기'),
          ),
        ],
      );
    }

    final child = today.partnerAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnswerCard(
          label: '자녀의 답',
          text: child is TextAnswer ? child.text : '자녀가 답했어요.',
          highlighted: true,
        ),
        if (child is TextAnswer) ...[
          const SizedBox(height: 20),
          // 음성 상태 조회·재생·링크 갱신은 부모 답변 화면이 처리한다
          OutlinedButton.icon(
            onPressed: () => context.push('/parent-answer'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.volume_up),
            label: const Text('목소리로 듣기'),
          ),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyLarge);
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.text,
    this.highlighted = false,
  });

  final String label;
  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// 예: 9월 24일 수요일
String formatAssignedDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
}
