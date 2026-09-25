import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../domain/app_user.dart';
import 'sign_up_controller.dart';

/// 역할 선택 → 이름 입력 → 가입. 한 화면에 주요 행동 하나만 둔다.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const nameMaxLength = 50; // 서버 CreateUserRequest와 동일

  final _nameController = TextEditingController();
  UserRole? _role;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final role = _role;
    final name = _nameController.text.trim();
    if (role == null || name.isEmpty) return;
    ref.read(signUpControllerProvider.notifier).submit(name: name, role: role);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(signUpControllerProvider, (_, next) {
      final user = next.value;
      if (user != null && !next.isLoading) {
        context.go(user.isPaired ? '/today' : '/pairing');
      }
    });

    final role = _role;
    return Scaffold(
      appBar: role == null
          ? null
          : AppBar(
              leading: BackButton(
                onPressed: ref.watch(signUpControllerProvider).isLoading
                    ? null
                    : () => setState(() => _role = null),
              ),
            ),
      body: SafeArea(
        child: role == null
            ? _RoleStep(onSelected: (r) => setState(() => _role = r))
            : _NameStep(
                role: role,
                controller: _nameController,
                maxLength: nameMaxLength,
                onSubmit: _submit,
              ),
      ),
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({required this.onSelected});
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Text('누가 사용하시나요?', style: textTheme.headlineMedium),
        const SizedBox(height: 32),
        _RoleCard(
          icon: Icons.record_voice_over,
          title: '부모님',
          description: '질문에 목소리로 답해요',
          onTap: () => onSelected(UserRole.parent),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.edit_note,
          title: '자녀',
          description: '부모님을 초대하고 글로 답해요',
          onTap: () => onSelected(UserRole.child),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title, $description',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(icon, size: 48, color: scheme.primary),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(description, style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 32, color: scheme.onSurface),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NameStep extends ConsumerWidget {
  const _NameStep({
    required this.role,
    required this.controller,
    required this.maxLength,
    required this.onSubmit,
  });

  final UserRole role;
  final TextEditingController controller;
  final int maxLength;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final isParent = role == UserRole.parent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          isParent ? '성함을 알려주세요' : '이름을 알려주세요',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          isParent ? '자녀에게 이 이름으로 보여요.' : '부모님께 이 이름으로 보여요.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          enabled: !state.isLoading,
          autofocus: true,
          maxLength: maxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            hintText: isParent ? '예: 김영희' : '예: 김민지',
            border: const OutlineInputBorder(),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
        ),
        if (state.hasError) ...[
          const SizedBox(height: 16),
          _ErrorMessage(error: state.error!),
        ],
        const SizedBox(height: 32),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final canSubmit =
                controller.text.trim().isNotEmpty && !state.isLoading;
            return FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('시작하기'),
            );
          },
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});
  final Object error;

  String get _message {
    final e = error;
    if (e is ApiException) {
      if (e.statusCode == 400) return '이름을 다시 확인해 주세요.';
      return e.userMessage;
    }
    return '문제가 생겼어요. 다시 시도해 주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _message,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
