#!/bin/bash

# Configuration
CONFIG_FILE=~/.config/aws-argos-extensions/config.json

# Ensure the config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Missing config file: $CONFIG_FILE"
    exit 1
fi

# Source the shared SQS utility functions
source ~/.config/argos/sqs-utils.sh

# Define queues and thresholds (custom name | queue URL | threshold)
QUEUES=$(jq -r '.sqs_monitor[] | [.name, .url, .threshold] | @tsv' < "$CONFIG_FILE")
echo $QUEUES
# Notification state file
ALERT_STATE_FILE=/tmp/sqs-alerts-state
touch "$ALERT_STATE_FILE"

# Initialize status variables
TOP_BAR_COLOR="white"
TOP_BAR_TEXT="SQS"
ALERT_COUNT=0
DROPDOWN_ALERTS=""
DROPDOWN_CONTENT=""

# Function to check notification timing
should_notify() {
    local QUEUE_NAME=$1
    local CURRENT_TIME=$(date +%s)
    local LAST_ALERT_TIME=$(grep "^$QUEUE_NAME:" "$ALERT_STATE_FILE" | cut -d':' -f2)

    if [[ -z $LAST_ALERT_TIME ]] || (( CURRENT_TIME - LAST_ALERT_TIME >= 300 )); then
        # Update the timestamp in the state file
        grep -v "^$QUEUE_NAME:" "$ALERT_STATE_FILE" > "${ALERT_STATE_FILE}.tmp"
        echo "$QUEUE_NAME:$CURRENT_TIME" >> "${ALERT_STATE_FILE}.tmp"
        mv "${ALERT_STATE_FILE}.tmp" "$ALERT_STATE_FILE"
        return 0  # Notify
    fi
    return 1  # Do not notify
}

# Check each queue
for QUEUE in $QUEUES; do
  echo $QUEUE
  continue
    IFS=$'\t' read -r NAME QUEUE_URL THRESHOLD <<< "$QUEUE"
    echo $THRESHOLD
    exit 1
    # Fetch SQS attributes
    AWS_OUTPUT=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --output json)

    # Handle AWS CLI errors
    if [[ $? -ne 0 ]]; then
        DROPDOWN_ALERTS+="<span color='red'>$QUEUE_NAME</span>: <span color='red'>Error fetching data</span>\n"
        ALERT_COUNT=$((ALERT_COUNT + 1))
        TOP_BAR_COLOR="red"
        if should_notify "$QUEUE_NAME"; then
            notify-send "SQS Alert: $QUEUE_NAME" "Error fetching data" -u critical
        fi
        continue
    fi

    # Parse SQS data
    VISIBLE=$(echo "$AWS_OUTPUT" | jq -r '.Attributes.ApproximateNumberOfMessages')
    IN_FLIGHT=$(echo "$AWS_OUTPUT" | jq -r '.Attributes.ApproximateNumberOfMessagesNotVisible')

    # Check against the threshold
    if [[ $VISIBLE -gt $THRESHOLD ]]; then
        DROPDOWN_ALERTS+="&#x200B;<span color='red'>$QUEUE_NAME: Visible: $VISIBLE, In-flight: $IN_FLIGHT</span>\n"
        ALERT_COUNT=$((ALERT_COUNT + 1))
        TOP_BAR_COLOR="red"
        if should_notify "$QUEUE_NAME"; then
            notify-send "SQS Alert: $QUEUE_NAME" "Visible: $VISIBLE, In-flight: $IN_FLIGHT (Threshold: $THRESHOLD)" -u critical
        fi
        continue
    fi

    # Add to dropdown content for non-alerted queues
    DROPDOWN_CONTENT+="<span color='black'>$QUEUE_NAME</span>: <span color='black'>Visible: $VISIBLE</span>, <span color='black'>In-flight: $IN_FLIGHT</span>\n"
done

# Update top bar text
if [[ $ALERT_COUNT -gt 0 ]]; then
    TOP_BAR_TEXT+=" ($ALERT_COUNT)"
else
    TOP_BAR_TEXT+=": All OK"
fi

# Display top bar
print "$TOP_BAR_TEXT" "$TOP_BAR_COLOR" | sed 's/$/ | refresh=true/'

# Display dropdown content
echo "---"
if [[ -n $DROPDOWN_ALERTS ]]; then
    echo -e "$DROPDOWN_ALERTS"
    echo "---"
fi
if [[ -n $DROPDOWN_CONTENT ]]; then
    echo -e "$DROPDOWN_CONTENT"
fi
echo "---"
echo "Manual Refresh | refresh=true"
