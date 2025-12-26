#!/bin/bash
source ./utils.sh
source ./config.sh

transform_rank_countries() {
    local raw_dir="$1"
    local metric="$2"
    local year="$3"
    local mode="$4"  # top or least
    local n="$5"
    local output_file="$6"

    log_info "Transforming data for $metric in $year ($mode $n)..."

    local tmp_file
    tmp_file=$(mktemp)

    # Loop through all JSON files for this metric
    for file in "$raw_dir"/*_"$metric"*.json; do
        [[ -f "$file" ]] || continue

        # Extract blocks containing the given year
        awk -v year="$year" '
            /"country":/ { country=$0 }
            /"date":/ && $0 ~ year {
                getline; value=$0
                # Clean fields
                gsub(/.*"value":"?/, "", country)
                gsub(/".*/, "", country)
                gsub(/.*"value":/, "", value)
                gsub(/[,}].*/, "", value)
                print country "," value
            }
        ' "$file" >> "$tmp_file"
    done

    if [[ ! -s "$tmp_file" ]]; then
        log_error "No data found for $metric in $year."
        rm -f "$tmp_file"
        return 1
    fi

    # Sort results
    if [[ "$mode" == "top" ]]; then
        sort -t, -k2 -nr "$tmp_file" | head -n "$n" > "$output_file"
    else
        sort -t, -k2 -n "$tmp_file" | head -n "$n" > "$output_file"
    fi

    log_info "Saved ranked results to $output_file"
    rm -f "$tmp_file"
}
