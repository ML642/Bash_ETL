# Bash_ETL
A minimal ETL (Extract, Transform, Load) tool written in Bash for educational purposes. This project demonstrates how to fetch data from APIs, clean and transform tabular data, and save it in CSV format. It also includes optional automation via cron and basic reporting features.
Bash_ETL - World Bank Data Pipeline

📊 Features
📥 Data Extraction: Fetches country data from World Bank API (GDP, population, inflation, CO₂ emissions, etc.)

🔧 Data Transformation: Cleans, filters, and ranks countries by specified metrics

📤 Data Loading: Generates formatted reports and CSV outputs

⏰ Automation: Optional cron scheduling for monthly updates

📈 Year-over-Year Analysis: Calculates growth percentages when previous year data is available

🛡️ Error Handling: Comprehensive validation and logging

📁 Project Structure
text
Bash_ETL/
├── main.sh              # Main entry point and orchestration
├── config.sh            # Configuration and metric mappings
├── fetch_data.sh        # API data extraction functions
├── transform.sh         # Data processing and ranking logic
├── load.sh              # Report generation and output
├── utils.sh             # Shared utilities and logging
├── chron.sh             # Cron job scheduling helper
├── run_example.sh       # Example usage script
├── data/                # Data storage directory
│   ├── raw/            # Raw JSON responses from API
│   └── output/         # Processed CSV results
├── logs/                # Application logs (auto-created)
└── README.md           # This file
🚀 Quick Start
Prerequisites
Bash 4.0+

curl for API requests

Basic Unix utilities: awk, sed, sort, bc

(Optional) jq for improved JSON parsing

Ubuntu/Debian:

bash
sudo apt-get update
sudo apt-get install curl awk sed bc
# Optional: sudo apt-get install jq
macOS:

bash
# Install Homebrew if not available
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install bash curl awk sed bc
# Optional: brew install jq
Basic Usage
bash
# Make scripts executable
chmod +x *.sh

# Run an example (Top 10 GDP countries in 2023)
./main.sh --year 2023 --metric gdp --topn 10

# Run with different metrics and modes
./main.sh --year 2022 --metric population --leastn 5
./main.sh --year 2021 --metric inflation --topn 15
📖 Available Metrics
Metric Key	Description	API Code
gdp	GDP (current US$)	NY.GDP.MKTP.CD
gdp_per_capita	GDP per capita (current US$)	NY.GDP.PCAP.CD
population	Population total	SP.POP.TOTL
unemployment	Unemployment rate (%)	SL.UEM.TOTL.ZS
inflation	Inflation (%)	FP.CPI.TOTL.ZG
co2	CO₂ emissions (metric tons per capita)	EN.ATM.CO2E.PC
⚙️ Command Line Options
Option	Required	Description	Example
--year	Yes	Target year (1960-current)	--year 2023
--metric	Yes	Metric to analyze (see above)	--metric gdp
--topn	One of these	Show top N countries	--topn 10
--leastn	One of these	Show bottom N countries	--leastn 5
📋 Examples
Example 1: Top 10 GDP Countries (2023)
bash
./main.sh --year 2023 --metric gdp --topn 10
Sample Output:

text
========================================
Ranking: TOP 10 Countries - 2023
Metric: gdp
YoY Growth: 2022 → 2023
========================================
RANK  COUNTRY              CODE         VALUE      GROWTH %
----------------------------------------------------------------------
#1    United States        USA      $25,462,700,000,000   +2.10%
#2    China                CHN      $17,700,899,000,000   +5.20%
#3    Germany              DEU       $4,072,192,000,000   -0.30%
...
========================================
Example 2: 5 Countries with Lowest Unemployment (2022)
bash
./main.sh --year 2022 --metric unemployment --leastn 5
Example 3: Year-over-Year CO₂ Comparison (2020-2021)
bash
./main.sh --year 2021 --metric co2 --topn 8

📊 Output Files
Results are saved in two locations:

Console: Formatted human-readable report

CSV File: data/output/{mode}n_{metric}_{year}.csv

Example: data/output/topn_gdp_2023.csv
