#!/bin/bash

source ./utils.sh

# Print a report in the terminal
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