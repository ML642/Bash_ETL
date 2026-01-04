#!/bin/bash
source ./config.sh

usage() {
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local NC='\033[0m'
    echo -e "${BOLD}${CYAN}Usage:${NC}"
    echo -e "  ${GREEN}./main.sh${NC} --year YEAR --metric METRIC (${YELLOW}--topn N${NC} | ${YELLOW}--leastn N${NC})"
    echo ""

    echo -e "${BOLD}${CYAN}Required arguments:${NC}"
    echo -e "  ${YELLOW}--year YEAR${NC}          Year of analysis (e.g. 2022)"
    echo -e "  ${YELLOW}--metric METRIC${NC}      Metric to analyze"
    echo ""

    echo -e "${BOLD}${CYAN}Ranking options (choose exactly one):${NC}"
    echo -e "  ${YELLOW}--topn N${NC}             Show top N countries"
    echo -e "  ${YELLOW}--leastn N${NC}           Show bottom N countries"
    echo ""

    echo -e "${BOLD}${CYAN}Available metrics:${NC}"
    echo -e "  ${GREEN}gdp${NC}                 Gross Domestic Product"
    echo -e "  ${GREEN}unemployment${NC}        Unemployment rate"
    echo -e "  ${GREEN}population${NC}          Population size"
    echo ""

    echo -e "${BOLD}${CYAN}Examples:${NC}"
    echo -e "  ${GREEN}./main.sh --year 2022 --metric gdp --topn 10${NC}"
    echo -e "  ${GREEN}./main.sh --year 2021 --metric unemployment --leastn 5${NC}"
}
require_arg() {
    local name="$1"
    local value="$2"
    if [[ -z "$value" ]]; then
        usage
        error "Argument $name is required"
    fi
}
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install jq to proceed."
        exit 1
    fi
}

command_exists() {
  command -v "$1" &> /dev/null
}


log_info() {
  local YELLOW='\033[0;33m'
  local NC="\033[0m"
  echo -e "${YELLOW}[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}"
}

log_error() {
    local RED='\033[0;31m'
    local NC='\033[0m'
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*${NC}" >&2
}
log_success(){
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    echo -e "${GREEN}[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') -  $*${NC} "
}


check_internet() {
  if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_error "No internet connection."
    exit 1
  fi
}


require_positive_int() {
  local value="$1"

  if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
    usage
    error "Value must be a positive integer: $value"
  fi
}


require_year() {
  local year="$1"

  if ! [[ "$year" =~ ^[0-9]{4}$ ]]; then
    usage
    error "Invalid year: $year"
  fi
}

print_report() {
    local result_file="$1"
    local metric="$2"
    local year="$3"
    local mode="$4"
    local n="$5"

    if [[ ! -f "$result_file" ]]; then
        log_error "Result file not found: $result_file"
        return 1
    fi

    echo ""
    log_info "Top $n countries by $metric in $year ($mode):"
    echo "-------------------------------------------"
    column -t -s, "$result_file"
    echo "-------------------------------------------"
}

validate_metric() {
  local metric="$1"

  if [[ -z "${METRIC_MAP[$metric]:-}" ]]; then
    error "Unknown metric: $metric (available: ${!METRIC_MAP[*]})"
  fi
}
error() {
    usage
    log_error "$1"
    exit 1
}
