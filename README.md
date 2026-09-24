# 삶을 기록해주는 AI (가제) — 가족 썸원 컨셉

> 부모와 자녀를 초대 코드로 1:1 연결하고, 매일 같은 질문에 부모는 **음성**으로,
> 자녀는 **텍스트**로 답한다. 상대 답변 공개 조건은 서버 정책으로 판단하며
> 세부 정책은 2026-09-25까지 확정한다.
> 부모의 답변은 STT → LLM 정리를 거쳐 원본 육성 + 정리 자막으로 제공하고,
> 자녀의 답변은 TTS로 부모에게 낭독한다.

- MVP 프로토타입 마감: **2026-10-02**
- 정식 출시 목표: **2026년 12월 초**
- 팀 구성: 프론트엔드 3명, 백엔드 1명
- API 계약: [`docs/api-contract.md`](docs/api-contract.md)

## 기술 스택

| 영역 | 기술 |
|---|---|
| 프론트엔드 | Flutter (Dart) — 녹음 `record`, 재생 `just_audio` |
| 백엔드 | Spring Boot (Java 17), REST API, Layered Architecture |
| DB | PostgreSQL (개발: Docker 컨테이너 / 출시: AWS RDS PostgreSQL) |
| STT / LLM 정리 / TTS | **OpenAI 단일 벤더** — `gpt-transcribe` / `gpt-5-mini` / `gpt-4o-mini-tts` (질문 음성 안내는 질문 등록 시 사전 생성·캐싱) |
| 스토리지(원본 음성 아카이빙) | Cloudflare R2 (S3 호환 SDK 사용) |

## 저장소 구조

```
/
├── README.md              ← 이 파일
├── AGENTS.md               ← 프로젝트 공통 규칙 (반드시 먼저 읽기)
├── docs/
│   └── api-contract.md     ← API 요청·응답·상태값의 단일 진실 공급원
├── frontend/
│   ├── AGENTS.md           ← Flutter 컨벤션, 화면별 담당, 프론트 전용 일정
│   └── (Flutter 프로젝트)
└── backend/
    ├── AGENTS.md           ← Spring Boot 구현 규칙과 백엔드 작업 순서
    └── (Spring Boot 프로젝트)
```

**읽는 순서**: 이 README → 루트 `AGENTS.md` → `docs/api-contract.md` → 각자
역할에 맞는 `frontend/AGENTS.md` 또는 `backend/AGENTS.md`.

## 로컬 개발 환경 시작하기

### 백엔드

```bash
cd backend
cp .env.example .env          # 환경 변수 채우기 (API 키 등은 팀 비공개 채널에서 공유)
docker compose up -d          # PostgreSQL 컨테이너 기동 (5432 포트)
set -a
source .env
set +a
./gradlew bootRun             # 또는 IDE에서 Application 클래스 실행
```

### 프론트엔드

```bash
cd frontend
flutter pub get
flutter run                   # API_BASE_URL은 lib/config/env.dart 에서 로컬 백엔드 주소로 설정
```

## 일정 개요

| 날짜 | 마일스톤 |
|---|---|
| 9/24 | 저장소 세팅, API 계약 v0, 프로젝트 스캐폴드 |
| 9/25 ~ 9/30 | 핵심 루프(페어링→질문→녹음→STT/LLM→공개→재생) 순차 구현 |
| 10/1 | 통합 QA, 엣지케이스 처리 |
| 10/2 | MVP 프로토타입 제출 |
| 12월 초 | 정식 출시 |

## 연동 문제가 생겼을 때

프론트-백엔드 API가 안 맞거나 스펙이 애매하면 `[API]` GitHub Issue를 만들고,
코드와 [`docs/api-contract.md`](docs/api-contract.md)를 같은 PR에서 변경합니다.
처리 방식은 루트 `AGENTS.md`에 정리되어 있습니다.
