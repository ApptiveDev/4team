import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_providers.dart';

/// 앱을 켰을 때 가입 화면 대신 갈 곳. 로그인 정보가 없으면 null(가입 화면 유지).
///
/// 라우터에 redirect를 두지 않고 가입 화면에서 판단한다. 첫 화면이 `/onboarding`이라
/// 결과가 같고, 여러 사람이 함께 고치는 router.dart를 건드리지 않아도 된다.
final launchDestinationProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final token = await ref.read(tokenStorageProvider).read();
  final user = await ref.read(currentUserProvider.future);
  if (token == null || user == null) return null;
  return user.isPaired ? '/today' : '/pairing';
});

/// 401(토큰 없음·만료)이면 로그인 정보를 지우고 가입 화면으로 보낸다.
/// 처리했으면 true.
///
/// 토큰과 사용자 정보를 함께 지워야 한다. 사용자 정보만 남으면 가입 화면이 다시
/// 홈으로 보내서 401이 반복된다.
Future<bool> handleSessionExpired(
  BuildContext context,
  WidgetRef ref,
  Object error,
) async {
  if (error is! ApiException || error.statusCode != 401) return false;

  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.of(context);
  await ref.read(tokenStorageProvider).clear();
  await ref.read(userStorageProvider).clear();
  ref.invalidate(currentUserProvider);
  // 앱 시작 때 계산한 "갈 곳"이 남아 있으면 가입 화면이 그 값을 다시 쓴다
  ref.invalidate(launchDestinationProvider);

  // 같은 기기·같은 역할로 다시 가입하면 서버가 기존 계정을 돌려준다
  messenger?.showSnackBar(
    const SnackBar(content: Text('다시 시작해 주세요.\n같은 역할을 고르면 이야기가 그대로 이어져요.')),
  );
  router.go('/onboarding');
  return true;
}
