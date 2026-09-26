import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/stories_providers.dart';
import '../domain/story.dart';

/// 지금까지 불러온 이야기 목록과 다음 페이지 상태
class StoriesState {
  const StoriesState({
    required this.items,
    required this.nextCursor,
    required this.hasNext,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  factory StoriesState.fromPage(StoryPage page) => StoriesState(
    items: page.items,
    nextCursor: page.nextCursor,
    hasNext: page.hasNext,
  );

  final List<Story> items;
  final String? nextCursor;
  final bool hasNext;

  /// 다음 페이지를 불러오는 중
  final bool isLoadingMore;

  /// 다음 페이지 불러오기 실패 (목록은 그대로 두고 아래에 다시 시도 버튼)
  final bool loadMoreFailed;
}

class StoriesController extends AsyncNotifier<StoriesState> {
  @override
  Future<StoriesState> build() async {
    final page = await ref.read(storiesRepositoryProvider).fetchPage();
    return StoriesState.fromPage(page);
  }

  /// 서명 URL이 만료됐을 때 새 URL을 받기 위해 해당 이야기를 다시 찾는다.
  /// 목록 state는 바꾸지 않는다(재생 중인 카드가 다시 그려지지 않게).
  Future<StoryParentAnswer> fetchLatestParentAnswer(String storyId) async {
    final repo = ref.read(storiesRepositoryProvider);
    String? cursor;
    while (true) {
      final page = await repo.fetchPage(cursor: cursor);
      for (final story in page.items) {
        if (story.storyId == storyId) return story.parentAnswer;
      }
      if (!page.hasNext) break;
      cursor = page.nextCursor;
    }
    throw StateError('이야기를 다시 찾지 못했어요');
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.isLoadingMore) return;

    state = AsyncData(
      StoriesState(
        items: current.items,
        nextCursor: current.nextCursor,
        hasNext: current.hasNext,
        isLoadingMore: true,
      ),
    );

    try {
      final page = await ref
          .read(storiesRepositoryProvider)
          .fetchPage(cursor: current.nextCursor);
      if (!ref.mounted) return; // 기다리는 사이 화면이 닫혔으면 무시
      state = AsyncData(
        StoriesState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          hasNext: page.hasNext,
        ),
      );
    } on ApiException {
      if (!ref.mounted) return;
      state = AsyncData(
        StoriesState(
          items: current.items,
          nextCursor: current.nextCursor,
          hasNext: current.hasNext,
          loadMoreFailed: true,
        ),
      );
    }
  }
}

final storiesControllerProvider =
    AsyncNotifierProvider.autoDispose<StoriesController, StoriesState>(
      StoriesController.new,
      // Riverpod 3는 실패한 provider를 자동으로 여러 번 재시도한다.
      // TODO(C): today-home PR 병합 후 retryTransientOnly로 교체
      retry: (retryCount, error) => null,
    );
