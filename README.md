
# AWS Argos Extensions

## Overview

**AWS Argos Extensions** is a collection of GNOME Shell extensions built using [Argos](https://github.com/p-e-w/argos) to provide real-time monitoring and management of various AWS services. At this stage, the project includes an extension for monitoring **Amazon SQS (Simple Queue Service)** queues.

This project aims to simplify cloud resource monitoring directly from the GNOME desktop environment. It enables quick insights and actionable notifications without the need to switch between multiple AWS dashboards or third-party tools.

---

## Why AWS Argos Extensions?

Managing AWS resources can be a complex task, especially for developers, system administrators, and DevOps engineers who need real-time visibility into their cloud infrastructure. While AWS provides robust monitoring solutions like **CloudWatch**, these tools often require dedicated dashboards or integrations.

**AWS Argos Extensions** bridges the gap by:
- Displaying real-time AWS metrics directly in the GNOME top bar.
- Reducing context-switching by keeping essential monitoring tools at your fingertips.
- Providing lightweight and customizable monitoring for your desktop environment.

---

## Current Features

### Amazon SQS Monitoring
The **SQS Monitoring** extension allows you to:
- Monitor the number of **visible** and **in-flight** messages for multiple SQS queues.
- Define thresholds for each queue to trigger alerts.
- Receive desktop notifications when thresholds are breached or if there are errors fetching queue metrics.
- Enable or disable notifications dynamically through the dropdown menu.
- View all configured queues and their current status directly in the dropdown.

---

## Benefits of AWS Argos Extensions

1. **Real-Time Monitoring**:
    - Stay updated on critical AWS services without additional tools.

2. **Productivity Boost**:
    - Reduce the need to log in to the AWS Management Console or external dashboards.

3. **Lightweight and Extensible**:
    - Built on Argos, making it easy to extend and customize.

4. **Customizable Alerts**:
    - Define queue-specific thresholds to trigger actionable alerts.

5. **Desktop Integration**:
    - Seamlessly integrates with GNOME Shell for a non-intrusive, efficient monitoring experience.

---

## Installation

### Prerequisites
1. **AWS CLI**:
    - Ensure that the AWS CLI is installed and configured with proper credentials.
    - [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
    - Configure using:
      ```bash
      aws configure
      ```

2. **Argos Extension**:
    - Install the [Argos GNOME Shell extension](https://github.com/p-e-w/argos) to enable the integration.
    - Restart GNOME Shell after installation.

3. **Dependencies**:
    - Ensure `jq` is installed for JSON parsing:
      ```bash
      sudo apt install jq
      ```

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/aws-argos-extensions.git
   cd aws-argos-extensions
   ```

2. Create a symbolic link to the Argos directory:
   ```bash
   ln -s $(pwd)/extensions/sqs-monitor/sqs-monitor.2s.sh ~/.config/argos/
   ```

3. Configure the SQS Monitoring extension:
    - Edit the `config.json` file:
      ```json
      {
        "notifications_enabled": true,
        "sqs_monitor": [
          {
            "name": "Queue1",
            "url": "https://sqs.eu-central-1.amazonaws.com/your-account-id/queue-name",
            "threshold": 10
          }
        ]
      }
      ```
    - Save the file as `~/.config/aws-argos-extensions/config.json`.

4. Reload Argos:
    - Press `Alt + F2`, type `r`, and press Enter to reload GNOME Shell.

---

## Usage

### SQS Monitoring Features
- **Top Bar**:
    - Displays the overall status of your SQS queues.
    - Highlights alert counts if any thresholds are breached.

- **Dropdown Menu**:
    - Lists all configured queues with their current status.
    - Alerts for queues that exceed thresholds or encounter errors.
    - Includes a **Manual Refresh** option and a **Toggle Notifications** feature.

---

## Example Output

**Top Bar**:
```plaintext
SQS (2)
```

**Dropdown Menu**:
```plaintext
Queue1: Visible: 15, In-flight: 3
Queue2: Visible: 0, In-flight: 1
---
Disable Notifications
Manual Refresh
```

---

## Roadmap

- **Additional Extensions**:
    - Add monitoring for other AWS services like EC2, RDS, and Lambda.
- **Advanced Features**:
    - Enable more customization options for notifications and thresholds.
- **Improved UI**:
    - Add tooltips and more interactive elements.

---

## Contributing

Contributions are welcome! Feel free to submit issues, feature requests, or pull requests to enhance the project.

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.