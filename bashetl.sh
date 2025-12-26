#!/bin/bash

START_YEAR="2015"
END_YEAR="2024"

mkdir -p data

echo "========================================="
echo "World Bank Data Fetcher"
echo "========================================="
echo ""


echo "Step 1: Finding top 10 countries by GDP..."
echo ""

curl -s "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&date=2023&per_page=300" > data/all_gdp_temp.json

if command -v jq &> /dev/null; then
    TOP_GDP_COUNTRIES=$(jq -r '.[1] | sort_by(-.value) | limit(10; .[]) | .countryiso3code' data/all_gdp_temp.json | tr '\n' ',')
    
    echo "Top 10 countries by GDP:"
    jq -r '.[1] | sort_by(-.value) | limit(10; .[]) | "  \(.country.value): $\(.value / 1000000000 | floor) billion"' data/all_gdp_temp.json
else
    echo "  (jq not installed, using default top 10)"
    TOP_GDP_COUNTRIES="US,CN,JP,DE,IN,GB,FR,IT,BR,CA"
    echo "  Using: US, China, Japan, Germany, India, UK, France, Italy, Brazil, Canada"
fi

echo ""
sleep 2

echo "Step 2: Finding bottom 10 countries by unemployment rate..."
echo ""

curl -s "https://api.worldbank.org/v2/country/all/indicator/SL.UEM.TOTL.ZS?format=json&date=2023&per_page=300" > data/all_unemployment_temp.json

if command -v jq &> /dev/null; then
    LOWEST_UNEMP_COUNTRIES=$(jq -r '.[1] | sort_by(.value) | limit(10; .[]) | select(.value != null) | .countryiso3code' data/all_unemployment_temp.json | tr '\n' ',')
    
    echo "Bottom 10 countries by unemployment rate:"
    jq -r '.[1] | sort_by(.value) | limit(10; .[]) | select(.value != null) | "  \(.country.value): \(.value)%"' data/all_unemployment_temp.json
else
    echo "  (jq not installed, using default)"
    LOWEST_UNEMP_COUNTRIES="TH,KH,QA,BN,LA,MH,MM,NE,RW,TZ"
    echo "  Using countries with historically low unemployment"
fi

echo ""
sleep 2

echo "========================================="
echo "Step 3: Fetching detailed historical data..."
echo "========================================="
echo ""

fetch_data() {
    local country=$1
    local indicator=$2
    local name=$3
    
    echo "Fetching $name for $country..."
    
    url="https://api.worldbank.org/v2/country/${country}/indicator/${indicator}"
    url="${url}?format=json&date=${START_YEAR}:${END_YEAR}&per_page=100"
    
    curl -s "$url" > "data/${name}_${country}.json"
    echo "  ✓ Saved: data/${name}_${country}.json"
    
    sleep 1
}

echo ""
echo "--- Fetching GDP data (Top 10 countries) ---"
for country in ${TOP_GDP_COUNTRIES//,/ }; do
    [ -n "$country" ] && fetch_data "$country" "NY.GDP.MKTP.CD" "gdp"
done

echo ""
echo "--- Fetching Unemployment data (Lowest 10 countries) ---"
for country in ${LOWEST_UNEMP_COUNTRIES//,/ }; do
    [ -n "$country" ] && fetch_data "$country" "SL.UEM.TOTL.ZS" "unemployment"
done

rm -f data/all_gdp_temp.json data/all_unemployment_temp.json

echo ""
echo "========================================="
echo "✓ Complete!"
echo "========================================="
echo ""
echo "Data saved in ./data/ folder:"
ls -lh data/ | grep -v "^total" | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Files: $(ls data/*.json 2>/dev/null | wc -l) JSON files created"