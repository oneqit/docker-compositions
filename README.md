# Docker Compositions

백엔드 인프라용 Docker Compose 파일 모음입니다.

## 구조

각 서비스마다 다음 파일을 제공합니다:
- **dev (기본)**: `docker-compose.yml` - 보안 비활성화, 빠른 로컬 개발용
- **secure**: `docker-compose.secure.yml` - 보안 활성화, 운영 환경 참고용
- **ui**: `docker-compose.ui.yml` - 관리 UI
- **.env.example**: 환경변수 템플릿

```
docker-compositions/
├── start.sh              # 대화형 실행 스크립트
├── .gitignore
├── redis/
│   ├── docker-compose.yml
│   ├── docker-compose.secure.yml
│   ├── docker-compose.ui.yml
│   └── .env.example
├── rabbitmq/
├── kafka/
├── mysql/
├── mongodb/
├── postgresql/
└── elasticsearch/
```

각 서비스의 상세 설정 및 접속 정보는 해당 디렉토리의 README.md를 참조하세요.

## 빠른 시작

### 대화형 스크립트 사용 (권장)

```bash
./start.sh
```

스크립트가 다음을 대화형으로 안내합니다:
1. 서비스 선택 (다중 선택 가능)
2. 모드 선택 (dev / secure)
3. UI 포함 여부
4. Kafka의 경우 KRaft / Zookeeper 선택

### 수동 실행

#### 서비스만 실행

```bash
cd <service>

# Dev 버전
docker-compose up -d

# Secure 버전
docker-compose -f docker-compose.secure.yml up -d
```

#### 서비스 + UI 실행

```bash
cd <service>

# Dev 버전 + UI
docker-compose -f docker-compose.yml -f docker-compose.ui.yml up -d

# Secure 버전 + UI (.env 설정 필요)
cp .env.example .env
# .env 파일을 편집하여 인증 정보 설정
docker-compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

### 서비스 중지

```bash
docker-compose down
# 또는 secure 버전의 경우
docker-compose -f docker-compose.secure.yml down
# 또는 UI 포함 버전의 경우
docker-compose -f docker-compose.yml -f docker-compose.ui.yml down
```

## 환경변수 (.env) 설정

Secure 모드에서 UI를 사용할 때는 `.env` 파일에 인증 정보를 설정해야 합니다.

```bash
# 1. .env.example을 .env로 복사
cp .env.example .env

# 2. .env 파일을 편집하여 인증 정보 설정
vi .env

# 3. docker-compose 실행 (같은 디렉토리의 .env를 자동으로 읽음)
docker-compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

## 서비스 목록

| 서비스 | 기본 포트 | 관리 UI | UI 포트 |
|--------|----------|---------|---------|
| Redis | 6379 | Redis Commander | 8081 |
| RabbitMQ | 5672 | Management UI | 15672 |
| Kafka | 9092 | Kafka UI | 8080 |
| MySQL | 3306 | phpMyAdmin | 8080 |
| MongoDB | 27017 | Mongo Express | 8081 |
| PostgreSQL | 5432 | pgAdmin | 5050 |
| Elasticsearch | 9200 | Kibana | 5601 |

## 파일 구조

각 서비스 디렉토리의 파일 구조:

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | 기본 서비스 (보안 없음) |
| `docker-compose.secure.yml` | 보안이 적용된 서비스 |
| `docker-compose.ui.yml` | 관리 UI (환경변수로 dev/secure 모두 지원) |
| `.env.example` | 환경변수 템플릿 |

## 주의사항

1. **Secure 버전 사용 시**: 반드시 기본 비밀번호를 변경하세요.
2. **데이터 볼륨**: DB/스토리지 서비스는 `./data` 디렉토리에 데이터를 저장합니다.
3. **네트워크**: 각 서비스는 독립적인 브리지 네트워크를 사용합니다.
4. **포트 충돌**: 여러 서비스를 동시에 실행할 경우 UI 포트가 충돌할 수 있습니다 (예: Kafka UI와 phpMyAdmin 모두 8080 사용).
