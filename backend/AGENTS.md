# backend/AGENTS.md — Spring Boot

> 이 문서를 읽기 전에 루트 `../AGENTS.md`(공통 API 계약)를 먼저 읽으세요.
> 여기는 백엔드 구현 방식, 상세 스펙, 외부 연동을 다룹니다.

## 기술 스택

- Spring Boot (Java 또는 Kotlin — 팀 선호에 맞춰 오늘 확정), Gradle
- REST API, **Controller – Service – Repository** 계층 구조, DTO/Entity 분리
- 예외는 `@RestControllerAdvice` 공통 핸들러로 처리
- DB: 개발은 Docker Compose PostgreSQL, 출시는 AWS RDS PostgreSQL (엔진 동일하게 유지)
- 외부 연동: OpenAI(`gpt-transcribe`, `gpt-4o-mini-tts`), Anthropic(Claude Haiku 4.5),
  Cloudflare R2 (S3 호환 SDK)

## 패키지 구조 (제안)

```
com.example.app
├── domain
│   ├── user/          (User 엔티티, 인증)
│   ├── pair/           (Pair, 초대 코드)
│   ├── question/       (Question, DailyAssignment)
│   ├── recording/      (Recording, STT/LLM 처리)
│   └── answer/         (Answer)
├── infra
│   ├── stt/             (OpenAI gpt-transcribe 클라이언트)
│   ├── llm/             (Claude Haiku 클라이언트)
│   ├── tts/             (OpenAI TTS 클라이언트)
│   └── storage/         (R2 업로드/다운로드 클라이언트)
├── common
│   ├── exception/       (공통 예외 핸들러)
│   └── config/          (환경설정, Bean 등록)
└── Application.java
```

각 도메인 패키지 내부는 `Controller / Service / Repository / dto` 하위 구조를
따릅니다.

## 환경 변수 (.env.example)

```
DB_URL=jdbc:postgresql://localhost:5432/app
DB_USERNAME=postgres
DB_PASSWORD=postgres

OPENAI_API_KEY=
ANTHROPIC_API_KEY=

R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=

APP_JWT_SECRET=
```

실제 키 값은 절대 커밋하지 말고 팀 비공개 채널(또는 GitHub Secrets)로
공유하세요.

## 상세 API 스펙

루트 `AGENTS.md` 4장의 요약 표를 기준으로, 여기서는 구현에 필요한 세부
사항만 추가합니다.

### 공통 규칙

- 성공 응답: `2xx` + JSON body
- 실패 응답: 아래 공통 에러 포맷
  ```json
  { "errorCode": "RECORDING_NOT_FOUND", "message": "녹음을 찾을 수 없습니다." }
  ```
- 인증 실패: `401`, 페어링 안 된 사용자의 페어 전용 API 접근: `403`

### `POST /recordings` 처리 흐름 (핵심 파이프라인)

1. multipart로 오디오 파일 수신 → `Recording` 엔티티 생성, status=`UPLOADED`
2. 오디오 파일을 R2에 업로드 (원본 그대로, 가공 없음) → `audioUrlOriginal` 저장
3. `gpt-transcribe` 호출 → 성공 시 `sttText` 저장, status=`STT_DONE` / 실패 시 status=`FAILED`, `failedReason` 저장 후 **재시도 가능하게 API 별도 제공**(`POST /recordings/{id}/retry`, P1로 미뤄도 무방)
4. Claude Haiku 4.5 호출(STT 텍스트 정리) → 성공 시 `summaryText` 저장, status=`LLM_DONE`
5. status=`READY`로 전환

> MVP 기간(~10/2)에는 **동기 처리(요청-응답 안에서 순차 호출)로 단순하게
> 구현**하는 것을 권장합니다. 비동기 큐(메시지 브로커 등)는 시간이 많이
> 들고, 지금 규모(팀 내부 테스트)에서는 응답 지연이 크게 체감되지 않습니다.
> `@Async` + 폴링 정도로도 충분합니다. 진짜 비동기 큐 도입은 사용자가 늘어난
> 이후(P1)로 미루세요.

### LLM 정리 프롬프트 가드레일 (중요)

기획서 v2 보완안 11장 리스크 — **LLM이 없는 사실을 지어내면 안 됩니다.**
프롬프트에 반드시 다음을 포함하세요:

```
아래는 어르신이 음성으로 답한 내용을 받아쓴 텍스트입니다.
문장을 자연스럽게 다듬고 군더더기(어, 음 등)만 정리하세요.
원문에 없는 사실, 날짜, 지명, 감정 묘사를 새로 추가하지 마세요.
```

정리본(`summaryText`)은 항상 원본(`sttText`, `audioUrlOriginal`)과 함께
저장되어야 하며, 프론트는 원본을 기본으로 노출합니다(정리본은 보조).

### `GET /today` 공개 판단 로직

```java
boolean revealed = recording.getStatus() == READY && answer.getStatus() == SUBMITTED;
```
둘 중 하나라도 아직이면 `revealed=false`로 응답하고, 요청한 사용자 자신의
제출물만 내려줍니다(상대방 것은 아직 노출하지 않음).

### 질문 음성 사전 생성 (FR-22)

질문 세트는 유한하므로, **런타임에 TTS를 호출하지 않습니다.** 별도
배치 스크립트(또는 `@Component` + `CommandLineRunner`)로 신규 질문이 추가될
때마다 TTS를 미리 생성해 R2에 저장하고, `Question.audioUrl`에 그 URL을
채워둡니다. 이렇게 하면 7장 비용 시뮬레이션의 TTS 비용 항목이 거의 사라집니다.

## 일자별 계획 (백엔드 전용, 9/23 ~ 10/2)

| 날짜 | 작업 |
|---|---|
| 9/23 (오늘) | 저장소/Gradle 프로젝트 스캐폴드, Docker Compose(PostgreSQL) 세팅, ERD 초안 확정, API 계약 리뷰 |
| 9/24 | `User`/`Pair` 엔티티, 간편 인증(이름+역할+기기토큰), `POST /users` |
| 9/25 | `POST /pairs/invite`, `POST /pairs/join`, `Question`/`DailyAssignment` 시드 + `GET /questions/today` |
| 9/26 | `POST /recordings` (R2 업로드까지), `Recording` 상태 필드, `GET /recordings/{id}` |
| 9/27 | `gpt-transcribe` 연동(STT_DONE), Claude Haiku 연동(LLM_DONE, 가드레일 프롬프트 적용) |
| 9/28 | `POST /answers`, `GET /today` 공개 판단 로직 |
| 9/29 | `GET /answers/{id}/audio` (자녀 답변 TTS 낭독, 캐싱), 질문 음성 사전 생성 배치 스크립트 |
| 9/30 | `GET /stories` 보관함(페이지네이션), 프론트와 전체 루프 통합 테스트 |
| 10/1 | 에러 케이스(STT 실패, 재시도), 로깅/모니터링 최소 세팅 |
| 10/2 | 최종 점검, 배포 환경(스테이징) 확인 |

## 이슈 대응

프론트에서 API 스펙 관련 GitHub Issue가 올라오면, 루트 `AGENTS.md`의 "이슈
처리 프로세스"를 따르세요. 이 문서(백엔드 상세 스펙)를 고쳐야 하는 변경이면
루트 `AGENTS.md`도 함께 갱신합니다(둘이 어긋나면 안 됩니다).