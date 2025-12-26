#!/bin/bash
source ./config.sh
require_arg() {
    local name="$1"
    local value="$2"
    if [[ -z "$value" ]]; then
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
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
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
    error "Value must be a positive integer: $value"
  fi
}


require_year() {
  local year="$1"

  if ! [[ "$year" =~ ^[0-9]{4}$ ]]; then
    error "Invalid year: $year"
  fi
}



validate_metric() {
  local metric="$1"

  if [[ -z "${METRIC_MAP[$metric]:-}" ]]; then
    error "Unknown metric: $metric (available: ${!METRIC_MAP[*]})"
  fi
}
error() {
    log_error "$1"
    exit 1
}