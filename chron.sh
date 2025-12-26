#!/bin/bash

echo "Running ETL..."

schedule_cron() {
    local cron_cmd="0 2 1 * * /usr/bin/bash $PWD/main.sh >> $PWD/logs/cron.log 2>&1"

    # Check if the cron job already exists
    crontab -l 2>/dev/null | grep -F "$PWD/main.sh" > /dev/null
    
    if [ $? -ne 0 ]; then
        # Add the cron job
        (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
        echo "Cron job added: Runs main.sh monthly at 2:00 AM"
    else
        echo "Cron job already exists."
    fi
}
