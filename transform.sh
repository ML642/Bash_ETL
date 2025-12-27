#!/bin/bash

# Fast function to rank countries from JSON data
transform_rank_countries() {
    local raw_dir="$1"
    local metric="$2"
    local year="$3"
    local mode="$4"    # "top" or "bottom"
    local n="$5"
    local output_file="$6"

    # Find the JSON file
    local json_file=$(ls "$raw_dir"/*${metric}*${year}.json 2>/dev/null | head -1)
    [[ ! -f "$json_file" ]] && { log_error "No JSON file found"; return 1; }

    log_info "Processing: $json_file"

    local temp=$(mktemp)
    trap "rm -f $temp" RETURN

    # Extract all entries for the year in one pass
    # Pattern: find lines with the year, extract country code and value
    grep "\"date\":\"$year\"" "$json_file" | \
        grep -o '"country":{"id":"[^"]*","value":"[^"]*"},"countryiso3code":"[^"]*","date":"'"$year"'","value":[0-9.]*' | \
        sed 's/"country":{"id":"//' | \
        sed 's/","value":"/|/' | \
        sed 's/"},"countryiso3code":"/|/' | \
        sed 's/","date":"'"$year"'","value":/|/' | \
        sed 's/$//' > "$temp"

    local count=$(wc -l < "$temp")
    log_info "Found $count countries with data"

    [[ $count -eq 0 ]] && { log_error "No data extracted"; return 1; }

    # Sort: field 4 is the value
    local sorted
    if [[ "$mode" == "top" ]]; then
        sorted=$(sort -t'|' -k4 -rn "$temp" | head -n "$n")
    else
        sorted=$(sort -t'|' -k4 -n "$temp" | head -n "$n")
    fi

    # Output
    {
        echo "========================================"
        echo "Ranking: ${mode^^} $n Countries - $year"
        echo "Metric: $metric"
        echo "========================================"
        printf "%-5s %-25s %-10s %20s\n" "RANK" "COUNTRY" "CODE" "VALUE"
        echo "----------------------------------------"

        rank=1
        echo "$sorted" | while IFS='|' read -r _ name code value; do
            formatted=$(printf "%',.2f" "$value" 2>/dev/null || echo "$value")
            printf "%-5s %-25s %-10s %20s\n" "#$rank" "$name" "$code" "$formatted"
            ((rank++))
        done

        echo "========================================"
    } | tee "$output_file"

}