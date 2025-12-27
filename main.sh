#!/bin/bash
set -euo pipefail

source ./utils.sh
source ./config.sh
source ./fetch_data.sh
source ./transform.sh
source ./load.sh
source ./transform.sh

DATA_DIR="./data"
RAW_DIR="$DATA_DIR/raw"
OUT_DIR="$DATA_DIR/output"

mkdir -p "$RAW_DIR" "$OUT_DIR"

YEAR=""
METRIC=""
MODE=""
N=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --year)
      YEAR="$2"
      shift 2
      ;;
    --metric)
      METRIC="$2"
      shift 2
      ;;
    --topn)
      MODE="top"
      N="$2"
      shift 2
      ;;
    --leastn)
      MODE="least"
      N="$2"
      shift 2
      ;;
    *)
      error "Unknown argument: $1"
      ;;
  esac
done


require_arg "--year" "$YEAR"
require_arg "--metric" "$METRIC"
require_arg "--topn|--leastn" "$MODE"
require_positive_int "$N"
validate_metric "$METRIC"

log_info "Bash ETL – World Bank Country Ranking"
log_info "Year: $YEAR | Metric: $METRIC | Mode: $MODE | N: $N"

echo ""
log_info "Step 1: Extracting raw data..."
fetch_all_countries "$METRIC" "$YEAR" "$RAW_DIR"
echo ""
log_info "Step 2: Transforming data..."
RESULT_FILE="$OUT_DIR/${MODE}n_${METRIC}_${YEAR}.csv"

transform_rank_countries \
  "$RAW_DIR" \
  "$METRIC" \
  "$YEAR" \
  "$MODE" \
  "$N" \
  "$RESULT_FILE"

echo ""
log_info "Step 3: Loading results..."
print_report "$RESULT_FILE" "$METRIC" "$YEAR" "$MODE" "$N"

echo ""
log_info "✓ ETL Complete!"
echo "Output: $RESULT_FILE"