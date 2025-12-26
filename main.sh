#!/bin/bash

source ./utils.sh
source ./fetch_data

START_YEAR=2015
END_YEAR=2024
DATA_DIR="./data"

mkdir -p "$DATA_DIR"

echo "========================================="
echo "World Bank Data Fetcher (Bash ETL)"
echo "========================================="


echo ""
echo "Step 1: Fetching top 10 countries by GDP..."

TOP_GDP_COUNTRIES=$(get_top_gdp_countries 2023 10)

echo "Top 10 GDP countries: $TOP_GDP_COUNTRIES"
sleep 1


echo ""
echo "Step 2: Fetching bottom 10 countries by unemployment rate..."

LOWEST_UNEMP_COUNTRIES=$(get_lowest_unemployment_countries 2023 10)

echo "Bottom 10 lowest unemployment countries: $LOWEST_UNEMP_COUNTRIES"
sleep 1



echo ""
echo "Step 3: Fetching historical data for each country..."

for country in ${TOP_GDP_COUNTRIES//,/ }; do
    fetch_data "$country" "NY.GDP.MKTP.CD" "gdp" "$START_YEAR" "$END_YEAR" "$DATA_DIR"
done

for country in ${LOWEST_UNEMP_COUNTRIES//,/ }; do
    fetch_data "$country" "SL.UEM.TOTL.ZS" "unemployment" "$START_YEAR" "$END_YEAR" "$DATA_DIR"
done

echo ""
echo "========================================="
echo "✓ ETL Complete! JSON files saved in $DATA_DIR/"
echo "========================================="