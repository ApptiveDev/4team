# Backend — 삶을 기록해주는 AI

Spring Boot 백엔드입니다. API 스펙·데이터 모델·코딩 컨벤션·일정은
[`AGENTS.md`](./AGENTS.md)를 참고하세요. 이 문서는 **실행 방법**만 다룹니다.

## 요구 사항

- JDK 21+
- Gradle (프로젝트 내 `./gradlew` 사용, 별도 설치 불필요)
- Docker / Docker Compose (로컬 PostgreSQL용)

## 로컬 실행

```bash
# 1. PostgreSQL 컨테이너 기동
docker compose up -d

# 2. 환경 변수 설정
cp .env.example .env
# .env를 열어 아래 값들을 채운다 (팀 비공개 채널에서 공유받기)

# 3. 서버 실행
./gradlew bootRun
```

서버는 기본적으로 `http://localhost:8080`에서 뜹니다.

## 환경 변수

| 변수 | 설명 |
|---|---|
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | 로컬은 `docker-compose.yml` 기본값 그대로 사용 |
| `OPENAI_API_KEY` | STT(`gpt-transcribe`), LLM 정리(`gpt-5-mini`), TTS(`gpt-4o-mini-tts`) 전부 이 키로 호출 |
| `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME` | Cloudflare R2 (원본 음성 아카이빙) |
| `APP_JWT_SECRET` | 인증 토큰 서명용 |

전체 목록/형식은 `.env.example` 참고. **API 키는 절대 커밋하지 말 것.**

## 프로젝트 구조

패키지 구조·계층 규칙은 [`AGENTS.md`](./AGENTS.md#패키지-구조-제안)에 정리되어
있습니다. 여기서 중복 설명하지 않습니다.

## API 문서

- 현재는 [`AGENTS.md`](./AGENTS.md#상세-api-스펙)가 스펙 문서 역할을 합니다.
- Swagger/OpenAPI를 붙이면 로컬 실행 시 `http://localhost:8080/swagger-ui.html`
  (붙이는 시점에 이 줄 갱신할 것)

## 테스트

```bash
./gradlew test
```

(아직 테스트 코드 없음 — 작성되는 대로 이 섹션 업데이트)

## 자주 겪는 문제

| 증상 | 원인/해결 |
|---|---|
| `bootRun` 시 DB 연결 실패 | `docker compose up -d`로 PostgreSQL 컨테이너가 떠 있는지 확인 |
| `.env` 값이 안 읽힘 | `.env` 파일이 `backend/` 루트에 있는지, 키 이름 오타 없는지 확인 |
| `docker compose up` 시 포트 충돌 | 로컬에 이미 5432 포트를 쓰는 PostgreSQL이 떠 있는지 확인 (`docker ps`) |
| OpenAI 호출 401 | `OPENAI_API_KEY` 값 확인, 크레딧 잔액 확인 |