# Backend — 가족 질문·음성 기록 서비스

Spring Boot 백엔드다. 구현 규칙은 [`AGENTS.md`](AGENTS.md), 요청·응답 계약은
[`../docs/api-contract.md`](../docs/api-contract.md)를 참고한다.

## 요구 사항

- JDK 17
- Docker / Docker Compose
- Gradle은 저장소의 Wrapper 사용

버전 확인:

```bash
java -version
./gradlew --version
docker compose version
```

## 로컬 실행

```bash
cp .env.example .env
docker compose up -d
set -a
source .env
set +a
./gradlew bootRun
```

Spring Boot는 `.env`를 자동으로 읽지 않는다. IntelliJ로 실행한다면 `.env`의
값을 Run Configuration의 Environment variables에 넣는다.

서버 기본 주소는 `http://localhost:8080`, Android 에뮬레이터에서 접근할 때는
`http://10.0.2.2:8080`이다.

## 환경변수

| 변수 | 설명 |
|---|---|
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | PostgreSQL 연결 정보 |
| `APP_JWT_SECRET` | HS256 서명 키, 32바이트 이상 |
| `APP_ACCESS_TOKEN_EXPIRATION_DAYS` | MVP 기본 30일 |
| `OPENAI_API_KEY` | STT·LLM·TTS 호출 키 |
| `R2_ACCOUNT_ID` | Cloudflare 계정 ID |
| `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | R2 S3 호환 자격증명 |
| `R2_BUCKET_NAME` | 비공개 원본 음성 bucket |
| `JPA_SHOW_SQL` | 로컬 SQL 출력 여부, 기본 `false` |
| `JPA_DDL_AUTO` | 로컬 기본 `update`; 운영 배포 전 migration 도구로 교체 |

실제 `.env`, API key, 비밀번호는 커밋하지 않는다. 전체 형식은
[`.env.example`](.env.example)을 복사해 사용한다.

## 테스트

```bash
./gradlew test
```

## API 개발 순서

1. `GET /api/v1/health`
2. 가입·JWT, 페어링
3. 오늘 질문·Assignment
4. 자녀 답변·공개 상태
5. 녹음 업로드·폴링(Mock 처리)
6. R2·STT·LLM 실제 연동
7. TTS·지난 이야기

프론트는 [`../docs/api-contract.md`](../docs/api-contract.md)의 JSON으로 먼저
개발한다. 백엔드가 완성될 때까지 기다릴 필요가 없다.

## 자주 겪는 문제

| 증상 | 확인할 것 |
|---|---|
| DB 연결 실패 | `docker compose ps`, `.env`의 DB 값, 5432 포트 충돌 |
| `password authentication failed for user "postgres"` | 5432를 다른 PostgreSQL이 쓰는지 `docker ps`로 확인하고, 해당 DB의 비밀번호와 `DB_PASSWORD`를 맞춘다. 기존 볼륨은 컨테이너 환경변수만 바꿔도 비밀번호가 바뀌지 않는다. |
| 환경변수가 비어 있음 | `.env`를 셸에 export했는지 또는 IDE에 등록했는지 확인 |
| Android에서 접속 실패 | 에뮬레이터는 `localhost` 대신 `10.0.2.2` 사용 |
| `401 Unauthorized` | Bearer token 만료·누락 및 Security 공개 경로 확인 |
| OpenAI `401` | API key와 프로젝트 사용 한도 확인 |

### 기존 PostgreSQL이 5432를 사용 중일 때

`docker compose ps`에는 아무것도 없는데 `docker ps`의 다른 컨테이너가 5432를
사용한다면 다음 중 하나만 선택한다.

1. 기존 DB를 계속 사용: 기존 DB 비밀번호를 `.env`의 `DB_PASSWORD`와 IntelliJ
   Run Configuration에 넣는다.
2. 이 프로젝트 DB를 사용: 기존 컨테이너를 먼저 중지하고 `docker compose up -d`를
   실행한다. 기존 컨테이너 삭제나 volume 삭제는 하지 않는다.

IntelliJ는 프로젝트의 `.env`를 자동으로 읽지 않는다. `.env`를 만들었더라도 Run
Configuration의 Environment variables에 넣지 않았다면 기본값으로 접속한다.
