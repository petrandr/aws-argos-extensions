#!/bin/bash

# Define directories
REPO_DIR=$(pwd)
EXTENSIONS_DIR=~/.config/aws-argos-extensions
ARGOS_DIR=~/.config/argos

# Ensure directories exist
mkdir -p "$EXTENSIONS_DIR"
mkdir -p "$ARGOS_DIR"

ln -sf "$REPO_DIR/config.json" "$EXTENSIONS_DIR/config.json"

echo "Select an extension to install:"
PS3="Enter the number: "
options=("SQS Monitor" "EC2 Monitor" "Exit")
select opt in "${options[@]}"; do
    case $opt in
        "SQS Monitor")
            echo "Installing SQS Monitor..."
            ln -sf "$REPO_DIR/extensions/sqs-monitor/sqs-monitor.2s.sh" "$ARGOS_DIR/sqs-monitor.2s.sh"
            echo "SQS Monitor installed. Please configure the file: $EXTENSIONS_DIR/sqs-monitor-config.json"
            break
            ;;
        "EC2 Monitor")
            echo "Installing EC2 Monitor..."
            ln -sf "$REPO_DIR/extensions/ec2-monitor/ec2-monitor.5m.sh" "$ARGOS_DIR/ec2-monitor.5m.sh"
            ln -sf "$REPO_DIR/extensions/ec2-monitor/config-example.json" "$EXTENSIONS_DIR/ec2-monitor-config.json"
            echo "EC2 Monitor installed. Please configure the file: $EXTENSIONS_DIR/ec2-monitor-config.json"
            break
            ;;
        "Exit")
            echo "Exiting."
            break
            ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
