# AGENTS.md (루트) — 공통 계약 문서

이 문서는 프론트(Flutter)와 백엔드(Spring Boot)가 함께 합의한 **API 계약의
단일 진실 공급원(source of truth)**입니다. 사람이든 AI 코딩 에이전트든, 이
프로젝트에서 작업하기 전에 반드시 이 문서를 먼저 읽으세요.

- 프론트 전용 상세: `frontend/AGENTS.md`
- 백엔드 전용 상세: `backend/AGENTS.md`

## 1. 제품 컨셉 요약 (가족 썸원 구조)

- 자녀가 앱을 설치하고 초대 코드를 발급 → 부모가 코드를 입력해 1:1 페어링
- 매일 정해진 시간에 질문 1개가 양쪽에 노출됨
- **부모**: 음성으로 답변 (30~60초, 최소 길이 제한 없음) → 녹음 종료 시 자동 업로드
- **자녀**: 텍스트로 답변
- **둘 다 답하면** 서로의 답이 공개됨 (상호 공개 게이트, 자녀 쪽은 절대 차단하지 않음)
- 부모 답변 공개 화면: **원본 육성 재생이 기본**, 정리 텍스트는 자막/보조
- 자녀 답변은 부모에게 **TTS로 낭독**되어 전달 (접근성 목적)
- 질문 음성 안내는 **빌드 시점에 미리 생성해 캐싱**(런타임 TTS 호출 없음)

## 2. 공통 파이프라인 (부모 vs 자녀)

```
[부모]
녹음(30~60초) → 자동 업로드 → STT(gpt-transcribe) → LLM 정리(gpt-5-mini)
  → 원본 음성은 R2에 아카이빙, STT/정리 텍스트는 DB 저장 → (자녀 공개 시) 원본 음성 + 자막 노출

[자녀]
텍스트 입력 → 제출 → DB 저장 → (부모 공개 시) 텍스트 그대로 노출 + TTS 낭독(gpt-4o-mini-tts, 부모용)
```

두 흐름은 같은 "질문-답변(Assignment)" 단위로 묶이고, **둘 다 완료되어야
서로에게 공개**됩니다. 이 공개 판단 로직이 공통 파이프라인의 핵심입니다.

## 3. 데이터 모델 (초안)

| 엔티티 | 주요 필드 | 설명 |
|---|---|---|
| `User` | id, name, role(PARENT/CHILD), deviceId, accessToken | MVP는 간편 인증(이름+역할+기기토큰)으로 시작, 이후 강화 |
| `Pair` | id, parentId, childId, inviteCode, pairedAt | 부모-자녀 1:1 연결 |
| `Question` | id, text, category, audioUrl(사전 생성 TTS) | 질문 세트, 시드 데이터로 관리 |
| `DailyAssignment` | id, pairId, questionId, assignedDate | 페어별 오늘의 질문 배정 |
| `Recording` | id, assignmentId, audioUrlOriginal(R2), sttText, summaryText, status | 부모 답변. status: `UPLOADED → STT_DONE → LLM_DONE → READY` (실패 시 `FAILED`) |
| `Answer` | id, assignmentId, text, status | 자녀 답변. status: `SUBMITTED` |

공개 여부(`revealed`)는 별도 컬럼보다 **`Recording.status == READY && Answer.status == SUBMITTED`
인지를 조회 시점에 계산**하는 방식을 권장합니다(MVP 단순화).

## 4. 공통 API 계약 (v0)

Base URL: `/api/v1` · 모든 응답은 JSON · 인증은 `Authorization: Bearer {accessToken}`

> **MVP 인증 방식에 대한 가정**: 일정상 이메일/전화 인증까지 갈 시간이 없다고
> 판단해, "이름 + 역할 선택 + 기기 식별자"만으로 계정을 만드는 최소 인증으로
> 시작하는 것을 기본값으로 제안합니다. 강화된 인증(전화번호 OTP 등)은 P1로
> 미루는 데 팀이 동의하는지 오늘 중 확인해주세요. 이견 있으면 이 섹션부터
> 고쳐야 합니다.

