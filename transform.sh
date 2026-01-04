#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

transform_rank_countries() {
    local raw_dir="$1"
    local metric="$2"
    local year="$3"
    local mode="$4"    
    local n="$5"
    local output_file="$6"

    local previous_year=$((year-1))
    local json_file=""
    local prev_json_file=""

    # Find current year file
    json_file=$(ls "$raw_dir"/*${metric}*${year}.json 2>/dev/null | head -1)
    [[ ! -f "$json_file" ]] && json_file=$(ls "$raw_dir"/*${year}.json 2>/dev/null | head -1)
    [[ ! -f "$json_file" ]] && json_file=$(ls "$raw_dir"/*.json 2>/dev/null | grep "$year" | head -1)

    # Find previous year file
    prev_json_file=$(ls "$raw_dir"/*${metric}*${previous_year}.json 2>/dev/null | head -1)
    [[ ! -f "$prev_json_file" ]] && prev_json_file=$(ls "$raw_dir"/*${previous_year}.json 2>/dev/null | head -1)

    log_info "Processing: $json_file"
    [[ -f "$prev_json_file" ]] && log_info "Previous year data: $prev_json_file"

    local temp=$(mktemp)
    local temp_prev=$(mktemp)
    trap "rm -f $temp $temp_prev" RETURN

    # Extract current year data
    grep "\"date\":\"$year\"" "$json_file" | \
        grep -o '"country":{"id":"[^"]*","value":"[^"]*"},"countryiso3code":"[^"]*","date":"'"$year"'","value":[0-9.]*' | \
        sed 's/"country":{"id":"//; s/","value":"/|/; s/"},"countryiso3code":"/|/; s/","date":"'"$year"'","value":/|/' | \
        tr -d ',' > "$temp"

    local count=$(wc -l < "$temp")
    log_info "Found $count entries with data"
    [[ $count -eq 0 ]] && { log_error "No data extracted"; return 1; }

    # Extract previous year data if available
    if [[ -f "$prev_json_file" ]]; then
        grep "\"date\":\"$previous_year\"" "$prev_json_file" | \
            grep -o '"country":{"id":"[^"]*","value":"[^"]*"},"countryiso3code":"[^"]*","date":"'"$previous_year"'","value":[0-9.]*' | \
            sed 's/"country":{"id":"//; s/","value":"/|/; s/"},"countryiso3code":"/|/; s/","date":"'"$previous_year"'","value":/|/' | \
            tr -d ',' > "$temp_prev"
    fi

    # Filter out World Bank aggregates
    local exclude="WLD|HIC|OED|PST|IBT|IBD|LMY|MIC|EAS|UMC|LTE|NAC|ECS|EAP|TEA|EUU|EMU|EAR|LMC|LCN|TLA|LAC|TEC|MEA|TSA|SAS|SSF|SSA|ARB|CSS|CEB|PRE|PSS|TMN|TSS|LIC|LDC|IDX|IDB|IDA|INX"

    awk -F'|' -v ex="$exclude" '
        BEGIN { split(ex, arr, "|") }
        {
            code = $3
            value = $4
            exclude_it = 0

            if (value == "null" || value == "" || value == "0") exclude_it = 1

            for (i in arr) {
                if (code == arr[i]) {
                    exclude_it = 1
                    break
                }
            }

            if (length(code) != 3) exclude_it = 1

            if (!exclude_it) print $0
        }
    ' "$temp" > "${temp}_filtered"

    local filtered_count=$(wc -l < "${temp}_filtered")
    log_success "Filtered to $filtered_count actual countries"

    # Build previous year lookup map
    declare -A prev_values
    if [[ -f "$prev_json_file" ]]; then
        while IFS='|' read -r _ _ code value; do
            [[ -n "$code" && -n "$value" && "$value" != "null" ]] && prev_values[$code]="$value"
        done < "$temp_prev"
    fi

    # Sort data
    local sorted
    if [[ "$mode" == "top" ]]; then
        sorted=$(sort -t'|' -k4 -rn "${temp}_filtered" | head -n "$n")
    else
        sorted=$(sort -t'|' -k4 -n "${temp}_filtered" | head -n "$n")
    fi

    # Output with growth column
    {
        echo "========================================"
        echo "Ranking: ${mode^^} $n Countries - $year"
        echo "Metric: $metric"
        [[ -f "$prev_json_file" ]] && echo "YoY Growth: $previous_year → $year"
        echo "========================================"

        if [[ -f "$prev_json_file" ]]; then
            printf "%-5s %-20s %-8s %18s %12s\n" "RANK" "COUNTRY" "CODE" "VALUE" "GROWTH %"
            echo "----------------------------------------------------------------------"
        else
            printf "%-5s %-25s %-10s %20s\n" "RANK" "COUNTRY" "CODE" "VALUE"
            echo "----------------------------------------------------------------------"
        fi

        rank=1
        echo "$sorted" | while IFS='|' read -r _ name code value; do
            # Truncate long country names
            if [[ ${#name} -gt 20 ]]; then
                name="${name:0:17}..."
            fi

            formatted=$(printf "%',.2f" "$value" 2>/dev/null || echo "$value")

            # Calculate growth if previous year data exists
            if [[ -f "$prev_json_file" && -n "${prev_values[$code]}" ]]; then
                prev="${prev_values[$code]}"
                growth=$(awk -v curr="$value" -v prev="$prev" 'BEGIN {printf "%.2f", ((curr - prev) / prev) * 100}')

                if (( $(echo "$growth >= 0" | bc -l 2>/dev/null || echo 0) )); then
                    growth_str="+${growth}%"
                    color=${GREEN}
                else
                    color=${RED}
                    growth_str="${growth}%"
                fi

                printf "%-5s %-20s %-8s %18s" "#$rank" "$name" "$code" "$formatted"
		echo "$(printf '%12s' "$growth_str")"
            else
                if [[ -f "$prev_json_file" ]]; then

                    printf "%-5s %-25s %-10s %20s\n" "#$rank" "$name" "$code" "$formatted"
                fi
            fi

            ((rank++))
        done

	echo "======================================================================"
    } | tee "$output_file"
     log_success "Results saved to: $output_file"
}
