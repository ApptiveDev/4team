# API 계약 v0 — 2026-10-02 MVP

이 문서는 Flutter와 Spring Boot 사이의 **단일 API 계약(source of truth)**이다.
프론트는 이 문서의 예시 JSON으로 Mock을 만들고, 백엔드는 동일한 필드와 상태값을
구현한다. 계약을 바꿀 때는 코드와 이 문서를 같은 PR에서 수정한다.

- Base URL: `/api/v1`
- 인증: `Authorization: Bearer {accessToken}`
- Content-Type: 기본 `application/json`, 녹음 업로드만 `multipart/form-data`
- MVP 마감: 2026-10-02

## 1. 아직 회의가 필요한 정책

`자녀 쪽은 절대 차단하지 않는다`는 원칙과 상호 공개 조건은 **2026-09-25까지
결정할 TBD**다. 클라이언트가 정책을 직접 계산하지 않도록 모든 조회 응답에
서버가 계산한 `revealStatus`와 `canViewPartnerAnswer`를 내려준다.

프론트는 우선 다음 상태를 모두 표시할 수 있게 구현한다.

- `WAITING_FOR_PARENT`: 부모 답변 대기
- `WAITING_FOR_CHILD`: 자녀 답변 대기
- `REVEALED`: 상대 답변 공개

회의에서 정할 항목:

1. 양쪽 모두 답해야 공개할지
2. 일정 기간 후 한쪽 답변만 공개할지
3. `건너뛰기(SKIPPED)`를 MVP에 넣을지
4. 공개 후 재녹음·답변 수정을 허용할지

정책이 확정되기 전까지 Mock의 기본값은 `MUTUAL_SUBMISSION`으로 두되, 화면은
반드시 서버의 `revealStatus`만 신뢰한다.

## 2. 공통 규칙

### 2.1 ID와 시간

- 모든 ID는 JSON `string`이다. `usr_`, `pair_`, `asg_` 등의 접두사는 예시일
  뿐이므로 클라이언트가 ID 내부 구조를 해석하지 않는다.
- 날짜는 `YYYY-MM-DD`, 시각은 UTC offset이 포함된 ISO-8601 문자열이다.
- 일일 질문 배정·날짜 경계의 기준 시간대는 `Asia/Seoul`이다.

```json
{
  "id": "asg_01J8M6WQ0G5D6S8KZC8V2J2X5P",
  "assignedDate": "2026-09-24",
  "createdAt": "2026-09-24T09:30:00+09:00"
}
```

### 2.2 필드와 HTTP 상태

- 필드 이름은 `camelCase`를 사용한다.
- 값이 아직 없지만 의미 있는 필드는 `null`로 내려준다.
- 권한 때문에 공개할 수 없는 상대방 데이터는 필드 자체를 생략한다.
- 생성 `201`, 비동기 처리 시작 `202`, 정상 조회·수정 `200`, body 없는 성공
  `204`를 사용한다.
- 프론트는 화면 분기를 HTTP 문구가 아니라 `errorCode`와 상태 enum으로 처리한다.

### 2.3 공통 에러 응답

```json
{
  "timestamp": "2026-09-24T10:15:30+09:00",
  "status": 400,
  "errorCode": "INVALID_AUDIO_FORMAT",
  "message": "m4a(AAC) 형식의 녹음 파일만 업로드할 수 있습니다.",
  "path": "/api/v1/assignments/asg_123/parent-recording",
  "traceId": "01J8M7N6XH7VMM5T0J7D4A6W9K",
  "fieldErrors": [
    { "field": "audioFile", "reason": "unsupported_content_type" }
  ]
}
```

`fieldErrors`가 없으면 빈 배열 `[]`을 내려준다.

