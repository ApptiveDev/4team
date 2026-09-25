import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/stories/data/stories_providers.dart';
import 'package:life_record/features/stories/domain/story.dart';
import 'package:life_record/features/stories/presentation/stories_controller.dart';

import 'fake_stories_repository.dart';

void main() {
  late FakeStoriesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeStoriesRepository({
      null: StoryPage(
        items: [testStory('1'), testStory('2')],
        nextCursor: 'c2',
        hasNext: true,
      ),
      'c2': StoryPage(
        items: [testStory('3')],
        nextCursor: null,
        hasNext: false,
      ),
    });
    container = ProviderContainer(
      overrides: [storiesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // autoDispose provider가 테스트 도중 사라지지 않게 구독해 둔다.
    container.listen(storiesControllerProvider, (_, _) {});
  });

  StoriesController controller() =>
      container.read(storiesControllerProvider.notifier);

  Future<StoriesState> firstPage() =>
      container.read(storiesControllerProvider.future);

  test('처음 열면 첫 페이지를 불러온다', () async {
    final state = await firstPage();

    expect(state.items.map((s) => s.storyId), ['story_1', 'story_2']);
    expect(state.hasNext, isTrue);
    expect(repo.requestedCursors, [null]);
  });

  test('loadMore는 다음 페이지를 뒤에 이어 붙인다', () async {
    await firstPage();
    await controller().loadMore();

    final state = container.read(storiesControllerProvider).value!;
    expect(state.items.map((s) => s.storyId), [
      'story_1',
      'story_2',
      'story_3',
    ]);
    expect(state.hasNext, isFalse);
    expect(repo.requestedCursors, [null, 'c2']);
  });

  test('마지막 페이지면 더 요청하지 않는다', () async {
    await firstPage();
    await controller().loadMore();
    await controller().loadMore();

    expect(repo.requestedCursors, [null, 'c2']);
  });

  test('불러오는 중에 다시 호출해도 한 번만 요청한다', () async {
    await firstPage();
    repo.gate = Completer<void>();

    final a = controller().loadMore();
    final b = controller().loadMore(); // 첫 요청이 끝나기 전 두 번째 호출
    expect(
      container.read(storiesControllerProvider).value!.isLoadingMore,
      isTrue,
    );

    repo.gate!.complete();
    await Future.wait([a, b]);

    expect(repo.requestedCursors, [null, 'c2']);
  });

  test('다음 페이지 실패 시 기존 목록은 그대로 두고 실패 표시', () async {
    await firstPage();
    repo.error = ApiException();

    await controller().loadMore();

    final state = container.read(storiesControllerProvider).value!;
    expect(state.items, hasLength(2));
    expect(state.loadMoreFailed, isTrue);
    expect(state.isLoadingMore, isFalse);
  });

  test('첫 페이지 실패는 에러 상태가 된다', () async {
    repo.error = ApiException();
    // setUp에서 이미 첫 요청이 나갔으므로, 에러를 설정한 뒤 다시 불러오게 한다
    container.invalidate(storiesControllerProvider);

    await expectLater(firstPage(), throwsA(anything));

    final state = container.read(storiesControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<ApiException>());
  });
}
