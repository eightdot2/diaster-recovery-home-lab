# Docker Disaster Recovery Backup Script to Google Drive

A comprehensive backup solution for headless, Linux-based home lab environments with an intelligent retention policy. This script creates timestamped backups of your Docker configurations, scripts, and system files whilst automatically managing storage through a graduated retention system.

Please note - this is primarily a Docker-focused backup script, although it does back up other important system files too. 
Here's the breakdown of what this script does:

Docker-Focused Backups (~70% of the script):

- Docker Compose files (.yml, .yaml)
- Docker environment files (.env)
- Docker-related scripts (.sh)
- Docker network configurations
- Dockerfiles and configs

Non-Docker System Backups (~30%):

- All your custom scripts (/home/username/scripts/) [well, this is where I keep all my local scripts anyway]
- SSH keys (~/.ssh/)
- Shell configs (.bashrc, .profile)
- Email config (/etc/msmtprc)
- Crontab entries
- System package list (for rebuilding the entire system)

What It Doesn't Back Up:

- Application data (explicitly excludes */data/**)
- Log files (excludes */logs/**)
- Cache directories (excludes */cache/**)
- Personal documents, photos, etc.

It's really a "Infrastructure Recovery" script rather than a complete system backup. It's designed to let you rebuild your entire Docker-based home lab setup from scratch, but you'd still need separate backups for:

- Personal files
- Media collections
- Application databases (unless you have separate database backup strategies)

------

## Features

- **Timestamped backups** - Each backup stored in `YYYYMMDD-HHMMSS` directories
- **Intelligent retention** - Keeps more recent backups, fewer older ones
- **Email notifications** - Detailed reports of what was backed up and cleaned up
- **Secure filtering** - Only backs up configuration files, excludes data/logs/cache
- **Cloud storage** - Uses rclone for reliable cloud backup
- **Recovery ready** - Includes system package lists and network configurations

## Retention Policy

The script automatically manages backup retention to prevent unlimited storage growth:

- **Last 3 backups** - Always retained regardless of age
- **Monthly backups** - One backup per month for backups 30+ days old
- **Quarterly backups** - One backup per quarter for backups 90+ days old
- **Yearly backups** - One backup per year for backups 365+ days old

**Example:** Daily backups over 6 months results in ~9 retained backups instead of 180+


## What Gets Backed Up

1. **Docker Configurations**
   - `docker-compose.yml` files
   - Environment files (`.env`)
   - Shell scripts (`.sh`)
   - Configuration files (`.conf`, `.json`, `.toml`, `.ini`)
   - Documentation (`.md`, `.txt`)
   - Dockerfiles

2. **Scripts Directory**
   - All custom scripts and automation

3. **System Configurations**
   - Email configuration (`msmtprc`)
   - Crontab entries
   - Docker network configurations
   - System package lists

4. **User Configurations**
   - SSH keys
   - Shell configuration files (`.bashrc`, `.profile`)
  

## Prerequisites

### 1. Rclone Configuration
Install rclone and configure your cloud storage provider.

### 2. Email Notifications (msmtp)
Install and configure msmtp for email notifications.

### 3. Directory Structure
Ensure your Docker configs are organised in a structured manner with separate directories for each service.


## Installation

1. **Download the script and make it executable**

2. **Configure the script** - Edit the configuration section at the top and update these variables:
   - `BACKUP_REMOTE` - your rclone remote configuration
   - `NOTIFICATION_EMAIL` - where to send reports
   - `FROM_EMAIL` - sender address for notifications
   - `USERNAME` - your system username

3. **Test the configuration** - Verify rclone connectivity and email delivery

4. **Run a test backup**

5. **Schedule with cron** - Add to crontab for automated backups


## Security Considerations

- **Script runs as root** - Required for accessing system configs and rclone
- **Email contains paths** - Ensure your email account is secure
- **SSH keys backed up** - Consider if you want these in cloud storage
- **Cloud storage encryption** - Enable encryption in your rclone remote if required

### Excluding Sensitive Data
The script automatically excludes data, logs, and cache directories.

## Troubleshooting

Common issues include rclone authentication errors, email delivery failures, and permission errors. Test your configuration before scheduling automated backups.

## Recovery Usage

Use rclone to list available backups and restore files as needed. The script includes system package lists and network configurations for complete disaster recovery.

## Contributing

Contributions welcome! Please fork, create a feature branch, test thoroughly, and submit a pull request.

## License

MIT License - Feel free to modify and distribute

