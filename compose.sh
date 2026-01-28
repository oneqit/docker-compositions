#!/bin/bash

# Docker Compositions - Interactive Start/Stop Script
# Toggle services: running -> stop, stopped -> start

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Service list (index-based array for bash 3.2 compatibility)
SERVICE_DIRS=("" "redis" "rabbitmq" "kafka" "mysql" "mongodb" "postgresql" "elasticsearch")
SERVICE_NAMES=("" "Redis" "RabbitMQ" "Kafka" "MySQL" "MongoDB" "PostgreSQL" "Elasticsearch")

# Container name mapping
# dev mode: oneqit_{container}
# secure mode: oneqit_{container}_secure
# ui: oneqit_{ui_container}
SERVICE_CONTAINERS=("" "redis" "rabbitmq" "kafka" "mysql" "mongodb" "postgresql" "elasticsearch")
SERVICE_UI_CONTAINERS=("" "redis_commander" "" "kafka_ui" "phpmyadmin" "mongo_express" "pgadmin" "kibana")

# Service status (empty: stopped, dev: dev mode, secure: secure mode)
SERVICE_MODE=("" "" "" "" "" "" "" "")
# UI status (0: no ui, 1: ui running)
SERVICE_UI=("" "0" "0" "0" "0" "0" "0" "0")

print_header() {
    echo -e "\n${BLUE}=== Docker Compositions ===${NC}\n"
}

detect_running_services() {
    local running_containers=$(docker ps --format '{{.Names}}' 2>/dev/null)

    for i in 1 2 3 4 5 6 7; do
        local container="${SERVICE_CONTAINERS[$i]}"
        local ui_container="${SERVICE_UI_CONTAINERS[$i]}"
        SERVICE_MODE[$i]=""
        SERVICE_UI[$i]="0"

        # Check dev mode (oneqit_{container})
        if echo "$running_containers" | grep -q "^oneqit_${container}$"; then
            SERVICE_MODE[$i]="dev"
        fi

        # Check secure mode (oneqit_{container}_secure)
        if echo "$running_containers" | grep -q "^oneqit_${container}_secure$"; then
            SERVICE_MODE[$i]="secure"
        fi

        # Check UI (oneqit_{ui_container})
        if [[ -n "$ui_container" ]] && echo "$running_containers" | grep -q "^oneqit_${ui_container}$"; then
            SERVICE_UI[$i]="1"
        fi
    done
}

is_running() {
    [[ -n "${SERVICE_MODE[$1]}" ]]
}

get_status_label() {
    local idx=$1
    local mode="${SERVICE_MODE[$idx]}"
    local ui="${SERVICE_UI[$idx]}"

    if [[ -z "$mode" ]]; then
        echo ""
        return
    fi

    local label="$mode"
    if [[ "$ui" == "1" ]]; then
        label="$label+ui"
    fi
    echo " ${CYAN}[$label]${NC}"
}

print_services() {
    echo -e "${YELLOW}Select services (e.g. 1 3):${NC}"
    for i in 1 2 3 4 5 6 7; do
        local status_label=$(get_status_label $i)
        if is_running $i; then
            echo -e "  $i) ${GREEN}●${NC} ${SERVICE_NAMES[$i]}${status_label}"
        else
            echo -e "  $i) ${GRAY}○${NC} ${SERVICE_NAMES[$i]}"
        fi
    done
    echo ""
}

print_mode_options() {
    echo -e "${YELLOW}Select mode:${NC}"
    echo "  1) dev (default)"
    echo "  2) secure"
    echo ""
}

print_ui_options() {
    echo -e "${YELLOW}Include UI:${NC}"
    echo "  1) service only"
    echo "  2) service + admin UI"
    echo ""
}

print_kafka_options() {
    echo -e "${YELLOW}Kafka mode:${NC}"
    echo "  1) KRaft (recommended)"
    echo "  2) Zookeeper"
    echo ""
}