| HTTP | 대표 `errorCode` | 의미 |
|---|---|---|
| 400 | `VALIDATION_ERROR`, `INVALID_AUDIO_FORMAT` | 요청값 오류 |
| 401 | `UNAUTHORIZED`, `TOKEN_EXPIRED` | 토큰 없음·만료 |
| 403 | `ROLE_NOT_ALLOWED`, `PAIR_ACCESS_DENIED` | 역할·소유권 오류 |
| 404 | `USER_NOT_FOUND`, `ASSIGNMENT_NOT_FOUND` | 리소스 없음 |
| 409 | `ALREADY_PAIRED`, `INVITE_CODE_USED`, `ANSWER_LOCKED` | 현재 상태와 충돌 |
| 413 | `AUDIO_FILE_TOO_LARGE` | 파일 크기 초과 |
| 422 | `AUDIO_DURATION_OUT_OF_RANGE` | 녹음 길이 오류 |
| 429 | `RATE_LIMITED` | 요청 빈도 제한 |
| 500 | `INTERNAL_ERROR` | 서버 내부 오류 |
| 502 | `AI_PROVIDER_ERROR`, `STORAGE_ERROR` | 외부 연동 오류 |

### 2.4 인증과 권한

- `POST /users`만 인증 없이 호출한다.
- 서버가 HS256 JWT access token을 발급한다. payload에는 `sub`(userId),
  `role`, `iat`, `exp`만 넣는다.
- MVP 만료 기간은 30일이다. refresh token과 전화번호 OTP는 출시 이후 범위다.
- 토큰 원문은 DB에 저장하지 않는다.
- `pairId`는 가능한 한 토큰의 현재 사용자로부터 서버가 찾는다. 요청자가 해당
  Pair/Assignment의 구성원인지 모든 API에서 검사한다.

### 2.5 수정·재시도·중복 요청

- 자녀 답변은 공개 전까지 같은 `PUT` 요청으로 수정할 수 있다.
- 부모 녹음은 공개 전까지 같은 `PUT` 요청으로 재녹음할 수 있다. 새 녹음이
  정상 업로드된 뒤 이전 파일을 대체한다.
- 공개 이후 수정 요청은 `409 ANSWER_LOCKED`를 반환한다. 이 정책은 회의 결과에
  따라 변경될 수 있다.
- `PUT` 엔드포인트는 동일 요청을 다시 보내도 최종 상태가 하나만 남도록 한다.
- 녹음 업로드에는 `Idempotency-Key` 헤더를 권장한다. 같은 키의 재요청은 새
  Recording을 만들지 않고 최초 응답을 반환한다.

### 2.6 녹음 파일

- 파일 확장자·코덱: `.m4a`, AAC-LC
- 허용 MIME: `audio/mp4`, `audio/m4a`, `audio/aac`
- 권장 길이: 30~60초, MVP 허용 길이: 1~60초
- 최대 크기: 10 MiB
- 업로드 필드명: `audioFile`
- 원본은 비공개 R2 bucket에 저장한다. DB에는 공개 URL이 아닌 object key를
  저장하고, 조회 시 만료 시간이 짧은 signed URL을 반환한다.

### 2.7 녹음 처리와 폴링

`processingStatus` 값:

```text
UPLOADED -> STT_PROCESSING -> STT_DONE -> LLM_PROCESSING -> READY
                                                        \-> FAILED
              각 단계의 복구 불가능한 오류 -----------> FAILED
```

- 프론트는 최초 30초 동안 3초, 이후 5초 간격으로 조회한다.
- `READY` 또는 `FAILED`이면 폴링을 종료한다.
- 총 60초가 지나면 폴링을 멈추고 "처리 중" 화면을 보여준다. 사용자가 다시
  진입하면 상태를 재조회한다.
- 앱이 백그라운드로 가면 폴링을 중지하고 복귀할 때 재조회한다.

