transform_rank_countries() {
    local raw_dir="$1"
    local metric="$2"
    local year="$3"
    local mode="$4"    # "top" or "bottom"
    local n="$5"
    local output_file="$6"

    # Find the JSON file - try multiple patterns
    local json_file=""

    # Try pattern 1: with metric name
    json_file=$(ls "$raw_dir"/*${metric}*${year}.json 2>/dev/null | head -1)

    # Try pattern 2: just year (in case metric is in different format)
    if [[ ! -f "$json_file" ]]; then
        json_file=$(ls "$raw_dir"/*${year}.json 2>/dev/null | head -1)
    fi

    # Try pattern 3: any json file with the year
    if [[ ! -f "$json_file" ]]; then
        json_file=$(ls "$raw_dir"/*.json 2>/dev/null | grep "$year" | head -1)
    fi

    if [[ ! -f "$json_file" ]]; then
        log_error "No JSON file found in $raw_dir"
        log_error "Looking for patterns: *${metric}*${year}.json or *${year}.json"
        log_error "Files available:"
        ls -lh "$raw_dir" 2>/dev/null || echo "Directory empty or not found"
        return 1
    fi

    log_info "Processing: $json_file"

    local temp=$(mktemp)
    trap "rm -f $temp" RETURN

    # Extract all entries for the year in one pass
    # Pattern: find lines with the year, extract country code and value
    grep "\"date\":\"$year\"" "$json_file" | \
        grep -o '"country":{"id":"[^"]*","value":"[^"]*"},"countryiso3code":"[^"]*","date":"'"$year"'","value":[0-9.]*' | \
        sed 's/"country":{"id":"//; s/","value":"/|/; s/"},"countryiso3code":"/|/; s/","date":"'"$year"'","value":/|/' | \
        tr -d ',' > "$temp"

    local count=$(wc -l < "$temp")
    log_info "Found $count entries with data"

    [[ $count -eq 0 ]] && { log_error "No data extracted"; return 1; }

    # Filter out World Bank aggregates and regions (field 3 is the code)
    # Keep only entries where the code field has exactly 3 uppercase letters AND is not an aggregate
    local exclude="WLD|HIC|OED|PST|IBT|IBD|LMY|MIC|EAS|UMC|LTE|NAC|ECS|EAP|TEA|EUU|EMU|EAR|LMC|LCN|TLA|LAC|TEC|MEA|TSA|SAS|SSF|SSA|ARB|CSS|CEB|PRE|PSS|TMN|TSS|LIC|LDC|IDX|IDB|IDA|INX"

    # Filter by checking if field 3 (code) matches any exclude pattern
    awk -F'|' -v ex="$exclude" '
        BEGIN { split(ex, arr, "|") }
        {
            code = $3
            value = $4
            exclude_it = 0

            # Skip if value is null or empty
            if (value == "null" || value == "" || value == "0") exclude_it = 1

            # Check against exclude list
            for (i in arr) {
                if (code == arr[i]) {
                    exclude_it = 1
                    break
                }
            }

            # Also exclude if code is empty or not exactly 3 characters
            if (length(code) != 3) exclude_it = 1

            if (!exclude_it) print $0
        }
    ' "$temp" > "${temp}_filtered"

    local filtered_count=$(wc -l < "${temp}_filtered")
    log_info "Filtered to $filtered_count actual countries"

    # Sort: field 4 is the value
    local sorted
    if [[ "$mode" == "top" ]]; then
        sorted=$(sort -t'|' -k4 -rn "${temp}_filtered" | head -n "$n")
    else
        sorted=$(sort -t'|' -k4 -n "${temp}_filtered" | head -n "$n")
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
            # Truncate long country names
            if [[ ${#name} -gt 20 ]]; then
                name="${name:0:17}..."
            fi

            formatted=$(printf "%',.2f" "$value" 2>/dev/null || echo "$value")
            printf "%-5s %-25s %-10s %20s\n" "#$rank" "$name" "$code" "$formatted"
            ((rank++))
        done

        echo "========================================"
    } | tee "$output_file"

}