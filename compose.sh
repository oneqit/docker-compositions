#!/bin/bash

# Docker Compositions - Interactive Start/Stop Script
# Toggle services: running -> stop, stopped -> start
# Services are auto-discovered from service.json files

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

# Check jq dependency
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo -e "Install with: ${GREEN}brew install jq${NC} (macOS)"
        echo -e "            ${GREEN}apt-get install jq${NC} (Ubuntu/Debian)"
        exit 1
    fi
}

# Get value from service.json using jq
get_service_meta() {
    local service_dir=$1
    local key=$2
    local json_file="$SCRIPT_DIR/$service_dir/service.json"
    if [[ -f "$json_file" ]]; then
        jq -r "$key // empty" "$json_file"
    fi
}

# Get value from categories.json
get_category_meta() {
    local key=$1
    jq -r "$key // empty" "$SCRIPT_DIR/categories.json"
}

# Discover all services with service.json
discover_services() {
    local services=()
    for dir in "$SCRIPT_DIR"/*/; do
        if [[ -f "$dir/service.json" ]]; then
            services+=("$(basename "$dir")")
        fi
    done
    echo "${services[@]}"
}

# Build service arrays from service.json files
# Arrays are indexed by display number (1-based)
declare -a SERVICE_DIRS
declare -a SERVICE_NAMES
declare -a SERVICE_CONTAINERS
declare -a SERVICE_UI_CONTAINERS
declare -a SERVICE_UI_INTEGRATED
declare -a SERVICE_CATEGORIES
declare -a SERVICE_MODE
declare -a SERVICE_UI
declare -a CATEGORY_IDS
declare -a CATEGORY_NAMES
declare -a CATEGORY_ORDER

load_categories() {
    local count
    count=$(get_category_meta '.categories | length')

    for ((i=0; i<count; i++)); do
        local id name order
        id=$(get_category_meta ".categories[$i].id")
        name=$(get_category_meta ".categories[$i].name")
        order=$(get_category_meta ".categories[$i].order")
        CATEGORY_IDS[$order]="$id"
        CATEGORY_NAMES[$order]="$name"
    done
}

load_services() {
    local services
    services=($(discover_services))

    # Load categories first
    load_categories

    # Build indexed arrays in category order (bash 3.2 compatible - no associative arrays)
    local idx=1
    local max_order=6
    for ((order=1; order<=max_order; order++)); do
        local cat_id="${CATEGORY_IDS[$order]}"
        if [[ -n "$cat_id" ]]; then
            # Find all services matching this category
            for service_dir in "${services[@]}"; do
                local category
                category=$(get_service_meta "$service_dir" '.category')
                if [[ "$category" == "$cat_id" ]]; then
                    SERVICE_DIRS[$idx]="$service_dir"
                    SERVICE_NAMES[$idx]=$(get_service_meta "$service_dir" '.name')
                    SERVICE_CONTAINERS[$idx]=$(get_service_meta "$service_dir" '.container')
                    SERVICE_UI_CONTAINERS[$idx]=$(get_service_meta "$service_dir" '.ui_container')
                    SERVICE_UI_INTEGRATED[$idx]=$(get_service_meta "$service_dir" '.ui_integrated')
                    SERVICE_CATEGORIES[$idx]="$cat_id"
                    SERVICE_MODE[$idx]=""
                    SERVICE_UI[$idx]="0"
                    ((idx++))
                fi
            done
        fi
    done
}

# Get max service index
get_max_service_idx() {
    echo "${#SERVICE_DIRS[@]}"
}

print_header() {
    echo -e "\n${BLUE}=== Docker Compositions ===${NC}\n"
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Exiting...${NC}"; exit 0' INT

detect_running_services() {
    local running_containers
    running_containers=$(docker ps --format '{{.Names}}' 2>/dev/null)
    local max_idx
    max_idx=$(get_max_service_idx)

    for ((i=1; i<=max_idx; i++)); do
        local container="${SERVICE_CONTAINERS[$i]}"
        local ui_container="${SERVICE_UI_CONTAINERS[$i]}"
        local ui_integrated="${SERVICE_UI_INTEGRATED[$i]}"
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
            # UI integrated services: UI container is the main container
            if [[ "$ui_integrated" == "true" ]]; then
                SERVICE_MODE[$i]="dev"
            fi
        fi

        # UI integrated secure+ui: oneqit_{container}_secure_ui
        if [[ "$ui_integrated" == "true" ]]; then
            if echo "$running_containers" | grep -q "^oneqit_${container}_secure_ui$"; then
                SERVICE_MODE[$i]="secure"
                SERVICE_UI[$i]="1"
            fi
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

    local current_category=""
    local max_idx
    max_idx=$(get_max_service_idx)

    for ((i=1; i<=max_idx; i++)); do
        local cat_id="${SERVICE_CATEGORIES[$i]}"

        # Print category header when category changes
        if [[ "$cat_id" != "$current_category" ]]; then
            # Find category name from CATEGORY_IDS
            local cat_name=""
            for ((j=1; j<=6; j++)); do
                if [[ "${CATEGORY_IDS[$j]}" == "$cat_id" ]]; then
                    cat_name="${CATEGORY_NAMES[$j]}"
                    break
                fi
            done
            echo -e "  ${BLUE}[$cat_name]${NC}"
            current_category="$cat_id"
        fi

        local status_label
        status_label=$(get_status_label $i)
        if is_running $i; then
            echo -e "    $i) ${GREEN}●${NC} ${SERVICE_NAMES[$i]}${status_label}"
        else
            echo -e "    $i) ${GRAY}○${NC} ${SERVICE_NAMES[$i]}"
        fi
    done
    echo -e "\n${GRAY}(Ctrl+C to exit)${NC}"
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

    local name
    name=$(get_service_meta "$service_dir" '.name')

    echo -e "${CYAN}Access:${NC}"

    # Get main access info
    local main_addr main_label
    main_addr=$(get_service_meta "$service_dir" ".access_info.$mode.main")
    main_label=$(get_service_meta "$service_dir" ".access_info.$mode.main_label")

    if [[ -z "$main_label" ]]; then
        main_label="$name"
    fi

    # Pad the label for alignment
    printf "  %-14s ${GREEN}%s${NC}\n" "$main_label:" "$main_addr"

    # Print credentials for secure mode or dev mode (if any)
    local creds_count
    creds_count=$(get_service_meta "$service_dir" ".access_info.$mode.credentials | length")
    if [[ -n "$creds_count" && "$creds_count" != "null" && "$creds_count" -gt 0 ]]; then
        for ((j=0; j<creds_count; j++)); do
            local cred
            cred=$(get_service_meta "$service_dir" ".access_info.$mode.credentials[$j]")
            echo -e "  ${YELLOW}$cred${NC}"
        done
    fi

    # Print UI info
    if [[ "$include_ui" == "yes" ]]; then
        local ui_url ui_name ui_creds ui_note
        ui_url=$(get_service_meta "$service_dir" '.access_info.ui.url')
        ui_name=$(get_service_meta "$service_dir" '.access_info.ui.name')
        ui_creds=$(get_service_meta "$service_dir" '.access_info.ui.credentials')
        ui_note=$(get_service_meta "$service_dir" '.access_info.ui.note')

        if [[ -n "$ui_url" ]]; then
            printf "  %-14s ${GREEN}%s${NC}\n" "$ui_name:" "$ui_url"
        fi
        if [[ -n "$ui_creds" ]]; then
            echo -e "  ${YELLOW}$ui_creds${NC}"
        fi
        if [[ -n "$ui_note" ]]; then
            echo -e "  ${GRAY}Note: $ui_note${NC}"
        fi
    fi

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

# Check if service has Kafka-like modes
has_modes() {
    local service_dir=$1
    local modes
    modes=$(get_service_meta "$service_dir" '.modes | length')
    [[ -n "$modes" && "$modes" != "null" && "$modes" -gt 0 ]]
}

# Get compose file based on mode and UI option
get_compose_file() {
    local service_dir=$1
    local mode=$2
    local include_ui=$3
    local extra_mode=$4

    local prefix=""
    # Check for compose_prefix (like Kafka's zookeeper mode)
    if [[ -n "$extra_mode" ]]; then
        prefix=$(get_service_meta "$service_dir" ".compose_prefix.$extra_mode")
    fi

    local suffix=""
    if [[ "$mode" == "secure" && "$include_ui" == "yes" ]]; then
        suffix="secure.ui"
    elif [[ "$mode" == "secure" ]]; then
        suffix="secure"
    elif [[ "$include_ui" == "yes" ]]; then
        suffix="ui"
    fi

    if [[ -n "$suffix" ]]; then
        echo "docker-compose.${prefix}${suffix}.yml"
    else
        if [[ -n "$prefix" ]]; then
            echo "docker-compose.${prefix%%.}.yml"
        else
            echo "docker-compose.yml"
        fi
    fi
}

start_service() {
    local service_dir=$1
    local service_name=$2
    local mode=$3
    local include_ui=$4
    local extra_mode=$5

    check_env_file "$service_dir" "$mode" "$include_ui"

    local compose_file
    compose_file=$(get_compose_file "$service_dir" "$mode" "$include_ui" "$extra_mode")

    echo -e "${GREEN}Starting $service_name...${NC}"
    echo -e "  Mode: $mode, UI: $include_ui"
    if [[ -n "$extra_mode" ]]; then
        echo -e "  Extra: $extra_mode"
    fi
    echo -e "  File: $compose_file"

    cd "$SCRIPT_DIR/$service_dir"
    docker-compose -f "$compose_file" up -d
    cd "$SCRIPT_DIR"

    echo ""
    print_access_info "$service_dir" "$mode" "$include_ui"
}

stop_service() {
    local service_dir=$1
    local service_name=$2
    local idx=$3

    local mode="${SERVICE_MODE[$idx]}"
    local ui="${SERVICE_UI[$idx]}"
    local include_ui="no"
    [[ "$ui" == "1" ]] && include_ui="yes"

    # Detect extra mode (like kafka's zookeeper) from running containers
    local extra_mode=""
    if has_modes "$service_dir"; then
        local running
        running=$(docker ps --format '{{.Names}}' 2>/dev/null)
        # Check for zookeeper mode specifically (Kafka)
        if [[ "$service_dir" == "kafka" ]] && echo "$running" | grep -q "oneqit_zookeeper"; then
            extra_mode="zookeeper"
        fi
    fi

    local compose_file
    compose_file=$(get_compose_file "$service_dir" "$mode" "$include_ui" "$extra_mode")

    echo -e "${RED}Stopping $service_name...${NC}"
    echo -e "  File: $compose_file"

    cd "$SCRIPT_DIR/$service_dir"
    docker-compose -f "$compose_file" down
    cd "$SCRIPT_DIR"

    echo ""
}

main() {
    check_jq
    load_services

    local max_idx
    max_idx=$(get_max_service_idx)

    while true; do
        print_header

        detect_running_services
        print_services
        read -p "> " service_input

        if [[ -z "$service_input" ]]; then
            echo -e "${RED}No service selected${NC}"
            continue
        fi

        to_start=()
        to_stop=()

        for num in $service_input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le "$max_idx" ]] && [[ -n "${SERVICE_DIRS[$num]}" ]]; then
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
                stop_service "${SERVICE_DIRS[$num]}" "${SERVICE_NAMES[$num]}" "$num"
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
                    continue
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
                    continue
                    ;;
            esac

            # Check if any service has modes (like Kafka)
            extra_mode=""
            for num in "${to_start[@]}"; do
                if has_modes "${SERVICE_DIRS[$num]}"; then
                    # Currently only Kafka has modes, show Kafka-specific options
                    if [[ "${SERVICE_DIRS[$num]}" == "kafka" ]]; then
                        print_kafka_options
                        read -p "> [1]: " mode_choice
                        mode_choice=${mode_choice:-1}

                        case $mode_choice in
                            1) extra_mode="" ;;
                            2) extra_mode="zookeeper" ;;
                            *)
                                echo -e "${RED}Invalid mode${NC}"
                                continue 2
                                ;;
                        esac
                    fi
                    break
                fi
            done

            echo ""
            echo -e "${BLUE}=== Starting ===${NC}"
            echo ""

            for num in "${to_start[@]}"; do
                start_service "${SERVICE_DIRS[$num]}" "${SERVICE_NAMES[$num]}" "$mode" "$include_ui" "$extra_mode"
            done
        fi

        echo -e "${GREEN}=== Done ===${NC}"
    done
}

main "$@"
