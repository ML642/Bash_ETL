BASE_URL="https://api.worldbank.org/v2"
FORMAT="json"


declare -A METRIC_MAP=(
  [gdp]="NY.GDP.MKTP.CD"
  [gdp_per_capita]="NY.GDP.PCAP.CD"
  [population]="SP.POP.TOTL"
  [unemployment]="SL.UEM.TOTL.ZS"
  [inflation]="FP.CPI.TOTL.ZG"
  [co2]="EN.ATM.CO2E.PC"
)


declare -A METRIC_LABELS=(
  [gdp]="GDP (current US$)"
  [gdp_per_capita]="GDP per capita (current US$)"
  [population]="Population"
  [unemployment]="Unemployment rate (%)"
  [inflation]="Inflation (%)"
  [co2]="CO₂ emissions (metric tons per capita)"
)


DEFAULT_TOPN=10
DEFAULT_START_YEAR=2015
DEFAULT_END_YEAR=$(date +%Y)