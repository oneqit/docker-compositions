#!/bin/bash

# Docker Compositions - Interactive Start Script
# 서비스 선택, 모드 선택, UI 포함 여부를 대화형으로 선택합니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 서비스 목록 (인덱스 기반 배열로 변경 - bash 3.2 호환)
SERVICE_DIRS=("" "redis" "rabbitmq" "kafka" "mysql" "mongodb" "postgresql" "elasticsearch")
SERVICE_NAMES=("" "Redis" "RabbitMQ" "Kafka" "MySQL" "MongoDB" "PostgreSQL" "Elasticsearch")

print_header() {
    echo -e "\n${BLUE}=== Docker Compositions ===${NC}\n"
}

print_services() {
    echo -e "${YELLOW}서비스 선택 (공백으로 구분, 예: 1 3 5):${NC}"
    for i in 1 2 3 4 5 6 7; do
        echo "  $i) ${SERVICE_NAMES[$i]}"
    done
    echo ""
}

print_mode_options() {
    echo -e "${YELLOW}모드 선택:${NC}"
    echo "  1) dev (기본, 보안 없음)"
    echo "  2) secure (보안 활성화)"
    echo ""
}

print_ui_options() {
    echo -e "${YELLOW}UI 포함 여부:${NC}"
    echo "  1) 서비스만"
    echo "  2) 서비스 + 관리 UI"
    echo ""
}

print_kafka_options() {
    echo -e "${YELLOW}Kafka 모드 선택:${NC}"
    echo "  1) KRaft (권장, Zookeeper 없음)"
    echo "  2) Zookeeper (기존 방식)"
    echo ""
}

check_env_file() {
    local service_dir=$1
    local mode=$2
    local include_ui=$3

    if [[ "$mode" == "secure" && "$include_ui" == "yes" ]]; then
        if [[ ! -f "$SCRIPT_DIR/$service_dir/.env" ]]; then
            echo -e "${YELLOW}주의: $service_dir/.env 파일이 없습니다.${NC}"
            echo -e "  secure 모드 + UI 사용 시 .env 파일 설정이 필요할 수 있습니다."
            echo -e "  .env.example을 .env로 복사하여 설정하세요:"
            echo -e "  ${GREEN}cp $service_dir/.env.example $service_dir/.env${NC}"
            echo ""
        fi
    fi
}

get_compose_files() {
    local service_dir=$1
    local mode=$2
    local include_ui=$3
    local kafka_mode=$4

    local base_file=""
    local ui_file=""

    if [[ "$service_dir" == "kafka" ]]; then
        if [[ "$kafka_mode" == "zookeeper" ]]; then
            if [[ "$mode" == "secure" ]]; then
                base_file="docker-compose.zookeeper.secure.yml"
            else
                base_file="docker-compose.zookeeper.yml"
            fi
            ui_file="docker-compose.zookeeper.ui.yml"
        else
            if [[ "$mode" == "secure" ]]; then
                base_file="docker-compose.secure.yml"
            else
                base_file="docker-compose.yml"
            fi
            ui_file="docker-compose.ui.yml"
        fi
    else
        if [[ "$mode" == "secure" ]]; then
            base_file="docker-compose.secure.yml"
        else
            base_file="docker-compose.yml"
        fi
        ui_file="docker-compose.ui.yml"
    fi

    local files="-f $base_file"
    if [[ "$include_ui" == "yes" ]]; then
        files="$files -f $ui_file"
    fi

    echo "$files"
}

start_service() {
    local service_dir=$1
    local service_name=$2
    local mode=$3
    local include_ui=$4
    local kafka_mode=$5

    check_env_file "$service_dir" "$mode" "$include_ui"

    local compose_files=$(get_compose_files "$service_dir" "$mode" "$include_ui" "$kafka_mode")

    echo -e "${GREEN}Starting $service_name...${NC}"
    echo -e "  Directory: $service_dir"
    echo -e "  Mode: $mode"
    echo -e "  UI: $include_ui"
    if [[ "$service_dir" == "kafka" ]]; then
        echo -e "  Kafka Mode: $kafka_mode"
    fi
    echo -e "  Command: docker-compose $compose_files up -d"
    echo ""

    cd "$SCRIPT_DIR/$service_dir"
    docker-compose $compose_files up -d
    cd "$SCRIPT_DIR"

    echo ""
}

main() {
    print_header

    # 서비스 선택
    print_services
    read -p "선택: " service_input

    if [[ -z "$service_input" ]]; then
        echo -e "${RED}서비스를 선택해주세요.${NC}"
        exit 1
    fi

    # 선택된 서비스 검증
    selected_services=()
    for num in $service_input; do
        if [[ "$num" =~ ^[1-7]$ ]] && [[ -n "${SERVICE_DIRS[$num]}" ]]; then
            selected_services+=("$num")
        else
            echo -e "${RED}잘못된 선택: $num${NC}"
        fi
    done

    if [[ ${#selected_services[@]} -eq 0 ]]; then
        echo -e "${RED}유효한 서비스가 선택되지 않았습니다.${NC}"
        exit 1
    fi

    # 모드 선택
    print_mode_options
    read -p "선택 [1]: " mode_input
    mode_input=${mode_input:-1}

    case $mode_input in
        1) mode="dev" ;;
        2) mode="secure" ;;
        *)
            echo -e "${RED}잘못된 모드 선택${NC}"
            exit 1
            ;;
    esac

    # UI 포함 여부
    print_ui_options
    read -p "선택 [1]: " ui_input
    ui_input=${ui_input:-1}

    case $ui_input in
        1) include_ui="no" ;;
        2) include_ui="yes" ;;
        *)
            echo -e "${RED}잘못된 UI 선택${NC}"
            exit 1
            ;;
    esac

    # Kafka가 선택된 경우 KRaft/Zookeeper 선택
    kafka_mode="kraft"
    for num in "${selected_services[@]}"; do
        if [[ "${SERVICE_DIRS[$num]}" == "kafka" ]]; then
            print_kafka_options
            read -p "선택 [1]: " kafka_input
            kafka_input=${kafka_input:-1}

            case $kafka_input in
                1) kafka_mode="kraft" ;;
                2) kafka_mode="zookeeper" ;;
                *)
                    echo -e "${RED}잘못된 Kafka 모드 선택${NC}"
                    exit 1
                    ;;
            esac
            break
        fi
    done

    echo ""
    echo -e "${BLUE}=== 실행 시작 ===${NC}"
    echo ""

    # 서비스 시작
    for num in "${selected_services[@]}"; do
        start_service "${SERVICE_DIRS[$num]}" "${SERVICE_NAMES[$num]}" "$mode" "$include_ui" "$kafka_mode"
    done

    echo -e "${GREEN}=== 완료 ===${NC}"
    echo ""
    echo "실행 중인 컨테이너 확인: docker ps"
    echo "서비스 중지: docker-compose down (각 서비스 디렉토리에서)"
}

main "$@"
