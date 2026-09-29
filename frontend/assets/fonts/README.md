# 글꼴

디자인(Figma `벌꿀오소리` 1차 와이어프레임)의 글자 스타일에 맞춰 넣은 글꼴이다.
토큰은 `lib/core/theme/app_tokens.dart`에서 쓴다.

| 글꼴 | 파일 | 쓰는 곳 | 출처 | 라이선스 |
|---|---|---|---|---|
| KoddiUD 온고딕 | `KoddiUDOnGothic-Regular.ttf`, `-Bold.ttf` | 화면 제목, 오늘의 질문 | [한국장애인개발원](https://www.koddi.or.kr/ud/sub1_2) 공식 배포 TTF | 무료 배포. 상업적 디자인·2차 저작물에 사용 가능, 서체 자체 판매·유통 금지, 서체 데이터 변형 제한 |
| Pretendard 1.3.9 | `Pretendard-Regular.otf`, `-Medium.otf`, `-Bold.otf` | 그 밖의 모든 글 | [orioncactus/pretendard](https://github.com/orioncactus/pretendard) (npm `pretendard@1.3.9`) | SIL OFL 1.1 (`OFL-Pretendard.txt`) |

- KoddiUD 온고딕은 한국장애인개발원과 윤디자인이 만든 유니버설 디자인 서체다.
  라이선스상 파일을 줄이거나(서브셋) 고치지 않고 그대로 넣었다.
- 디자인에서 한글 텍스트에 지정된 `Noto Sans Arabic`, `Inter`는 한글 글자가 없어
  Figma가 대체 글꼴로 그리고 있었다. 앱에서는 Pretendard로 통일했다.
