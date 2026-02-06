# MongoDB

NoSQL 문서 데이터베이스 설정입니다.

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
# .env 파일을 편집하여 인증 정보 설정
docker compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

## 접속 정보

### MongoDB

| 항목 | Dev | Secure |
|------|-----|--------|
| 포트 | 27017 | 27017 |
| 인증 | 비활성화 | admin / your-secure-password-here |
| 기본 DB | - | production |

### Mongo Express (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:8081 | http://localhost:8081 |
| 계정 | 없음 | admin / your-secure-password-here |

## 클라이언트 연결 예시

### Dev 버전

```
mongodb://localhost:27017
```

### Secure 버전

```
mongodb://admin:your-secure-password-here@localhost:27017
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