AI 처리는 제출 여부와 분리한다. R2 업로드가 성공하면 부모는 `SUBMITTED`이며,
STT/LLM이 실패해도 원본 음성은 보존한다. 공개 정책상 상대에게 공개 가능한
상태라면 원본 음성을 재생할 수 있고, `sttText`/`summaryText`는 `null`,
`processingNotice`에는 실패 안내를 내려준다. **AI 실패 때문에 가족 답변 전체를
영구 차단하지 않는다.**

### 2.8 페이지네이션

- `cursor`는 서버가 만든 불투명한 Base64URL 문자열이다.
- 클라이언트는 cursor를 해석하거나 직접 생성하지 않는다.
- 기본 `limit=20`, 최대 `50`이다.

```json
{
  "items": [],
  "nextCursor": "MjAyNi0wOS0wMVQwMDowMDowMFo6c3RvcnlfMTIz",
  "hasNext": true
}
```

## 3. 상태 enum

| 이름 | 값 |
|---|---|
| `Role` | `PARENT`, `CHILD` |
| `SubmissionStatus` | `NOT_SUBMITTED`, `SUBMITTED`, `SKIPPED` |
| `ProcessingStatus` | `UPLOADED`, `STT_PROCESSING`, `STT_DONE`, `LLM_PROCESSING`, `READY`, `FAILED` |
| `TtsStatus` | `NOT_REQUESTED`, `PROCESSING`, `READY`, `FAILED` |
| `RevealStatus` | `WAITING_FOR_PARENT`, `WAITING_FOR_CHILD`, `WAITING_FOR_BOTH`, `REVEALED` |

`SKIPPED`는 공개 정책 회의에 대비해 enum에 예약하지만, 확정 전에는 클라이언트가
건너뛰기 버튼을 노출하지 않는다.

## 4. MVP API 목록

| # | 메서드·경로 | 역할 | 용도 |
|---|---|---|---|
| 0 | `GET /health` | 공개 | 서버 상태 확인 |
| 1 | `POST /users` | 공개 | 간편 가입 및 access token 발급 |
| 2 | `POST /pairs/invitations` | 자녀 | 초대 코드 발급 |
| 3 | `POST /pairs/join` | 부모 | 초대 코드로 1:1 연결 |
| 4 | `GET /today` | 공통 | 오늘 질문·제출·공개 상태 통합 조회 |
| 5 | `PUT /assignments/{assignmentId}/parent-recording` | 부모 | 녹음 신규 제출·교체 |
| 6 | `GET /recordings/{recordingId}` | 부모 | STT/LLM 처리 상태 폴링 |
| 7 | `PUT /assignments/{assignmentId}/child-answer` | 자녀 | 텍스트 답변 신규 제출·수정 |
| 8 | `GET /answers/{answerId}/audio` | 부모 | 자녀 답변 TTS 상태·재생 URL 조회 |
| 9 | `GET /stories?cursor=&limit=` | 공통 | 공개된 지난 이야기 목록 |

`GET /questions/today`와 `GET /today?pairId=`는 제거한다. 오늘 화면은 `GET
/today` 하나로 통합하고 Pair는 인증 사용자로부터 서버가 결정한다.

## 5. API 상세와 Mock JSON

### 5.0 서버 상태 — `GET /health`

인증 없이 호출한다.

응답 `200 OK`:

```json
{
  "status": "UP",
  "timestamp": "2026-09-24T09:00:00+09:00"
}
```

### 5.1 가입 — `POST /users`

요청:

```json
{
  "name": "김영희",
  "role": "PARENT",
  "deviceId": "9a243caf-26e2-4d72-bf4c-6d643ee49cf9"
}
```

응답 `201 Created`:

```json
{
  "user": {
    "id": "usr_01J8M8A9G39WJMB5KVX46DP3FQ",
    "name": "김영희",
    "role": "PARENT",
    "pairingStatus": "UNPAIRED"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiJ9.example.signature",
  "tokenType": "Bearer",
  "expiresAt": "2026-10-24T09:00:00+09:00"
}
```

