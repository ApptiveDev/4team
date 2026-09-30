import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/retry_policy.dart';
import '../../parent_answer/data/parent_answer_providers.dart';
import '../../parent_answer/domain/parent_answer.dart';

/// 지난 이야기 카드 하나의 자녀 답 TTS (answerId별로 따로 캐시)
final storyChildAudioProvider = FutureProvider.autoDispose
    .family<AnswerAudio, String>(
      (ref, answerId) =>
          ref.read(parentAnswerRepositoryProvider).getAudio(answerId),
      retry: retryTransientOnly,
    );
