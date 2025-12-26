#!/bin/bash

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