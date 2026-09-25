import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/audio_playback_card.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../data/parent_answer_providers.dart';
import '../domain/parent_answer.dart';
import 'parent_answer_controller.dart';

/// context.push('/parent-answer')로 인자 없이 진입한다.
/// today를 재조회해 서버가 공개를 허용한 자녀 답변만 표시한다.
class ParentAnswerPage extends ConsumerStatefulWidget {
  const ParentAnswerPage({super.key, this.controller});
  final ParentAnswerController? controller;

  @override
  ConsumerState<ParentAnswerPage> createState() => _ParentAnswerPageState();
}

class _ParentAnswerPageState extends ConsumerState<ParentAnswerPage>
    with WidgetsBindingObserver {
  late final ParentAnswerController _controller;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        ParentAnswerController(ref.read(parentAnswerRepositoryProvider));
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_checkAccess);
    unawaited(_controller.load());
  }

  void _checkAccess() {
    if (_redirecting || !mounted) return;
    final status = _controller.errorStatus;
    if (status != 401 && status != 403) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 401 ? '다시 시작해 주세요.' : '이 화면은 볼 수 없어요.'),
        ),
      );
      context.go(status == 401 ? '/onboarding' : '/today');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _controller.setForeground(state == AppLifecycleState.resumed);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_checkAccess);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('자녀의 이야기'),
        leading: IconButton(
          onPressed: () => context.go('/today'),
          tooltip: '오늘 화면으로',
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _controller.loading ? null : _controller.load,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(child: _body(context)),
    ),
  );

  Widget _body(BuildContext context) {
    final c = _controller;
    if (c.loading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: '답변 불러오는 중'),
      );
    }
    if (c.message != null) {
      return ErrorRetryView(message: c.message!, onRetry: c.load);
    }
    final answer = c.answer;
    if (answer == null) return const Center(child: Text('답변을 확인하고 있어요.'));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          answer.questionText,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        if (!answer.canView) ...[
          const Icon(Icons.favorite_border, size: 64),
          const SizedBox(height: 16),
          Text(switch (answer.revealStatus) {
            'WAITING_FOR_PARENT' => '오늘 이야기를 들려주시면 답변을 확인할 수 있어요.',
            'WAITING_FOR_CHILD' => '자녀의 이야기가 도착하면 여기서 볼 수 있어요.',
            _ => '아직 공개된 답변이 없어요. 편할 때 다시 들러 주세요.',
          }),
          const SizedBox(height: 24),
          FilledButton(onPressed: c.load, child: const Text('다시 확인')),
        ] else if (answer.text == null || answer.answerId == null) ...[
          const Text('아직 표시할 답변이 없어요.'),
          TextButton(onPressed: c.load, child: const Text('다시 확인')),
        ] else ...[
          Text(answer.text!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (c.audio?.status == AnswerTtsStatus.ready && c.audio?.url != null)
            AudioPlaybackCard(
              source: PlaybackSource(
                c.audio!.url!,
                expiresAt: c.audio!.expiresAt,
              ),
              label: '자녀의 답변 듣기',
              onRefresh: c.refreshAudioSource,
            ),
          if (c.audioLoading)
            const LinearProgressIndicator(semanticsLabel: '음성 확인 중'),
          if (c.audioMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(c.audioMessage!),
            ),
          if (c.audio?.status != AnswerTtsStatus.ready || c.audio?.url == null)
            TextButton(
              onPressed: c.audioLoading ? null : c.retryAudio,
              child: const Text('음성 상태 다시 확인'),
            ),
        ],
      ],
    );
  }
}