같은 `deviceId + role`의 재호출은 새 사용자를 중복 생성하지 않고 기존 사용자와
새 access token을 `200 OK`로 반환한다. MVP의 기기 변경·계정 복구는 지원하지
않으며 출시 전에 전화번호 인증 등으로 교체한다.

### 5.2 초대 코드 발급 — `POST /pairs/invitations`

자녀 토큰이 필요하다. body는 없다.

응답 `201 Created`:

```json
{
  "invitationId": "inv_01J8M8HE0DE9EAP9FDMRFFGBS7",
  "inviteCode": "482913",
  "expiresAt": "2026-09-25T09:10:00+09:00"
}
```

- 숫자 6자리, 유효기간 24시간, 1회용이다.
- 미사용 코드가 있으면 새 코드를 계속 만들지 않고 기존 코드를 반환해도 된다.

### 5.3 초대 코드 참여 — `POST /pairs/join`

부모 토큰이 필요하다.

요청:

```json
{
  "inviteCode": "482913"
}
```

응답 `201 Created`:

```json
{
  "pair": {
    "id": "pair_01J8M8P8WTTDQMK99PQK7TGJE8",
    "parent": {
      "id": "usr_parent_123",
      "name": "김영희"
    },
    "child": {
      "id": "usr_child_456",
      "name": "김민지"
    },
    "pairedAt": "2026-09-24T09:15:00+09:00"
  }
}
```

### 5.4 오늘 상태 — `GET /today`

부모·자녀 공통 API다. `pairId` query parameter를 받지 않는다.

응답 `200 OK` — 아직 부모만 답한 예시:

```json
{
  "assignment": {
    "id": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
    "assignedDate": "2026-09-24",
    "question": {
      "id": "qst_045",
      "text": "어릴 때 가장 좋아했던 놀이는 무엇이었나요?",
      "category": "CHILDHOOD",
      "audioUrl": "https://cdn.example.com/questions/qst_045.mp3"
    }
  },
  "viewerRole": "PARENT",
  "parentSubmissionStatus": "SUBMITTED",
  "childSubmissionStatus": "NOT_SUBMITTED",
  "revealStatus": "WAITING_FOR_CHILD",
  "canViewPartnerAnswer": false,
  "myAnswer": {
    "type": "VOICE",
    "recordingId": "rec_01J8M96KKXMV5XMXY6KGJ05Q6D",
    "processingStatus": "LLM_PROCESSING",
    "originalAudioUrl": "https://signed.example.com/rec_123.m4a?expires=...",
    "originalAudioExpiresAt": "2026-09-24T10:20:00+09:00",
    "sttText": "어릴 때는 동네에서 고무줄 놀이를...",
    "summaryText": null,
    "processingNotice": null
  }
}
```

상대 답변을 볼 수 없을 때는 `partnerAnswer` 필드를 **생략**한다. 공개 후에는
다음처럼 포함한다.

```json
{
  "assignment": {
    "id": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
    "assignedDate": "2026-09-24",
    "question": {
      "id": "qst_045",
      "text": "어릴 때 가장 좋아했던 놀이는 무엇이었나요?",
      "category": "CHILDHOOD",
      "audioUrl": "https://cdn.example.com/questions/qst_045.mp3"
    }
  },
  "viewerRole": "CHILD",
  "parentSubmissionStatus": "SUBMITTED",
  "childSubmissionStatus": "SUBMITTED",
  "revealStatus": "REVEALED",
  "canViewPartnerAnswer": true,
  "myAnswer": {
    "type": "TEXT",
    "answerId": "ans_01J8M9DDP02MTHJY44YKN3ZE73",
    "text": "저는 놀이터에서 숨바꼭질하던 시간이 기억나요.",
    "ttsStatus": "READY"
  },
  "partnerAnswer": {
    "type": "VOICE",
    "recordingId": "rec_01J8M96KKXMV5XMXY6KGJ05Q6D",
    "processingStatus": "READY",
    "originalAudioUrl": "https://signed.example.com/rec_123.m4a?expires=...",
    "originalAudioExpiresAt": "2026-09-24T10:20:00+09:00",
    "sttText": "어릴 때는 동네에서 고무줄 놀이를 했지.",
    "summaryText": "어린 시절 동네 친구들과 고무줄 놀이를 즐겼어요.",
    "processingNotice": null
  }
}
```

