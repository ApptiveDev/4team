import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/features/stories/data/stories_data_source.dart';
import 'package:life_record/features/stories/data/stories_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // assets 읽기에 필요

  StoriesRepositoryImpl repoFor(String scenario) => StoriesRepositoryImpl(
    MockStoriesDataSource(scenario: scenario, delay: Duration.zero),
  );

  test('계약 예시(first_page)를 그대로 파싱한다', () async {
    final page = await repoFor('first_page').fetchPage();

    expect(page.items, hasLength(1));
    expect(page.hasNext, isFalse);
    expect(page.nextCursor, isNull);

    final story = page.items.single;
    expect(story.questionText, '어릴 때 가장 좋아했던 놀이는 무엇이었나요?');
    expect(story.assignedDate, DateTime(2026, 9, 24));
    expect(story.parentAnswer.displayText, '어린 시절 동네 친구들과 고무줄 놀이를 즐겼어요.');
    expect(story.childAnswer.text, '저는 놀이터에서 숨바꼭질하던 시간이 기억나요.');
  });

  test('paged: cursor가 없으면 1페이지, 받은 cursor로 2페이지를 준다', () async {
    final repo = repoFor('paged');

    final first = await repo.fetchPage();
    expect(first.items, hasLength(3));
    expect(first.hasNext, isTrue);
    expect(first.nextCursor, isNotNull);

    final second = await repo.fetchPage(cursor: first.nextCursor);
    expect(second.items, hasLength(2));
    expect(second.hasNext, isFalse);
  });

  test('AI 처리 실패 이야기는 안내 문구를 보여준다', () async {
    final repo = repoFor('paged');
    final first = await repo.fetchPage();
    final second = await repo.fetchPage(cursor: first.nextCursor);

    final failed = second.items.first.parentAnswer;
    expect(failed.processingStatus, 'FAILED');
    expect(failed.summaryText, isNull);
    expect(failed.sttText, isNull);
    expect(failed.displayText, '음성 정리는 실패했지만 원본 녹음은 안전하게 저장되었습니다.');
  });

  test('empty: 빈 목록', () async {
    final page = await repoFor('empty').fetchPage();
    expect(page.items, isEmpty);
    expect(page.hasNext, isFalse);
  });
}
