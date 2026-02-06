# RabbitMQ

AMQP 메시지 브로커 설정입니다.

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

### RabbitMQ

| 항목 | Dev | Secure |
|------|-----|--------|
| AMQP 포트 | 5672 | 5672 |
| 인증 | guest / guest | admin / your-secure-password-here |

### Management UI (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:15672 | http://localhost:15672 |
| 계정 | guest / guest | admin / your-secure-password-here |

## 클라이언트 연결 예시

### Dev 버전

```
amqp://guest:guest@localhost:5672/
```

### Secure 버전

```
amqp://admin:your-secure-password-here@localhost:5672/
```

## 파일 설명

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | Dev 버전 (Management UI 없음) |
| `docker-compose.secure.yml` | Secure 버전 (Management UI 없음) |
| `docker-compose.ui.yml` | UI (Management 이미지로 전환) |
| `.env.example` | 환경변수 템플릿 |

> RabbitMQ는 다른 서비스와 달리 UI가 이미지 자체에 포함되어 있습니다.
> - 기본 파일: `rabbitmq:3-alpine` 이미지 사용 (UI 없음)
> - UI 파일: `rabbitmq:3-management-alpine` 이미지로 오버라이드하여 UI 활성화
