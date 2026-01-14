#!/bin/bash

transform_rank_countries() {
    local raw_dir="$1"
    local metric="$2"
    local year="$3"
    local mode="$4"
    local n="$5"
    local group="$6"
    local output_file="$7"

    local previous_year=$((year-1))
    local json_file=""
    local prev_json_file=""

    # Find current year file
    json_file=$(ls "$raw_dir"/*${metric}*${year}.json 2>/dev/null | head -1)
    [[ ! -f "$json_file" ]] && json_file=$(ls "$raw_dir"/*${year}.json 2>/dev/null | head -1)

    # Find previous year file
    prev_json_file=$(ls "$raw_dir"/*${metric}*${previous_year}.json 2>/dev/null | head -1)
    [[ ! -f "$prev_json_file" ]] && prev_json_file=$(ls "$raw_dir"/*${previous_year}.json 2>/dev/null | head -1)

    log_info "Processing: $json_file"
    [[ -f "$prev_json_file" ]] && log_info "Previous year data: $prev_json_file"

    local temp
    local temp_prev
    temp=$(mktemp)
    temp_prev=$(mktemp)
    trap "rm -f $temp $temp_prev" RETURN

    # Extract current year data
    grep "\"date\":\"$year\"" "$json_file" | \
        grep -o '"country":{"id":"[^"]*","value":"[^"]*"},"countryiso3code":"[^"]*","date":"'"$year"'","value":[0-9.]*' | \
        sed 's/"country":{"id":"//; s/","value":"/|/; s/"},"countryiso3code":"/|/; s/","date":"'"$year"'","value":/|/' | \
        tr -d ',' > "$temp"

    local count
    count=$(wc -l < "$temp")
    log_info "Found $count entries with data"
    [[ $count -eq 0 ]] && { log_error "No data extracted"; return 1; }

    # Extract previous year data
    if [[ -f "$prev_json_file" ]]; then
        grep "\"date\":\"$previous_year\"" "$prev_json_file" | \
            grep -o '"country":{"id":"[^"]*","value":"[^"]*"},"countryiso3code":"[^"]*","date":"'"$previous_year"'","value":[0-9.]*' | \
            sed 's/"country":{"id":"//; s/","value":"/|/; s/"},"countryiso3code":"/|/; s/","date":"'"$previous_year"'","value":/|/' | \
            tr -d ',' > "$temp_prev"
    fi

    # Filter out World Bank aggregates
    local exclude="WLD|HIC|OED|PST|IBT|IBD|LMY|MIC|EAS|UMC|LTE|NAC|ECS|EAP|TEA|EUU|EMU|EAR|LMC|LCN|TLA|LAC|TEC|MEA|TSA|SAS|SSF|SSA|ARB|CSS|CEB|PRE|PSS|TMN|TSS|LIC|LDC|IDX|IDB|IDA|INX"
    # World Bank groups
    local AGGREGATES="WLD|EUU|EMU|EAP|EAS|ECS|LCN|LAC|MNA|MEA|NAC|SAS|SSA|ARB|CSS|CEB|TMN|TSS|PSS|PRE|INX"
    local RICH="HIC"
    local POOR="LIC"

    awk -F'|' -v ex="$exclude" -v grp="$group" \
        -v AGG="$AGGREGATES" -v RICH="$RICH" -v POOR="$POOR" '
    BEGIN {
        split(ex, excl, "|")
        split(AGG, aggs, "|")
    }
    {
        code = $3
        value = $4
        drop = 0
        is_agg = 0

        if (value == "null" || value == "" || value == "0") drop = 1
        if (grp == "countries") {
            for (i in excl)
                if (code == excl[i]) drop = 1
        }

        for (i in aggs) if (code == aggs[i]) is_agg = 1

        if (length(code) != 3) drop = 1

        if (grp == "countries" && is_agg) drop = 1
        if (grp == "aggregates" && !is_agg) drop = 1
        if (grp == "rich" && code != RICH) drop = 1
        if (grp == "poor" && code != POOR) drop = 1

        if (!drop) print $0
    }
    ' "$temp" > "${temp}_filtered"

    local filtered_count
    filtered_count=$(wc -l < "${temp}_filtered")
    log_success "Filtered to $filtered_count actual countries"

    # Build previous year lookup
    declare -A prev_values
    if [[ -f "$temp_prev" ]]; then
        while IFS='|' read -r _ _ code value; do
            [[ -n "$code" && -n "$value" && "$value" != "null" ]] && prev_values[$code]="$value"
        done < "$temp_prev"
    fi



   # Sort data
   local sorted

   case "$mode" in
       top)
           # Sort by value DESC
           sorted=$(sort -t'|' -k4 -rn "${temp}_filtered" | head -n "$n")
           ;;
       least)
           # Sort by value ASC
           sorted=$(sort -t'|' -k4 -n "${temp}_filtered" | head -n "$n")
           ;;
       top-growth)
           # Sort by YoY growth DESC
           sorted=$(
               awk -F'|' '
               BEGIN { OFS="|" }
               {
                   print $0
               }' "${temp}_filtered" \
               | while IFS='|' read -r a b code value; do
                   growth=""
                   if [[ -n "${prev_values[$code]:-}" ]]; then
                       prev="${prev_values[$code]}"
                       growth=$(awk -v c="$value" -v p="$prev" 'BEGIN { printf "%.6f", (c-p)/p }')
                   else
                       growth="-999999"
                   fi
                   echo "$a|$b|$code|$value|$growth"
               done \
               | sort -t'|' -k5 -rn \
               | cut -d'|' -f1-4 \
               | head -n "$n"
           )
           ;;
       least-growth)
           # Sort by YoY growth ASC
           sorted=$(
               awk -F'|' '
               BEGIN { OFS="|" }
               {
                   print $0
               }' "${temp}_filtered" \
               | while IFS='|' read -r a b code value; do
                   growth=""
                   if [[ -n "${prev_values[$code]:-}" ]]; then
                       prev="${prev_values[$code]}"
                       growth=$(awk -v c="$value" -v p="$prev" 'BEGIN { printf "%.6f", (c-p)/p }')
                   else
                       growth="999999"
                   fi
                   echo "$a|$b|$code|$value|$growth"
               done \
               | sort -t'|' -k5 -n \
               | cut -d'|' -f1-4 \
               | head -n "$n"
           )
           ;;
       *)
           log_error "Unknown mode: $mode"
           return 1
           ;;
   esac


    # Write CSV
    echo "rank,country,code,value,growth_percent" > "$output_file"

    local rank=1
    echo "$sorted" | while IFS='|' read -r _ name code value; do
        local growth=""

        if [[ -n "${prev_values[$code]:-}" ]]; then
            prev="${prev_values[$code]}"
            growth=$(awk -v curr="$value" -v prev="$prev" 'BEGIN {printf "%.2f", ((curr - prev) / prev) * 100}')
        fi

        echo "$rank,$name,$code,$value,$growth" >> "$output_file"
        ((rank++))
    done

    log_success "Results saved to: $output_file"
}