| # | 메서드/경로 | 요청자 | 설명 |
|---|---|---|---|
| 1 | `POST /users` | 공통 | 회원가입(이름, 역할 선택) |
| 2 | `POST /pairs/invite` | 자녀 | 초대 코드 발급 |
| 3 | `POST /pairs/join` | 부모 | 초대 코드로 페어링 |
| 4 | `GET /questions/today?pairId=` | 공통 | 오늘의 질문 + 사전 생성된 음성 URL |
| 5 | `POST /recordings` | 부모 | 녹음 파일 업로드 (multipart/form-data) |
| 6 | `GET /recordings/{id}` | 부모 | 처리 상태 폴링 |
| 7 | `POST /answers` | 자녀 | 텍스트 답변 제출 |
| 8 | `GET /today?pairId=` | 공통 | 오늘 상태 통합 조회 (공개 여부 포함) |
| 9 | `GET /answers/{id}/audio` | 부모 | 자녀 답변의 TTS 낭독 음성 URL (없으면 생성 후 캐싱) |
| 10 | `GET /stories?pairId=&cursor=` | 공통 | 과거 스토리 보관함 (페이지네이션) |

### 4-1. 부모 녹음 업로드 — `POST /recordings`

요청 (multipart/form-data):
```
pairId: string
questionId: string
audioFile: (m4a/wav 파일)
```

응답 (202 Accepted):
```json
{
  "recordingId": "rec_123",
  "status": "UPLOADED"
}
```

### 4-2. 처리 상태 폴링 — `GET /recordings/{id}`

```json
{
  "recordingId": "rec_123",
  "status": "LLM_DONE",
  "sttText": "그때 그 겨울에...",
  "summaryText": "정리된 문장...",
  "failedReason": null
}
```
`status` 값: `UPLOADED` → `STT_DONE` → `LLM_DONE` → `READY` (또는 각 단계에서 `FAILED`)

프론트는 이 엔드포인트를 **3~5초 간격으로 폴링**하는 것을 기본으로 하고,
추후 여유가 되면 서버 푸시(웹소켓/FCM)로 대체하는 걸 P1로 남겨둡니다.

### 4-3. 오늘 상태 통합 조회 — `GET /today?pairId=`

```json
{
  "question": { "id": "q_45", "text": "어릴 때 살던 동네는 어땠나요?", "audioUrl": "https://.../q_45.mp3" },
  "parentStatus": "READY",
  "childStatus": "SUBMITTED",
  "revealed": true,
  "story": {
    "originalAudioUrl": "https://r2.../rec_123.m4a",
    "sttText": "...",
    "summaryText": "..."
  },
  "answer": { "text": "저도 어릴 때 놀이터에서..." }
}
```
`revealed`가 `false`면 `story`/`answer`는 자신의 것만 내려주고 상대방 것은
생략합니다(아직 공개 전).

## 5. 이슈 처리 프로세스 (연동 문제 대응)

개발 중 프론트-백엔드 스펙이 안 맞거나 애매한 부분을 발견하면:

1. **GitHub Issue**를 등록합니다. 제목에 `[API]` 접두어, 본문에 (a) 어떤
   엔드포인트인지 (b) 기대한 동작 (c) 실제 동작/불명확한 점을 적습니다.
2. 이슈를 처리하는 사람(팀원 또는 AI 코딩 에이전트)은 **이 `AGENTS.md`의
   관련 섹션을 먼저 찾아 확인**합니다 (섹션 4의 표에서 해당 엔드포인트 검색).
3. 스펙을 변경해야 한다면, **코드와 이 문서를 같은 PR에서 함께 수정**합니다.
   문서만 고치고 코드를 안 고치거나, 코드만 고치고 문서를 안 고치는 것을
   금지합니다 — 이 파일이 신뢰를 잃으면 계약 문서로서 의미가 없어집니다.
4. 변경 사항은 아래 "변경 이력"에 한 줄로 남깁니다.

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|---|---|---|
| 2026-09-23 | 최초 작성 (가족 썸원 피벗 반영, 공통 API 계약 v0) | - |
| 2026-09-23 | LLM 정리 모델을 Claude Haiku 4.5 → OpenAI `gpt-5-mini`로 변경 (STT/LLM/TTS 전부 OpenAI 단일 벤더로 통일) | - |