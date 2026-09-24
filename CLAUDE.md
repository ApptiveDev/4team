# CLAUDE.md

Claude Code는 `AGENTS.md`를 자동으로 읽지 않으므로 이 파일에서 불러온다. 규칙은
`AGENTS.md`에만 작성하고 여기에 복제하지 않는다.

@AGENTS.md

## 작업 전 확인

- API 필드·enum·에러 코드는 [`docs/api-contract.md`](docs/api-contract.md)가 기준이다.
  구현이 계약과 다르면 우회하지 말고 차이를 사용자에게 알린다.
- 담당 영역의 `frontend/AGENTS.md` 또는 `backend/AGENTS.md`는 해당 폴더의
  `CLAUDE.md`가 불러온다.
- 개인 설정(담당 역할, 로컬 전용 환경)은 git에 올라가지 않는 `CLAUDE.local.md`에 둔다.