print_access_info() {
    local service_dir=$1
    local mode=$2
    local include_ui=$3

    echo -e "${CYAN}Access:${NC}"

    case "$service_dir" in
        redis)
            echo -e "  Redis:           ${GREEN}localhost:6379${NC}"
            if [[ "$mode" == "secure" ]]; then
                echo -e "  ${YELLOW}Password: your-secure-password-here (default)${NC}"
            fi
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  Redis Commander: ${GREEN}http://localhost:8081${NC}"
            fi
            ;;
        rabbitmq)
            echo -e "  RabbitMQ AMQP:   ${GREEN}localhost:5672${NC}"
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  RabbitMQ UI:     ${GREEN}http://localhost:15672${NC}"
            fi
            if [[ "$mode" == "secure" ]]; then
                echo -e "  ${YELLOW}Credentials: admin / your-secure-password-here (default)${NC}"
            elif [[ "$include_ui" == "yes" ]]; then
                echo -e "  ${YELLOW}Credentials: guest / guest${NC}"
            fi
            ;;
        kafka)
            if [[ "$mode" == "secure" ]]; then
                echo -e "  Kafka SASL:      ${GREEN}localhost:9092${NC}"
                echo -e "  ${YELLOW}SASL Credentials: admin / your-secure-password-here (default)${NC}"
            else
                echo -e "  Kafka:           ${GREEN}localhost:9092${NC}"
            fi
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  Kafka UI:        ${GREEN}http://localhost:8080${NC}"
            fi
            ;;
        mysql)
            echo -e "  MySQL:           ${GREEN}localhost:3306${NC}"
            if [[ "$mode" == "secure" ]]; then
                echo -e "  ${YELLOW}Root: root / your-secure-root-password-here (default)${NC}"
                echo -e "  ${YELLOW}User: appuser / your-secure-user-password-here (default)${NC}"
                echo -e "  ${YELLOW}Database: production (default)${NC}"
            fi
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  phpMyAdmin:      ${GREEN}http://localhost:8080${NC}"
            fi
            ;;
        mongodb)
            echo -e "  MongoDB:         ${GREEN}localhost:27017${NC}"
            if [[ "$mode" == "secure" ]]; then
                echo -e "  ${YELLOW}Credentials: admin / your-secure-password-here (default)${NC}"
                echo -e "  ${YELLOW}Database: production (default)${NC}"
            fi
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  Mongo Express:   ${GREEN}http://localhost:8081${NC}"
            fi
            ;;
        postgresql)
            echo -e "  PostgreSQL:      ${GREEN}localhost:5432${NC}"
            if [[ "$mode" == "secure" ]]; then
                echo -e "  ${YELLOW}Credentials: postgres / your-secure-admin-password-here (default)${NC}"
                echo -e "  ${YELLOW}Database: production (default)${NC}"
            fi
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  pgAdmin:         ${GREEN}http://localhost:5050${NC}"
                echo -e "  ${YELLOW}pgAdmin: admin@local.dev / admin${NC}"
            fi
            ;;
        elasticsearch)
            echo -e "  Elasticsearch:   ${GREEN}http://localhost:9200${NC}"
            if [[ "$mode" == "secure" ]]; then
                echo -e "  ${YELLOW}Credentials: elastic / your-secure-password-here (default)${NC}"
            fi
            if [[ "$include_ui" == "yes" ]]; then
                echo -e "  Kibana:          ${GREEN}http://localhost:5601${NC}"
            fi
            ;;
    esac

    if [[ "$mode" == "secure" ]]; then
        echo -e "  ${GRAY}Customize: cp $service_dir/.env.example $service_dir/.env${NC}"
    fi
    echo ""
}

check_env_file() {
    local service_dir=$1
    local mode=$2
    local include_ui=$3

    if [[ "$mode" == "secure" && "$include_ui" == "yes" ]]; then
        if [[ ! -f "$SCRIPT_DIR/$service_dir/.env" ]]; then
            echo -e "${YELLOW}Warning: $service_dir/.env not found${NC}"
            echo -e "  Copy .env.example to .env:"
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

    local files=""
    if [[ "$include_ui" == "yes" ]]; then
        files="-f $ui_file -f $base_file"
    else
        files="-f $base_file"
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
    echo -e "  Mode: $mode, UI: $include_ui"
    if [[ "$service_dir" == "kafka" ]]; then
        echo -e "  Kafka: $kafka_mode"
    fi

    cd "$SCRIPT_DIR/$service_dir"
    docker-compose $compose_files up -d
    cd "$SCRIPT_DIR"

    echo ""
    print_access_info "$service_dir" "$mode" "$include_ui"
}

stop_service() {
    local service_dir=$1
    local service_name=$2

    echo -e "${RED}Stopping $service_name...${NC}"

    cd "$SCRIPT_DIR/$service_dir"
    docker-compose down
    cd "$SCRIPT_DIR"

    echo ""
}

main() {
    print_header

    detect_running_services
    print_services
    read -p "> " service_input

    if [[ -z "$service_input" ]]; then
        echo -e "${RED}No service selected${NC}"
        exit 1
    fi

    to_start=()
    to_stop=()

    for num in $service_input; do
        if [[ "$num" =~ ^[1-7]$ ]] && [[ -n "${SERVICE_DIRS[$num]}" ]]; then
            if is_running $num; then
                to_stop+=("$num")
            else
                to_start+=("$num")
            fi
        else
            echo -e "${RED}Invalid selection: $num${NC}"
        fi
    done

    if [[ ${#to_stop[@]} -gt 0 ]]; then
        echo ""
        echo -e "${BLUE}=== Stopping ===${NC}"
        echo ""
        for num in "${to_stop[@]}"; do
            stop_service "${SERVICE_DIRS[$num]}" "${SERVICE_NAMES[$num]}"
        done
    fi

    if [[ ${#to_start[@]} -gt 0 ]]; then
        print_mode_options
        read -p "> [1]: " mode_input
        mode_input=${mode_input:-1}

        case $mode_input in
            1) mode="dev" ;;
            2) mode="secure" ;;
            *)
                echo -e "${RED}Invalid mode${NC}"
                exit 1
                ;;
        esac

        print_ui_options
        read -p "> [1]: " ui_input
        ui_input=${ui_input:-1}

        case $ui_input in
            1) include_ui="no" ;;
            2) include_ui="yes" ;;
            *)
                echo -e "${RED}Invalid UI option${NC}"
                exit 1
                ;;
        esac

        kafka_mode="kraft"
        for num in "${to_start[@]}"; do
            if [[ "${SERVICE_DIRS[$num]}" == "kafka" ]]; then
                print_kafka_options
                read -p "> [1]: " kafka_input
                kafka_input=${kafka_input:-1}

                case $kafka_input in
                    1) kafka_mode="kraft" ;;
                    2) kafka_mode="zookeeper" ;;
                    *)
                        echo -e "${RED}Invalid Kafka mode${NC}"
                        exit 1
                        ;;
                esac
                break
            fi
        done

        echo ""
        echo -e "${BLUE}=== Starting ===${NC}"
        echo ""

        for num in "${to_start[@]}"; do
            start_service "${SERVICE_DIRS[$num]}" "${SERVICE_NAMES[$num]}" "$mode" "$include_ui" "$kafka_mode"
        done
    fi

    echo -e "${GREEN}=== Done ===${NC}"
}

main "$@"
