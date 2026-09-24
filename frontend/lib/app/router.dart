import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding',
          builder: (context, state) => const PlaceholderPage(title: '역할 선택·가입')),   // A
      GoRoute(path: '/pairing',
          builder: (context, state) => const PlaceholderPage(title: '페어링')),         // A
      GoRoute(path: '/today',
          builder: (context, state) => const PlaceholderPage(title: '오늘 질문')),      // A
      GoRoute(path: '/recording',
          builder: (context, state) => const PlaceholderPage(title: '부모 녹음')),      // B
      GoRoute(path: '/child-answer',
          builder: (context, state) => const PlaceholderPage(title: '자녀 답변')),      // C
      GoRoute(path: '/stories',
          builder: (context, state) => const PlaceholderPage(title: '지난 이야기')),    // A
    ],
  );
});