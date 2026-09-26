import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_record/core/network/api_exception.dart';
import 'package:life_record/features/stories/data/stories_providers.dart';
import 'package:life_record/features/stories/domain/story.dart';
import 'package:life_record/features/stories/presentation/stories_page.dart';
import 'package:life_record/features/stories/presentation/widgets/story_card.dart';

import 'fake_stories_repository.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, FakeStoriesRepository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storiesRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: StoriesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('이야기 카드와 더 보기 버튼이 보이고, 누르면 다음 이야기가 붙는다', (tester) async {
    final repo = FakeStoriesRepository({
      null: StoryPage(items: [testStory('1')], nextCursor: 'c2', hasNext: true),
      'c2': StoryPage(
        items: [testStory('2')],
        nextCursor: null,
        hasNext: false,
      ),
    });
    await pumpPage(tester, repo);

    expect(find.text('질문 1'), findsOneWidget);
    expect(find.text('자녀 답 1'), findsOneWidget);

    await tester.tap(find.text('이전 이야기 더 보기'));
    await tester.pumpAndSettle();

    expect(find.text('질문 2'), findsOneWidget);
    expect(find.text('이전 이야기 더 보기'), findsNothing); // 마지막 페이지
  });

  testWidgets('이야기가 없으면 빈 화면 안내', (tester) async {
    final repo = FakeStoriesRepository({
      null: const StoryPage(items: [], nextCursor: null, hasNext: false),
    });
    await pumpPage(tester, repo);

    expect(find.text('아직 모인 이야기가 없어요.'), findsOneWidget);
  });

  testWidgets('첫 로딩 실패 → 안내와 다시 시도 → 성공', (tester) async {
    final repo = FakeStoriesRepository({
      null: StoryPage(
        items: [testStory('1')],
        nextCursor: null,
        hasNext: false,
      ),
    })..error = ApiException();
    await pumpPage(tester, repo);

    expect(find.text('인터넷 연결을 확인해 주세요.'), findsOneWidget);

    repo.error = null; // 연결이 돌아왔다고 가정
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('질문 1'), findsOneWidget);
  });

  testWidgets('AI 정리 실패 이야기는 안내 문구를 보여준다', (tester) async {
    const notice = '음성 정리는 실패했지만 원본 녹음은 안전하게 저장되었습니다.';
    final repo = FakeStoriesRepository({
      null: StoryPage(
        items: [
          testStory(
            '1',
            summaryText: null,
            processingStatus: 'FAILED',
            processingNotice: notice,
          ),
        ],
        nextCursor: null,
        hasNext: false,
      ),
    });
    await pumpPage(tester, repo);

    expect(find.text(notice), findsOneWidget);
  });

  test('날짜는 "9월 24일 목요일" 형식', () {
    expect(StoryCard.formatDate(DateTime(2026, 9, 24)), '9월 24일 목요일');
  });
}
