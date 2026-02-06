# MySQL

관계형 데이터베이스 설정입니다.

## 실행 방법

```bash
# Dev (서비스만)
docker compose up -d

# Dev + UI
docker compose -f docker-compose.yml -f docker-compose.ui.yml up -d

# Secure (서비스만)
docker compose -f docker-compose.secure.yml up -d

# Secure + UI
docker compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

## 접속 정보

### MySQL

| 항목 | Dev | Secure |
|------|-----|--------|
| 포트 | 3306 | 3306 |
| Root 비밀번호 | root | your-secure-root-password-here |
| 일반 사용자 | - | appuser / your-secure-user-password-here |
| 기본 DB | dev | production |

### phpMyAdmin (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:8080 | http://localhost:8080 |
| 계정 | root / root | root / your-secure-root-password-here |

## 클라이언트 연결 예시

### Dev 버전

```bash
mysql -h localhost -P 3306 -u root -proot dev
```

### Secure 버전

```bash
# Root 사용자
mysql -h localhost -P 3306 -u root -p'your-secure-root-password-here' production

# 일반 사용자
mysql -h localhost -P 3306 -u appuser -p'your-secure-user-password-here' production
```

## 데이터 저장

데이터는 `./data` 디렉토리에 저장됩니다.

## 파일 설명

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | Dev 버전 |
| `docker-compose.secure.yml` | Secure 버전 |
| `docker-compose.ui.yml` | UI (phpMyAdmin) |
| `.env.example` | 환경변수 템플릿 |
