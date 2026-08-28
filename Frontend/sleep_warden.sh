#!/bin/bash

set -u  # exit on undefined variable

# Default values
API_HOST="localhost"
API_PORT="1216"
API_PROTOCOL="http"
API_PATH="/i_am_alive"
MIN_INTERVAL=$((45*60))  # 45 minutes in seconds
MAX_INTERVAL=$((75*60))  # 75 minutes in seconds
TIMEOUT_SECONDS=60
LOG_DIR="$HOME/Library/Logs/SleepWarden"
LOG_FILE="$LOG_DIR/SleepWardenFrontend.log"
CONFIG_FILE=""

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --host HOST         API host (default: localhost)
    -p, --port PORT         API port (default: 1216)
    -s, --protocol PROTO    Protocol: http or https (default: http)
    -a, --path PATH         API path (default: /i_am_alive)
    -c, --config FILE       Config file path
    -t, --timeout SECONDS   Notification timeout in seconds (default: 60)
    --min-interval SECONDS  Minimum interval between checks (default: 2700)
    --max-interval SECONDS  Maximum interval between checks (default: 4500)
    --help                  Show this help message

Config file format (key=value):
    API_HOST=example.com
    API_PORT=8080
    API_PROTOCOL=https
    API_PATH=/custom/path
    MIN_INTERVAL=3600
    MAX_INTERVAL=7200
    TIMEOUT_SECONDS=10
EOF
}

# Parse config file if exists
parse_config_file() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file not found: $config_file" >&2
        exit 1
    fi
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        case "$key" in
            API_HOST) API_HOST="$value" ;;
            API_PORT) API_PORT="$value" ;;
            API_PROTOCOL) API_PROTOCOL="$value" ;;
            API_PATH) API_PATH="$value" ;;
            MIN_INTERVAL) MIN_INTERVAL="$value" ;;
            MAX_INTERVAL) MAX_INTERVAL="$value" ;;
            TIMEOUT_SECONDS) TIMEOUT_SECONDS="$value" ;;
            LOG_DIR) LOG_DIR="$value" ;;
            LOG_FILE) LOG_FILE="$value" ;;
        esac
    done < "$config_file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            API_HOST="$2"
            shift 2
            ;;
        -p|--port)
            API_PORT="$2"
            shift 2
            ;;
        -s|--protocol)
            API_PROTOCOL="$2"
            shift 2
            ;;
        -a|--path)
            API_PATH="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            parse_config_file "$CONFIG_FILE"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT_SECONDS="$2"
            shift 2
            ;;
        --min-interval)
            MIN_INTERVAL="$2"
            shift 2
            ;;
        --max-interval)
            MAX_INTERVAL="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Build API URL
API_URL="${API_PROTOCOL}://${API_HOST}:${API_PORT}${API_PATH}"

# Validate intervals
if [ "$MIN_INTERVAL" -gt "$MAX_INTERVAL" ]; then
    echo "Error: MIN_INTERVAL cannot be greater than MAX_INTERVAL" >&2
    exit 1
fi

mkdir -p "$LOG_DIR"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alive_request() {
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL" \
        --connect-timeout 10 \
        --max-time 30)
    
    local curl_exit_code=$?
    
    if [ $curl_exit_code -eq 0 ]; then
        log_message "POST $API_URL -> response status code: $response"
    else
        log_message "ERROR: Failed to send request to $API_URL (curl exit code: $curl_exit_code)"
    fi
}

show_notification() {
    local notification_id="alive_check_$(date +%s)"
    log_message "Showing notification (ID: $notification_id)"
    log_message "Target API: $API_URL"

    osascript <<EOF
        display dialog "Confirm your activity" \
            buttons {"I'm alive!"} \
            default button "I'm alive!" \
            with icon note \
            with title "SleepWarden" \
            giving up after $TIMEOUT_SECONDS

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
log_message "Configuration:"
log_message "  API URL: $API_URL"
log_message "  Min interval: $((MIN_INTERVAL/60)) minutes"
log_message "  Max interval: $((MAX_INTERVAL/60)) minutes"
log_message "  Timeout: $TIMEOUT_SECONDS seconds"

while true; do
    show_notification
    
    if [ "$MAX_INTERVAL" -eq "$MIN_INTERVAL" ]; then
        random_interval=$MIN_INTERVAL
    else
        random_interval=$((RANDOM % (MAX_INTERVAL - MIN_INTERVAL + 1) + MIN_INTERVAL))
    fi
    
    next_check=$(date -v+${random_interval}S '+%H:%M:%S')
    
    log_message "Next check at $next_check ($((random_interval/60)) min)"
    sleep $random_interval
done
