#!/bin/bash

source ./utils.sh
source ./config.sh

fetch_all_countries() {
    local metric_name="$1"
    local metric="${METRIC_MAP[${metric_name}]}"
    local year="$2"
    local raw_dir="$3"

    mkdir -p "$raw_dir"

    local url="https://api.worldbank.org/v2/country/all/indicator/${metric}?format=json&per_page=20000"
    echo "$url"
    local outfile="${raw_dir}/countries_${metric_name}_${year}.json"

    echo "Fetching $metric for $year..."
    curl -s "$url" -o "$outfile"

    echo "Saved raw data to $outfile"
}
