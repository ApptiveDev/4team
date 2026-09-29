import 'package:flutter/material.dart';

/// Figma `벌꿀오소리` 1차 와이어프레임(2026-09-28)의 디자인 토큰.
///
/// 프레임이 393×852라 Figma 1px = Flutter 1 논리 픽셀로 옮긴다.
/// 색은 Figma 색상 스타일 `Primary1/…` 이름을 그대로 따른다.
abstract final class AppColors {
  static const bg = Color(0xFFFAF7ED); // Primary1/BG: 화면 배경
  static const underBg = Color(0xFFF9F7F2); // Primary1/Under BG
  static const card = Color(0xFFFCEFD4); // Primary1/Card: 카드·입력칸
  static const base = Color(0xFFCD7938); // Primary1/Base: 주 버튼·테두리
  static const base2 = Color(0xFFEAA05A); // Primary1/Base2: 태그
  static const dark = Color(0xFF935B2D); // Primary1/Dark: 보조 글자·아이콘
  static const font = Color(0xFF543C2B); // Primary1/Pont: 제목 글자
  static const disabled = Color(0xFFB5AD9D); // Primary1/Border/Disabled
  static const shadowTone = Color(0xFFEDE4CB); // Primary1/Border/Shadow
  static const questionText = Color(0xFF1D1B1A); // 오늘의 질문 본문
}

abstract final class AppFonts {
  /// 화면 제목과 오늘의 질문 (유니버설 디자인 서체)
  static const koddi = 'KoddiUDOnGothic';

  /// 그 밖의 모든 글
  static const pretendard = 'Pretendard';
}

/// Figma 글자 스타일. 이름 뒤 숫자는 글자 크기(px)다.
abstract final class AppText {
  /// KoddiUD/Main TiTle 40: 화면 제목
  static const mainTitle = TextStyle(
    fontFamily: AppFonts.koddi,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.font,
  );

  /// KoddiUD/Main Title 40 (Regular): 오늘의 질문
  static const question = TextStyle(
    fontFamily: AppFonts.koddi,
    fontSize: 40,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.questionText,
  );

  /// noto/서브 타이틀 30: 버튼, 카드 제목, 입력칸
  static const subTitle = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.dark,
  );

  /// pretendard/Sub Title (Bold): 홈 인사
  static const greeting = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.dark,
  );

  /// noto/추가 정보 25/35: 제목 아래 설명
  static const extraInfo = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 25,
    fontWeight: FontWeight.w400,
    height: 35 / 25,
    letterSpacing: 0.25,
    color: AppColors.dark,
  );

  /// pretendard/Extra Information 25: 날짜, `#오늘의 질문`, 태그
  static const label = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 25,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.dark,
  );

  /// pretendard/Direction 20: 짧은 안내
  static const direction = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.dark,
  );

  /// Number 50: 초대 숫자
  static const number = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 50,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 1,
    color: AppColors.font,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

abstract final class AppRadius {
  static const button = 15.0; // 버튼, 입력칸, 역할 카드, 숫자 칸
  static const questionCard = 20.0; // 오늘의 질문 카드(바깥 창)
  static const tag = 20.0;
  static const bar = 5.0; // 진행 표시 막대
}

abstract final class AppSizes {
  static const buttonHeight = 80.0;
  static const buttonWidth = 331.0; // 393 프레임에서 좌우 31
  static const iconButton = 30.0; // 이전 화살표, 마이크
  static const stepBarWidth = 43.0;
  static const stepBarHeight = 6.0;
}

/// Figma 바깥쪽 그림자. 모두 불투명도 25%.
abstract final class AppShadows {
  /// 채운 버튼 (0, 4) 흐림 7
  static const filledButton = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 7, color: Color(0x405C574A)),
  ];

  /// 테두리 버튼·입력칸 (0, 4) 흐림 4~7
  static const outlinedButton = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 4, color: Color(0x40958E7B)),
  ];
  static const field = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 7, color: Color(0x40958E7B)),
  ];

  /// 역할 카드 (0, 2) 흐림 13
  static const roleCard = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 13, color: Color(0x40625C53)),
  ];

  /// 초대 숫자 칸 (2, 2) 흐림 7
  static const numberBox = [
    BoxShadow(offset: Offset(2, 2), blurRadius: 7, color: Color(0x40000000)),
  ];

  /// 오늘의 질문 카드 (0, 4) 흐림 6
  static const questionCard = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 6, color: Color(0x405C574A)),
  ];

  /// 답 카드 (1, 2) 흐림 7
  static const answerCard = [
    BoxShadow(offset: Offset(1, 2), blurRadius: 7, color: Color(0x40635E52)),
  ];
}
