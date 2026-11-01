# 검증 결과 — 2026-11-01 (한국 시간)

## 실제 실행한 검증

현재 연결된 macOS 호스트의 Docker Linux 엔진에서 다음을 확인했습니다.
Windows 컴퓨터나 GitHub Actions에서 실행한 결과는 아닙니다.

| 항목 | 결과 |
| --- | --- |
| 고정한 원본 커밋 | `767bbd9c3d1905acb04891d5c5e208de17b34a71` |
| 원본 소스 무변경 검사 | 다운로드한 원본 아카이브와 16개 파일의 바이트 일치 |
| Workflow YAML | 파싱 성공, Windows 러너 라벨·수동 실행 트리거 확인 |
| Compose 설정 | `docker compose config --quiet` 성공 |
| 소스 빌드 | `docker compose build` 성공 |
| Go 정적 검사 | `go vet ./...` 성공 |
| Go 테스트 명령 | `go test ./...` 성공, 원본에는 테스트 파일 없음 |
| 컨테이너 배포 | `up -d --no-build --wait` 성공 |
| `/health` | HTTP 200, `{"status":"ok"}` |
| `/` | HTTP 200, `cicd-ok-local-20261101` |
| `X-App-Version` | 빌드 인자로 지정한 `local-767bbd9c`와 일치 |
| 정리 | 테스트 컨테이너와 네트워크 삭제 성공 |

빌드한 이미지: `ito-http-echo-check:local-20261101`

베이스 이미지 해시:
`golang:1-alpine@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb`

HTTP 검증은 Python 표준 라이브러리로 실제 응답을 읽어 확인했습니다.
GitHub 워크플로에서는 같은 판정 기준을 Windows PowerShell과 `curl.exe`로 실행합니다.
Windows PowerShell 단계와 GitHub Actions 전체 실행은 아직 검증하지 않았습니다.
실행 요약은 PowerShell에서 UTF-8로 기록하도록 설정했습니다.

## Windows에서 남은 확인

1. Docker Desktop의 Linux containers 모드와 러너 사용자 계정의 Docker 접근.
2. 자신의 GitHub 테스트 저장소에 파일을 올리고 러너를 등록.
3. `workflow.yaml`을 실행하고 대상 커밋의 Actions 결과·로그 확인.

GitHub 저장소 생성·업로드·러너 등록은 수행하지 않았습니다.

## GitHub 호스팅 러너용 워크플로 추가 검증 — 2026-11-02 (한국 시간)

`.github/workflows/cloud-check.yaml`을 추가했습니다. `ubuntu-latest`와 Bash를 사용하므로
현재 작업 노트북의 OS나 Windows self-hosted runner 없이 수동 실행할 수 있습니다.

- YAML을 파싱하고 모든 Bash 단계의 구문 검사를 통과했습니다.
- 새 워크플로의 배포·상태 확인·HTTP 검증·로그·정리 명령을 현재 macOS의
  Docker Linux 엔진에서 실행했습니다.
- Dockerfile과 원본 소스는 변경하지 않아 앞서 빌드한 동일 이미지를 재사용했습니다.
- 정상 응답과 빌드 버전이 맞으면 성공했습니다.
- 기대하는 실행 식별값을 바꾸면 검증이 실패했습니다.
- 기대하는 빌드 버전을 바꾸면 검증이 실패했습니다.
- 검증 후 테스트 컨테이너와 네트워크를 정리했습니다.

이 결과는 로컬에서 수행한 검증입니다. 새 워크플로의 GitHub Actions 실행과
Windows 호스트 검증은 아직 수행하지 않았습니다.
