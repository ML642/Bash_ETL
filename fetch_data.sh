#!/bin/bash

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
fetch_all_countries() {
    local metric="$1"
    local year="$2"
    local raw_dir="$3"

    mkdir -p "$raw_dir"

    local url="https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&per_page=20000"
    local outfile="${raw_dir}/countries_${metric}_${year}.json"

    echo "Fetching $metric for $year..."
    curl -s "$url" -o "$outfile"

    echo "Saved raw data to $outfile"
}