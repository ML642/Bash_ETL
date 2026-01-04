#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_CMD="0 2 1 * * /usr/bin/bash '$SCRIPT_DIR/main.sh' >> '$SCRIPT_DIR/logs/cron.log' 2>&1"


chrontab(){
echo ""
echo ""
echo "ETL Cron Setup"
echo "=============="

if crontab -l 2>/dev/null | grep -qF "$SCRIPT_DIR/main.sh"; then
    echo "Cron job already exists:"
    crontab -l | grep -F "$SCRIPT_DIR/main.sh"
    exit 0
fi

read -p "Schedule ETL to run monthly at 2 AM? (y/N): " answer

if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
    mkdir -p "$SCRIPT_DIR/logs"
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "✓ Cron job scheduled"
    echo "Edit with: crontab -e"
else
    echo "Cron job not scheduled"
fi
}
