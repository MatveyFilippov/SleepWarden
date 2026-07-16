#!/bin/bash
# Before execute: chmod +x sleep_warden.sh
# For shadow work: nohup ./sleep_warden.sh > /dev/null 2>&1
# For find PID: ps aux | grep sleep_warden

API_URL="http://localhost:1216/i_am_alive"
MIN_INTERVAL=45*60  # 45 минут в секундах
MAX_INTERVAL=75*60  # 75 минут в секундах
LOG_DIR="$HOME/Library/Logs/SleepWarden"
LOG_FILE="$LOG_DIR/SleepWardenFrontend.log"

mkdir -p "$LOG_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alive_request() {
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL")

    log_message "POST /i_am_alive -> response status code: $response"
}

show_notification() {
    notification_id="alive_check_$(date +%s)"
    log_message "Showing notification (ID: $notification_id)"

    osascript <<EOF
        display dialog "Confirm your activity" \
            buttons {"I'm alive!"} \
            default button "I'm alive!" \
            with icon note \
            with title "SleepWarden" \
            giving up after 300

        if button returned of result is "I'm alive!" then
            do shell script "echo 'confirmed'"
        end if
EOF

    if [ $? -eq 0 ]; then
        log_message "Activity confirmed"
        send_alive_request
    else
        log_message "TIMEOUT: prisoner don't answer"
    fi
}


log_message "SleepWarden frontend alive checker started"

while true; do
    show_notification
    
    random_interval=$((RANDOM % (MAX_INTERVAL - MIN_INTERVAL + 1) + MIN_INTERVAL))
    next_check=$(date -v+${random_interval}S '+%H:%M:%S')

    log_message "Next check at $next_check ($((random_interval/60)) min)"
    sleep $random_interval
done
