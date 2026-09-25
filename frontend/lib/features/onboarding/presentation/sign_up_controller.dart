import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../domain/app_user.dart';

/// 가입 요청 상태. 성공하면 가입한 사용자를 담는다.
class SignUpController extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() => const AsyncData(null);

  Future<void> submit({required String name, required UserRole role}) async {
    if (state.isLoading) return; // 연타 방지

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(name: name, role: role),
    );
    if (!ref.mounted) return;
    // 새로 저장된 사용자로 다시 읽게 한다 (페어링·첫 화면 분기에서 사용)
    if (result.hasValue) ref.invalidate(currentUserProvider);
    state = result;
  }
}

final signUpControllerProvider =
    NotifierProvider.autoDispose<SignUpController, AsyncValue<AppUser?>>(
      SignUpController.new,
    );
