# backend/AGENTS.md — Spring Boot 구현 규칙

작업 전에 루트 [`../AGENTS.md`](../AGENTS.md)와 API 계약
[`../docs/api-contract.md`](../docs/api-contract.md)을 읽는다. API 필드와 상태값은
이 문서가 아니라 API 계약이 기준이다.

## 1. 기술 기준

- Java 17, Spring Boot 3.5.x, Gradle Wrapper
- Spring Web, Validation, Data JPA, Security
- PostgreSQL 16
- JWT: JJWT, HS256, access token 30일(MVP)
- 외부 연동: OpenAI STT·LLM·TTS, Cloudflare R2
- 시간대: 일일 배정은 `Asia/Seoul`, DB timestamp는 offset/UTC 의미가 보존되게 저장

JWT 원문을 User 엔티티에 저장하지 않는다. `APP_JWT_SECRET`은 32바이트 이상의
환경변수로 주입하고 로그에 출력하지 않는다.

## 2. 패키지 구조

```text
com.apptive.backend
├── domain
│   ├── user
│   ├── pair
│   ├── question
│   ├── assignment
│   ├── recording
│   ├── answer
│   └── story
├── infra
│   ├── openai
│   └── storage
└── common
    ├── auth
    ├── config
    └── exception
```

도메인 내부는 필요에 따라 `controller`, `service`, `repository`, `dto`, `entity`로
나눈다. Entity를 API 응답으로 직접 반환하지 않는다.

## 3. 구현 규칙

- Controller: 인증 사용자·입력 검증·HTTP 변환만 담당
- Service: 페어 소유권, 수정 가능 여부, 공개 정책 등 업무 규칙 담당
- Repository: 영속성만 담당
- 모든 요청 DTO는 Bean Validation을 적용한다.
- 예외는 `@RestControllerAdvice`에서 API 계약의 공통 에러 형식으로 변환한다.
- `pairId`를 클라이언트가 보내게 하지 말고 인증 사용자로부터 조회한다.
- 녹음과 답변은 `assignmentId` 기준으로 중복을 통제한다.
- signed URL 자체를 DB에 저장하지 않고 R2 object key만 저장한다.
- 토큰, STT 원문, signed URL query를 애플리케이션 로그에 남기지 않는다.

## 4. 인증 구현

- `POST /api/v1/users`에서 사용자 생성 후 HS256 JWT를 발급한다.
- claim은 `sub`, `role`, `iat`, `exp`만 사용한다.
- `/api/v1/users`, `/api/v1/health`만 공개하고 나머지는 인증을 요구한다.
- 현재 사용자가 요청한 Pair·Assignment의 구성원인지 Service에서 다시 검사한다.
- 동일 `deviceId + role` 가입은 기존 사용자와 새 토큰을 반환한다.
- refresh token, 로그아웃 무효화, 기기 변경 복구는 P1이다.

## 5. 녹음 처리

API는 업로드 후 `202 Accepted`를 반환하고 프론트가 상태를 폴링하므로 MVP도
**비동기 상태 기반 처리**로 구현한다. 메시지 브로커는 쓰지 않고 `@Async`와
DB 상태 전이로 시작한다.

```text
UPLOADED
  → STT_PROCESSING → STT_DONE
  → LLM_PROCESSING → READY
  → 실패 시 FAILED
```

1. m4a/AAC, 1~60초, 최대 10 MiB인지 검증한다.
2. R2 비공개 bucket에 원본을 먼저 저장한다.
3. 저장 성공 시 부모 제출 상태는 `SUBMITTED`가 된다.
4. STT와 LLM을 순차 처리하되 실패해도 원본과 제출 상태를 보존한다.
5. 조회 시에만 짧은 만료 시간의 signed URL을 생성한다.
6. 같은 assignment의 재녹음은 새 파일 저장 성공 후 이전 파일을 교체한다.

LLM은 받아쓰기 내용을 자연스럽게 정리하되 원문에 없는 사실·날짜·지명·감정을
추가하지 않는다. `sttText`, `summaryText`, 원본 object key는 별도로 보존한다.

## 6. 자녀 답변 TTS

- 자녀 답변 저장 후 비동기로 생성하고 결과를 캐싱한다.
- `GET /answers/{id}/audio`는 조회만 하며 GET 요청에서 생성 작업을 시작하지 않는다.
- TTS 실패는 텍스트 답변 제출과 공개를 실패 처리하지 않는다.
- 질문 안내 TTS는 런타임 요청마다 만들지 않고 seed/질문 등록 시 사전 생성한다.

## 7. 환경변수

전체 예시는 [`.env.example`](.env.example)을 사용한다. Spring Boot는 `.env`
파일을 자동으로 읽지 않으므로 README의 방식대로 셸 환경 또는 IDE Run
Configuration으로 주입한다.

필수값:

- `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`
- `APP_JWT_SECRET`
- `OPENAI_API_KEY`
- `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`

## 8. 10/2 구현 순서

| 우선순위 | 범위 | 프론트 연동 기준 |
|---|---|---|
| P0-1 | 실행 환경, Security, 공통 예외, `GET /health` | 앱에서 서버 연결 확인 |
| P0-2 | User/JWT, Pair/초대 코드 | 가입·페어링 화면 연동 |
| P0-3 | Question/Assignment, `GET /today` | 홈 화면 연동 |
| P0-4 | 자녀 답변, 공개 상태 계산 | 자녀 답변·대기 화면 연동 |
| P0-5 | 녹음 업로드·폴링(Mock 처리 우선) | 부모 녹음 전체 흐름 연동 |
| P0-6 | R2, STT, LLM | 실제 음성 처리 연동 |
| P0-7 | TTS, 지난 이야기 | 재생·보관함 연동 |

외부 AI 연동 전에 Mock 상태 전이로 전체 API 흐름을 먼저 완성한다.

## 9. 테스트 최소 기준

- Service: 역할·소유권·중복 제출·공개 조건
- Controller: validation, 401/403/404/409, 공통 에러 JSON
- Recording: 허용 형식·크기·길이, 상태 전이, AI 실패 시 원본 보존
- Repository: assignment당 활성 답변/녹음 중복 방지

```bash
./gradlew test
```
