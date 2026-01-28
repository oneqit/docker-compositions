# Redis

인메모리 데이터 저장소 설정입니다.

## 실행 방법

```bash
# Dev (서비스만)
docker-compose up -d

# Dev + UI
docker-compose -f docker-compose.yml -f docker-compose.ui.yml up -d

# Secure (서비스만)
docker-compose -f docker-compose.secure.yml up -d

# Secure + UI (.env 설정 필요)
cp .env.example .env
# .env 파일을 편집하여 REDIS_COMMANDER_HOSTS 설정
docker-compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

## 접속 정보

### Redis

| 항목 | Dev | Secure |
|------|-----|--------|
| 포트 | 6379 | 6379 |
| 인증 | 없음 | your-secure-password-here |

### Redis Commander (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:8081 | http://localhost:8081 |
| 인증 | 없음 | 없음 (Redis 인증 정보 자동 연동) |

## 클라이언트 연결 예시

### Dev 버전

```
redis://localhost:6379
```

### Secure 버전

```
redis://:your-secure-password-here@localhost:6379
```

## redis-cli 사용

### Dev 버전

```bash
redis-cli -h localhost -p 6379
```

### Secure 버전

```bash
redis-cli -h localhost -p 6379 -a your-secure-password-here
```

## 파일 설명

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | Dev 버전 |
| `docker-compose.secure.yml` | Secure 버전 |
| `docker-compose.ui.yml` | UI (환경변수로 dev/secure 지원) |
| `.env.example` | 환경변수 템플릿 |
