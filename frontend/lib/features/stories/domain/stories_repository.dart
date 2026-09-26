import 'story.dart';

abstract class StoriesRepository {
  /// [cursor]가 null이면 첫 페이지, 있으면 그다음 페이지를 불러온다.
  Future<StoryPage> fetchPage({String? cursor});
}
