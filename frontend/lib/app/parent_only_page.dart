import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/widgets/error_retry_view.dart';
import '../features/onboarding/data/auth_providers.dart';
import '../features/onboarding/domain/app_user.dart';

final _parentUserProvider = FutureProvider.autoDispose<AppUser?>(
  (ref) => ref.read(userStorageProvider).read(),
);

/// 로컬 역할은 진입 안내용이며 최종 접근 권한은 서버가 검사한다.
class ParentOnlyPage extends ConsumerWidget {
  const ParentOnlyPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.useMock) return child;
    return ref
        .watch(_parentUserProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: ErrorRetryView(
              message: '사용자 정보를 확인하지 못했어요.',
              onRetry: () => ref.invalidate(_parentUserProvider),
            ),
          ),
          data: (user) {
            if (user?.role == UserRole.parent) return child;
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user == null ? '먼저 시작해 주세요.' : '부모님이 사용하는 화면이에요.'),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => context.go(
                            user == null ? '/onboarding' : '/today',
                          ),
                          child: const Text('돌아가기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
  }
}