페어링 전에는 `409 PAIR_NOT_FOUND`, 오늘 질문이 아직 배정되지 않았다면
`404 TODAY_ASSIGNMENT_NOT_FOUND`를 반환한다.

### 5.5 부모 녹음 제출·교체

`PUT /assignments/{assignmentId}/parent-recording`

헤더:

```text
Content-Type: multipart/form-data
Idempotency-Key: 5e8ea171-903f-49e9-b5c0-b39f96eb31e8
```

form-data:

```text
audioFile: answer.m4a
```

응답 `202 Accepted`:

```json
{
  "recordingId": "rec_01J8M96KKXMV5XMXY6KGJ05Q6D",
  "assignmentId": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
  "submissionStatus": "SUBMITTED",
  "processingStatus": "UPLOADED",
  "submittedAt": "2026-09-24T09:35:00+09:00",
  "pollingUrl": "/api/v1/recordings/rec_01J8M96KKXMV5XMXY6KGJ05Q6D"
}
```

공개 전 재녹음은 새 파일로 교체하고 같은 assignment에는 활성 Recording 하나만
유지한다. 기존 파일 삭제는 새 파일 저장 성공 뒤 수행한다.

### 5.6 녹음 처리 상태 — `GET /recordings/{recordingId}`

처리 중 응답 `200 OK`:

```json
{
  "recordingId": "rec_01J8M96KKXMV5XMXY6KGJ05Q6D",
  "assignmentId": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
  "processingStatus": "LLM_PROCESSING",
  "sttText": "어릴 때는 동네에서 고무줄 놀이를...",
  "summaryText": null,
  "failedStage": null,
  "failureCode": null,
  "processingNotice": null,
  "updatedAt": "2026-09-24T09:35:15+09:00"
}
```

실패 응답도 조회 자체는 `200 OK`이며 상태로 표현한다.

```json
{
  "recordingId": "rec_01J8M96KKXMV5XMXY6KGJ05Q6D",
  "assignmentId": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
  "processingStatus": "FAILED",
  "sttText": null,
  "summaryText": null,
  "failedStage": "STT",
  "failureCode": "AI_PROVIDER_TIMEOUT",
  "processingNotice": "음성 정리는 실패했지만 원본 녹음은 안전하게 저장되었습니다.",
  "updatedAt": "2026-09-24T09:36:00+09:00"
}
```

사용자 재시도는 MVP에서 동일 assignment에 녹음을 다시 `PUT`하는 방식으로
처리한다. 별도 AI-only retry API는 출시 이후 범위다.

### 5.7 자녀 답변 제출·수정

`PUT /assignments/{assignmentId}/child-answer`

요청:

```json
{
  "text": "저는 놀이터에서 숨바꼭질하던 시간이 기억나요."
}
```

- 앞뒤 공백 제거 후 1~1000자
- 공개 전 동일 API 호출은 기존 답변을 수정한다.
- TTS는 저장 후 비동기로 생성하고 실패해도 텍스트 답변 제출은 유지한다.

응답 `200 OK`(신규 생성 시에도 PUT이므로 동일):

```json
{
  "answerId": "ans_01J8M9DDP02MTHJY44YKN3ZE73",
  "assignmentId": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
  "text": "저는 놀이터에서 숨바꼭질하던 시간이 기억나요.",
  "submissionStatus": "SUBMITTED",
  "ttsStatus": "PROCESSING",
  "submittedAt": "2026-09-24T09:40:00+09:00",
  "updatedAt": "2026-09-24T09:40:00+09:00"
}
```

