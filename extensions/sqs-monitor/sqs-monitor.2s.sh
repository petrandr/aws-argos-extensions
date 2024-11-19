#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Configuration: Path to the configuration file containing SQS queue details
CONFIG_FILE=~/.config/aws-argos-extensions/config.json

# Ensure the configuration file exists before proceeding
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Missing config file: $CONFIG_FILE"
    exit 1
fi

# Source the shared SQS utility functions (e.g., reusable functions for SQS operations)
source ~/.config/argos/sqs-utils.sh

# Extract the SQS queue details (name, URL, and threshold) from the config file
# The JSON keys under 'sqs_monitor' are converted to tab-separated values
QUEUES=$(jq -r '.sqs_monitor[]? | [.name, .url, .threshold] | @tsv' < "$CONFIG_FILE")

# Path to the file storing the state of SQS alerts (to prevent redundant notifications)
ALERT_STATE_FILE=/tmp/sqs-alerts-state
touch "$ALERT_STATE_FILE"  # Ensure the state file exists

# Initialize variables for UI display
TOP_BAR_COLOR="white"       # Default color of the top bar (no alerts)
TOP_BAR_TEXT="SQS"          # Default text in the top bar
ALERT_COUNT=0               # Count of queues exceeding thresholds
DROPDOWN_ALERTS=""          # Holds alert messages for the dropdown
DROPDOWN_CONTENT=""         # Holds non-alert messages for the dropdown

# Function to determine if a notification should be sent for a queue
should_notify() {
    local QUEUE_NAME=$1  # Queue name
    local CURRENT_TIME=$(date +%s)  # Current timestamp in seconds
    # Last notification timestamp for the queue
    local LAST_ALERT_TIME=$(grep "^$QUEUE_NAME:" "$ALERT_STATE_FILE" | cut -d':' -f2)

    # Send notification if no prior notification or more than 5 minutes (300 seconds) have passed
    if [[ -z $LAST_ALERT_TIME ]] || (( CURRENT_TIME - LAST_ALERT_TIME >= 300 )); then
        # Update the state file with the current timestamp
        grep -v "^$QUEUE_NAME:" "$ALERT_STATE_FILE" > "${ALERT_STATE_FILE}.tmp"
        echo "$QUEUE_NAME:$CURRENT_TIME" >> "${ALERT_STATE_FILE}.tmp"
        mv "${ALERT_STATE_FILE}.tmp" "$ALERT_STATE_FILE"
        return 0  # Notify
    fi
    return 1  # Do not notify
}

# Loop through each queue defined in the configuration
while IFS=$'\t' read -r QUEUE_NAME QUEUE_URL THRESHOLD; do
    # Fetch the current attributes of the SQS queue
    AWS_OUTPUT=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --output json)

    # Handle errors from the AWS CLI (e.g., network issues, invalid permissions)
    if [[ $? -ne 0 ]]; then
        # Add an error alert to the dropdown
        DROPDOWN_ALERTS+="<span color='red'>$QUEUE_NAME</span>: <span color='red'>Error fetching data</span>\n"
        ALERT_COUNT=$((ALERT_COUNT + 1))  # Increment the alert count
        TOP_BAR_COLOR="red"  # Highlight the top bar as red to indicate an issue
        if should_notify "$QUEUE_NAME"; then
            # Send a critical notification for the error
            notify-send "SQS Alert: $QUEUE_NAME" "Error fetching data" -u critical
        fi
        continue
    fi

    # Parse the number of visible and in-flight messages from the AWS output
    VISIBLE=$(echo "$AWS_OUTPUT" | jq -r '.Attributes.ApproximateNumberOfMessages')
    IN_FLIGHT=$(echo "$AWS_OUTPUT" | jq -r '.Attributes.ApproximateNumberOfMessagesNotVisible')

    # Check if the number of visible messages exceeds the defined threshold
    if [[ $VISIBLE -gt $THRESHOLD ]]; then
        # Add a red alert message to the dropdown
        DROPDOWN_ALERTS+="&#x200B;<span color='red'>$QUEUE_NAME: Visible: $VISIBLE, In-flight: $IN_FLIGHT</span>\n"
        ALERT_COUNT=$((ALERT_COUNT + 1))  # Increment the alert count
        TOP_BAR_COLOR="red"  # Highlight the top bar as red
        if should_notify "$QUEUE_NAME"; then
            # Send a critical notification for the threshold breach
            notify-send "SQS Alert: $QUEUE_NAME" "Visible: $VISIBLE, In-flight: $IN_FLIGHT (Threshold: $THRESHOLD)" -u critical
        fi
        continue
    fi

    # Add non-alerted queue details to the dropdown content
    DROPDOWN_CONTENT+="<span color='white'>$QUEUE_NAME</span>: <span color='black'>Visible: $VISIBLE</span>, <span color='black'>In-flight: $IN_FLIGHT</span>\n"
done <<< "$QUEUES"

# Update the top bar text based on the number of alerts
if [[ $ALERT_COUNT -gt 0 ]]; then
    TOP_BAR_TEXT+=" ($ALERT_COUNT)"  # Display the number of alerts
else
    TOP_BAR_TEXT+=": All OK"  # Indicate all queues are within limits
fi

# Display the top bar with updated text and color
print "$TOP_BAR_TEXT" "$TOP_BAR_COLOR" | sed 's/$/ | refresh=true/'

# Display the dropdown content
echo "---"
if [[ -n $DROPDOWN_ALERTS ]]; then
    echo -e "$DROPDOWN_ALERTS"  # Show alerts in the dropdown
    echo "---"
fi
if [[ -n $DROPDOWN_CONTENT ]]; then
    echo -e "$DROPDOWN_CONTENT"  # Show non-alerts in the dropdown
fi
echo "---"
echo "Manual Refresh | refresh=true"  # Add a manual refresh option
