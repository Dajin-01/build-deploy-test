# Docker CI/CD 검증 샘플

HashiCorp의 작은 Go 웹 서버 `http-echo`를 실제 소스에서 빌드하고,
GitHub의 Linux 러너 또는 Windows의 Docker Desktop에 테스트용 Linux 컨테이너로 배포합니다.
이번 실행의 응답 문구와 빌드에 포함된 커밋을 확인한 후 컨테이너를 정리합니다.

## 구성

- `source/http-echo/`: 원본 오픈소스 소스와 MPL-2.0 라이선스.
- `Dockerfile`: 컨테이너 안에서 Go 정적 검사, `go test`, 바이너리 빌드.
- `compose.test.yaml`: 단일 컨테이너와 localhost 전용 테스트 포트 18080.
- `.github/workflows/cloud-check.yaml`: Windows 컴퓨터 없이 GitHub의 Ubuntu 러너에서 실행할 수동 워크플로.
- `.github/workflows/workflow.yaml`: Windows self-hosted runner에서 실행할 수동 워크플로.

원본: https://github.com/hashicorp/http-echo

고정한 원본 커밋: `767bbd9c3d1905acb04891d5c5e208de17b34a71`

원본 소스는 변경하지 않았습니다. 원본 Dockerfile은 릴리스 바이너리를 요구하므로
프로젝트 루트에 소스 빌드용 Dockerfile을 별도로 두었습니다.
Go 기반 이미지는 `golang:1-alpine`이므로 빌드 시점의 1.x 이미지가 사용됩니다.
원본에는 현재 Go 단위 테스트 파일이 없으며, `go test` 성공만으로 기능 검증을
주장하지 않습니다. 실제 기능은 HTTP 응답과 빌드 버전으로 검증합니다.

## Windows 컴퓨터 없이 GitHub에서 먼저 검증하기

Mac에서 이 저장소를 편집하고 push해도 됩니다. `cloud-check.yaml`이 기본 브랜치에
올라가면 Actions → **HTTP Echo Cloud Check** → Run workflow에서 실행합니다.
GitHub가 제공하는 `ubuntu-latest` 러너에서 빌드·테스트 배포·HTTP 검증을 수행하므로
현재 노트북에 self-hosted runner를 설치할 필요가 없습니다.

Actions 그래프에는 **build → deploy** 두 작업이 표시됩니다.
`build`에서 Go 검사와 이미지 빌드를 수행한 뒤 Docker 이미지를 아티팩트로 저장합니다.
`deploy`는 `needs: build`로 연결되어 빌드 성공 후에만 실행하며, 다른 러너에서
아티팩트를 받아 이미지를 로드하고 배포·HTTP 검증·정리를 수행합니다.
배포 단계는 이미지를 다시 빌드하거나 레지스트리에서 가져오지 않습니다.
이미지 아티팩트는 1일간 보관하며, 만료 후에는 전체 워크플로를 다시 실행하면 됩니다.

이 실행은 Linux 컨테이너의 빌드와 앱 응답을 검증합니다. Windows의 Docker Desktop,
PowerShell, 경로·권한 등 호스트 환경 검증은 나중에 Windows 컴퓨터를 연결하고
기존 **HTTP Echo Build Deploy Check** 워크플로를 실행해 확인합니다.

두 워크플로 모두 실행 중에만 컨테이너를 띄웁니다. 외부에 공개되는 상시 서비스나
Windows 내부 컴퓨터에 대한 원격 배포는 구성하지 않습니다.

## Windows에서 먼저 실행해 보기

Docker Desktop을 시작하고 Linux containers 모드를 사용합니다.
PowerShell에서 이 README가 있는 폴더로 이동한 뒤 실행합니다.
Windows에 Go를 별도로 설치할 필요는 없습니다.

```powershell
docker compose -f compose.test.yaml -p ito-echo-local build
docker compose -f compose.test.yaml -p ito-echo-local up -d --no-build
curl.exe --fail --retry 12 --retry-delay 2 --retry-connrefused http://127.0.0.1:18080/health
curl.exe --fail -i http://127.0.0.1:18080/
```

정상 응답은 `/health`의 `{"status":"ok"}`, `/`의 `cicd-ok-local`,
그리고 `X-App-Version: local-test` 헤더입니다. 종료 시 정리합니다.

```powershell
docker compose -f compose.test.yaml -p ito-echo-local down
```

## GitHub Actions 연결

Windows용 **HTTP Echo Build Deploy Check**도 그래프에 **build → deploy**로 표시됩니다.
두 작업은 모두 `self-hosted`, `windows`, `internal-test` 라벨을 가진 러너에서 실행합니다.
빌드한 이미지를 아티팩트로 전달하므로 같은 러너의 로컬 이미지에 의존하지 않습니다.
러너가 여러 대라면 이미지 실행이 가능한 동일 CPU 아키텍처로 구성해야 하며,
실제 배포 대상 컴퓨터가 선택되도록 러너 라벨을 구분하세요.

1. 이 폴더의 **내용**을 자신의 테스트 전용 GitHub 저장소 루트에 올립니다.
   `.github` 숨김 폴더와 원본 `source/http-echo/LICENSE`도 포함합니다.
2. 저장소의 Settings → Actions → Runners → New self-hosted runner에서
   Windows를 선택해 안내대로 설치·등록하고 `internal-test` 라벨을 추가합니다.
3. 처음에는 Docker Desktop을 실행한 사용자 계정의 터미널에서 러너의
   `.\run.cmd`를 실행합니다. 러너에 Git과 `curl.exe`가 있어야 하며,
   최신 러너를 사용합니다. 별도 서비스 계정을 쓰면 Docker 접근도 확인합니다.
4. 워크플로를 저장소의 기본 브랜치에 올린 뒤 Actions에서 수동 실행합니다.
5. 에이전트는 GitHub CLI로 대상 커밋의 실행 결과와 로그를 읽습니다.

```powershell
gh workflow run workflow.yaml --ref main
gh run list --workflow workflow.yaml --branch main --limit 5 --json databaseId,headSha,status,conclusion
gh run watch <대상-커밋과-일치하는-실행-ID> --exit-status
gh run view <실행-ID> --log
```

에이전트 쪽 GitHub CLI 인증에는 해당 저장소의 워크플로 실행·조회 권한이
필요합니다. runner는 GitHub 및 Docker Hub에 접속할 수 있어야 합니다.
에이전트가 Windows의 localhost에 직접 접속할 필요는 없습니다.

## 성공 기준

- 이번 저장소 커밋에서 Docker 이미지 빌드가 성공한다.
- 그 이미지로 테스트 컨테이너가 실행된다.
- `/health`가 성공하고 `/`가 이번 실행의 고유 문구를 반환한다.
- 응답의 `X-App-Version`이 워크플로가 checkout한 커밋 SHA와 같다.
- Actions 로그와 실행 요약에 성공 증거가 남는다.

컨테이너와 네트워크는 성공·실패 후 정리합니다. 볼륨은 사용하지 않으며
이미지와 빌드 캐시는 남습니다. 배포를 지속하거나 외부에 공개하는 설정은
포함하지 않았습니다. 취소·컴퓨터 종료 등으로 정리가 중단되면 로그에 나온
프로젝트 이름을 사용해 `docker compose -f compose.test.yaml -p <이름> down`을
실행합니다.

실제 확인한 결과와 플랫폼 범위는 `VALIDATION.md`를 참고하세요.
