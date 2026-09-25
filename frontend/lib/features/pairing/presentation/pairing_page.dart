import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_retry_view.dart';
import '../../onboarding/data/auth_providers.dart';
import '../../onboarding/domain/app_user.dart';
import '../data/pairing_providers.dart';
import '../domain/pairing_repository.dart';
import 'pairing_controller.dart';

/// 자녀는 초대 코드를 보여주며 연결을 기다리고, 부모는 코드를 입력한다.
class PairingPage extends ConsumerWidget {
  const PairingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: user.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => ErrorRetryView(
            message: '정보를 불러오지 못했어요.',
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
          data: (user) {
            if (user == null) {
              // 가입 정보가 없으면 가입부터
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.go('/onboarding'),
              );
              return const SizedBox.shrink();
            }
            return user.role == UserRole.child
                ? const _ChildInviteView()
                : const _ParentJoinView();
          },
        ),
      ),
    );
  }
}

class _ChildInviteView extends ConsumerStatefulWidget {
  const _ChildInviteView();

  @override
  ConsumerState<_ChildInviteView> createState() => _ChildInviteViewState();
}

class _ChildInviteViewState extends ConsumerState<_ChildInviteView> {
  static const pollInterval = Duration(seconds: 3);
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(pollInterval, (_) => _checkPaired());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _checkPaired() async {
    if (_checking) return;
    _checking = true;
    try {
      final paired = await ref.read(pairingRepositoryProvider).isPaired();
      if (paired && mounted) {
        _poll?.cancel();
        context.go('/today');
      }
    } catch (_) {
      // 잠깐의 네트워크 오류는 다음 확인 때 다시 시도한다.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(invitationProvider, (_, next) {
      if (next.hasError && isAlreadyPaired(next.error!)) context.go('/today');
    });

    final invitation = ref.watch(invitationProvider);
    return invitation.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetryView(
        message: '초대 숫자를 만들지 못했어요.',
        onRetry: () => ref.invalidate(invitationProvider),
      ),
      data: (invitation) => _InviteContent(invitation: invitation),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent({required this.invitation});
  final Invitation invitation;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invitation.inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('숫자를 복사했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = invitation.inviteCode;
    final spaced = code.length == 6
        ? '${code.substring(0, 3)} ${code.substring(3)}'
        : code;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Text('부모님을 초대해 주세요', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          '부모님 휴대폰에서 이 앱을 열고 "부모님"을 고른 뒤, 아래 숫자를 입력하시면 연결돼요.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        Semantics(
          label: '초대 숫자 ${code.split('').join(' ')}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              spaced,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: theme.colorScheme.onPrimaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${formatExpiry(invitation.expiresAt)}까지 쓸 수 있어요.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
          label: const Text('숫자 복사하기'),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                '부모님이 연결하면 자동으로 넘어가요.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 예: 9월 26일 오후 9:10
String formatExpiry(DateTime time) {
  final local = time.toLocal();
  final period = local.hour < 12 ? '오전' : '오후';
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}월 ${local.day}일 $period $hour12:$minute';
}

class _ParentJoinView extends ConsumerStatefulWidget {
  const _ParentJoinView();

  @override
  ConsumerState<_ParentJoinView> createState() => _ParentJoinViewState();
}

class _ParentJoinViewState extends ConsumerState<_ParentJoinView> {
  static const codeLength = 6;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(_onChanged);
  }

  @override
  void dispose() {
    _code.removeListener(_onChanged);
    _code.dispose();
    super.dispose();
  }

  void _onChanged() {
    ref.read(joinControllerProvider.notifier).clearError();
    setState(() {}); // 버튼 활성 상태 갱신
  }

  void _submit() {
    if (_code.text.length != codeLength) return;
    FocusScope.of(context).unfocus();
    ref.read(joinControllerProvider.notifier).join(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(joinControllerProvider, (_, next) {
      if (next.value == true ||
          (next.hasError && isAlreadyPaired(next.error!))) {
        context.go('/today');
      }
    });

    final state = ref.watch(joinControllerProvider);
    final theme = Theme.of(context);
    final canSubmit = _code.text.length == codeLength && !state.isLoading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Text('자녀와 연결해요', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text('자녀에게 받은 숫자 6자리를 입력해 주세요.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 32),
        TextField(
          controller: _code,
          enabled: !state.isLoading,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: codeLength,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
          ),
          decoration: const InputDecoration(
            hintText: '000000',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        if (state.hasError && !isAlreadyPaired(state.error!)) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pairingErrorMessage(state.error!),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: state.isLoading
              ? const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Text('연결하기'),
        ),
      ],
    );
  }
}
