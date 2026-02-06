# PostgreSQL

관계형 데이터베이스 설정입니다.

## 실행 방법

```bash
# Dev (서비스만)
docker compose up -d

# Dev + UI
docker compose -f docker-compose.yml -f docker-compose.ui.yml up -d

# Secure (서비스만)
docker compose -f docker-compose.secure.yml up -d

# Secure + UI (.env 설정 필요)
cp .env.example .env
# .env 파일을 편집하여 PGADMIN_PASSWORD 설정
docker compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

## 접속 정보

### PostgreSQL

| 항목 | Dev | Secure |
|------|-----|--------|
| 포트 | 5432 | 5432 |
| 사용자 | postgres | postgres |
| 비밀번호 | postgres | your-secure-admin-password-here |
| 기본 DB | dev | production |

### pgAdmin (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:5050 | http://localhost:5050 |
| 계정 | admin@local.dev / admin | admin@local.dev / your-secure-password-here |

pgAdmin 접속 후 서버 추가:
- Host: `postgresql` (Docker 네트워크 내부) 또는 `host.docker.internal` (호스트에서)
- Port: `5432`
- Username/Password: 위 PostgreSQL 접속 정보 참조

## 클라이언트 연결 예시

### Dev 버전

```bash
psql -h localhost -p 5432 -U postgres -d dev
# 비밀번호: postgres
```

### Secure 버전

```bash
psql -h localhost -p 5432 -U postgres -d production
# 비밀번호: your-secure-admin-password-here
```

## 데이터 저장

데이터는 `./data` 디렉토리에 저장됩니다.

## 파일 설명

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | Dev 버전 |
| `docker-compose.secure.yml` | Secure 버전 |
| `docker-compose.ui.yml` | UI (환경변수로 dev/secure 지원) |
| `.env.example` | 환경변수 템플릿 |
