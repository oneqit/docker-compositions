# Elasticsearch

검색 및 분석 엔진 설정입니다.

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
# .env 파일을 편집하여 인증 정보 설정
docker-compose -f docker-compose.secure.yml -f docker-compose.ui.yml up -d
```

## 접속 정보

### Elasticsearch

| 항목 | Dev | Secure |
|------|-----|--------|
| HTTP 포트 | 9200 | 9200 |
| Transport 포트 | 9300 | 9300 |
| xpack.security | 비활성화 | 활성화 |
| 계정 | 없음 | elastic / your-secure-password-here |

### Kibana (UI 포함 실행 시)

| 항목 | Dev | Secure |
|------|-----|--------|
| URL | http://localhost:5601 | http://localhost:5601 |
| 계정 | 없음 | elastic / your-secure-password-here |

## 클라이언트 연결 예시

### Dev 버전

```
http://localhost:9200
```

### Secure 버전

```
http://elastic:your-secure-password-here@localhost:9200
```

## 주의사항

- 최소 512MB 힙 메모리가 필요합니다
- 운영 환경에서는 `ES_JAVA_OPTS`를 조정하세요
- 데이터는 `./data` 디렉토리에 저장됩니다

## 파일 설명

| 파일 | 설명 |
|------|------|
| `docker-compose.yml` | Dev 버전 |
| `docker-compose.secure.yml` | Secure 버전 |
| `docker-compose.ui.yml` | UI (환경변수로 dev/secure 지원) |
| `.env.example` | 환경변수 템플릿 |
