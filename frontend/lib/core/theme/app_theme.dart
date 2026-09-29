import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// 앱 전체 테마. 값은 `app_tokens.dart`의 디자인 토큰에서 가져온다.
///
/// 화면에서 `Theme.of(context).textTheme.headlineMedium` 등을 쓰면 디자인
/// 글자 스타일이 그대로 적용된다.
/// - headlineMedium = 화면 제목 (KoddiUD 40)
/// - titleLarge = 카드 제목·강조 (30)
/// - bodyLarge = 제목 아래 설명 (25/35)
/// - bodyMedium = 짧은 안내 (20)
class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.base,
      onPrimary: AppColors.bg,
      primaryContainer: AppColors.card,
      onPrimaryContainer: AppColors.font,
      secondary: AppColors.base2,
      onSecondary: AppColors.bg,
      secondaryContainer: AppColors.card,
      onSecondaryContainer: AppColors.font,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: AppColors.bg,
      onSurface: AppColors.font,
      onSurfaceVariant: AppColors.dark,
      surfaceContainerHighest: AppColors.card,
      outline: AppColors.base,
      outlineVariant: AppColors.disabled,
      shadow: Color(0xFF5C574A),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    const buttonSize = Size.fromHeight(AppSizes.buttonHeight);
    final buttonText = AppText.subTitle.copyWith(color: null);

    return ThemeData(
      colorScheme: scheme,
      fontFamily: AppFonts.pretendard,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: const TextTheme(
        headlineMedium: AppText.mainTitle,
        headlineSmall: AppText.greeting,
        titleLarge: AppText.subTitle,
        bodyLarge: AppText.extraInfo,
        bodyMedium: AppText.direction,
        labelLarge: AppText.subTitle,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.dark,
        size: AppSizes.iconButton,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.dark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.label,
        iconTheme: IconThemeData(
          color: AppColors.dark,
          size: AppSizes.iconButton,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          backgroundColor: AppColors.base,
          foregroundColor: AppColors.bg,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.bg,
          textStyle: buttonText,
          iconSize: AppSizes.iconButton,
          shape: buttonShape,
          elevation: 3,
          shadowColor: const Color(0xFF5C574A),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.dark,
          textStyle: buttonText,
          iconSize: AppSizes.iconButton,
          shape: buttonShape,
          side: const BorderSide(color: AppColors.base, width: 2),
          elevation: 2,
          shadowColor: const Color(0xFF958E7B),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dark,
          textStyle: AppText.label,
          iconSize: 26,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: AppText.subTitle.copyWith(color: AppColors.disabled),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.base, width: 2),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.base,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: const Color(0xFF635E52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.base,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.font,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 20,
          height: 1.4,
          color: AppColors.bg,
        ),
      ),
    );
  }
}
