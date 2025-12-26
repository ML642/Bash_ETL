#!/bin/bash
fetch_data() {
    local country=$1
    local indicator=$2
    local name=$3
    local start_year=$4
    local end_year=$5
    local data_dir=$6

    if [ -z "$country" ] || [ -z "$indicator" ] || [ -z "$name" ] || [ -z "$data_dir" ]; then
        echo "fetch_data: Missing required arguments!"
        return 1
    fi

    local url="https://api.worldbank.org/v2/country/${country}/indicator/${indicator}?format=json&date=${start_year}:${end_year}&per_page=100"

    local output_file="${data_dir}/${name}_${country}.json"

    echo "Fetching ${name} data for ${country} (${start_year}-${end_year})..."
    
    if curl -s -f "$url" -o "$output_file"; then
        echo "  ✓ Saved to $output_file"
    else
        echo "  ✗ Failed to fetch data for $country"
    fi

    sleep 1
}