### 5.8 자녀 답변 TTS — `GET /answers/{answerId}/audio`

GET 요청에서는 TTS를 새로 생성하지 않는다. 자녀 답변 제출 시 생성 작업을
시작하고 이 API는 상태와 결과만 조회한다.

응답 `200 OK`:

```json
{
  "answerId": "ans_01J8M9DDP02MTHJY44YKN3ZE73",
  "ttsStatus": "READY",
  "audioUrl": "https://signed.example.com/tts/ans_123.mp3?expires=...",
  "audioExpiresAt": "2026-09-24T10:45:00+09:00",
  "processingNotice": null
}
```

생성 중에는 `audioUrl`, `audioExpiresAt`이 `null`이다. 실패해도 텍스트는 계속
노출하고 `ttsStatus=FAILED`와 안내 문구를 반환한다.

### 5.9 지난 이야기 — `GET /stories?cursor=&limit=20`

공개된 assignment만 반환한다. 최신순이다.

응답 `200 OK`:

```json
{
  "items": [
    {
      "storyId": "story_01J8MA2SAGKK4FR2PWT67W4TN4",
      "assignmentId": "asg_01J8M90G3M9BT7PRD6X4CN9C0E",
      "assignedDate": "2026-09-24",
      "question": {
        "id": "qst_045",
        "text": "어릴 때 가장 좋아했던 놀이는 무엇이었나요?",
        "category": "CHILDHOOD"
      },
      "parentAnswer": {
        "recordingId": "rec_01J8M96KKXMV5XMXY6KGJ05Q6D",
        "processingStatus": "READY",
        "originalAudioUrl": "https://signed.example.com/rec_123.m4a?expires=...",
        "originalAudioExpiresAt": "2026-09-24T10:50:00+09:00",
        "sttText": "어릴 때는 동네에서 고무줄 놀이를 했지.",
        "summaryText": "어린 시절 동네 친구들과 고무줄 놀이를 즐겼어요.",
        "processingNotice": null
      },
      "childAnswer": {
        "answerId": "ans_01J8M9DDP02MTHJY44YKN3ZE73",
        "text": "저는 놀이터에서 숨바꼭질하던 시간이 기억나요.",
        "ttsStatus": "READY"
      },
      "revealedAt": "2026-09-24T09:41:00+09:00"
    }
  ],
  "nextCursor": null,
  "hasNext": false
}
```

## 6. 프론트 Mock 파일 권장 구조

```text
frontend/
└── assets/
    └── mocks/
        ├── user_parent.json
        ├── user_child.json
        ├── today_waiting_for_parent.json
        ├── today_waiting_for_child.json
        ├── today_revealed.json
        ├── recording_processing.json
        ├── recording_failed.json
        └── stories_first_page.json
```

프론트는 화면에서 HTTP client를 직접 호출하지 않고 Repository/DataSource 계층을
통해 Mock과 실제 API를 교체한다. Android 에뮬레이터의 로컬 API 주소는
`http://10.0.2.2:8080/api/v1`, 실기기는 같은 네트워크에 있는 개발 PC의 LAN IP를
사용한다.

## 7. 10/2 범위 밖(P1)

- 전화번호 OTP, refresh token, 계정 복구
- FCM·웹소켓 처리 완료 알림
- AI-only 재처리 API와 운영자 콘솔
- Presigned URL을 이용한 앱→R2 직접 업로드
- 여러 부모·자녀를 묶는 가족 그룹
- 댓글·좋아요·공개 소셜 피드
- 질문 관리자 화면과 실시간 질문 TTS 생성

## 8. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|---|---|---|
| 2026-09-24 | v0 | MVP API 분리, 공통 규칙·전체 요청/응답·Mock 계약 확정 |
