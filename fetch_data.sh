#!/bin/bash

if [[ -n "$FETCH_DATA_INCLUDED" ]]; then
    return
fi
FETCH_DATA_INCLUDED=1

source ./utils.sh
source ./config.sh

fetch_data() {
    local country="$1"
    local metric_code="$2"
    local metric_name="$3"
    local start_year="$4"
    local end_year="$5"
    local output_dir="$6"

    mkdir -p "$output_dir"

    local url="http://api.worldbank.org/v2/country/${country}/indicator/${metric_code}?date=${start_year}:${end_year}&format=json"

    log_info "Fetching $metric_name data for $country from $start_year to $end_year..."

    local response_file="${output_dir}/${country}_${metric_name}.json"

    # Fetch data using curl
    if curl -s -f "$url" -o "$response_file"; then
        log_info "Saved $metric_name data for $country to $response_file"
    else
        log_error "Failed to fetch $metric_name data for $country"
    fi
}