# Kafka

Apache Kafka 메시지 브로커 설정입니다.

## 버전

- **KRaft (기본)**: Zookeeper 없이 Kafka 자체 메타데이터 관리
- **Zookeeper**: 기존 Zookeeper 기반 구성

## 실행 방법

### KRaft 버전 (권장)

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

### Zookeeper 버전

```bash
# Dev (서비스만)
docker compose -f docker-compose.zookeeper.yml up -d

# Dev + UI
docker compose -f docker-compose.zookeeper.yml -f docker-compose.zookeeper.ui.yml up -d

# Secure (서비스만)
docker compose -f docker-compose.zookeeper.secure.yml up -d

# Secure + UI (.env 설정 필요)
cp .env.example .env
# .env 파일을 편집하여 인증 정보 설정
docker compose -f docker-compose.zookeeper.secure.yml -f docker-compose.zookeeper.ui.yml up -d
```

## 접속 정보

### Kafka

| 항목 | Dev | Secure |
|------|-----|--------|
| 포트 | 9092 | 9092 |
| 프로토콜 | PLAINTEXT | SASL_PLAINTEXT |
| 인증 | 없음 | admin / your-secure-password-here |

### Kafka UI (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:8080 | http://localhost:8080 |
| 인증 | 없음 | 없음 (Kafka 인증 정보 자동 연동) |

## 클라이언트 연결 예시

### Dev 버전

```properties
bootstrap.servers=localhost:9092
```

### Secure 버전

```properties
bootstrap.servers=localhost:9092
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="admin" password="your-secure-password-here";
```

## 파일 설명

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | KRaft dev 버전 |
| `docker-compose.secure.yml` | KRaft secure 버전 |
| `docker-compose.ui.yml` | KRaft UI (환경변수로 dev/secure 지원) |
| `docker-compose.zookeeper.yml` | Zookeeper dev 버전 |
| `docker-compose.zookeeper.secure.yml` | Zookeeper secure 버전 |
| `docker-compose.zookeeper.ui.yml` | Zookeeper UI (환경변수로 dev/secure 지원) |
| `.env.example` | 환경변수 템플릿 |
| `kafka_jaas.conf` | Kafka SASL 인증 설정 |
| `zookeeper_jaas.conf` | Zookeeper SASL 인증 설정 |
