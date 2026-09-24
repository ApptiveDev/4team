import 'package:flutter/material.dart';

import '../../domain/answer_validator.dart';

/// 1000자를 넘겨도 잘라내지 않고 안내만 한다.
/// (붙여넣은 긴 글이 몰래 잘리지 않게)
class AnswerInput extends StatelessWidget {
  const AnswerInput({
    super.key,
    required this.controller,
    this.serverErrorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? serverErrorText;
  final bool enabled;

  static const tooLongMessage = '${AnswerValidator.maxLength}자까지 적을 수 있어요.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final length = AnswerValidator.length(controller.text);
    final tooLong =
        AnswerValidator.validate(controller.text) == AnswerValidation.tooLong;

    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 6,
      maxLines: 12,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '생각나는 대로 편하게 적어 주세요.',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        errorText: tooLong ? tooLongMessage : serverErrorText,
        counterText: '$length/${AnswerValidator.maxLength}',
        counterStyle: tooLong
            ? theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              )
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}
